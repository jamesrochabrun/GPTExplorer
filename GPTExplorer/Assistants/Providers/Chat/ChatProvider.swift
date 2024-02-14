//
//  ChatProvider.swift
//  GPTExplorer
//
//  Created by James Rochabrun on 12/8/23.
//

import SwiftUI
import SwiftOpenAI

@Observable class ChatProvider {
   
   // MARK: - Public Properties
   
   /// To be used for UI purposes.
   var chatDisplayMessages: [ChatMessageDisplayModel] = []
   /// The updates assistant parameters
   var assistantParameters: AssistantParameters = AssistantParameters(action: .create(model: Model.gpt41106Preview.value))
   var assistantURL: URL?
      
   // MARK: - Initializer
   
   init(service: OpenAIService) {
      self.service = service
   }
   
   // MARK: - Public Methods
   
   func chat(
      content: ChatMessageDisplayModel.DisplayContent.DisplayMessageType,
      _ parameters: ChatCompletionParameters)  
      async throws
   {
      defer {
         functionsToCallsMap = [:]
         chatMessageParameters = []
      }
      await startNewUserDisplayMessage(content)
      await startNewAssistantEmptyDisplayMessage()
      
      /// # Step 1: add the system message if any to the `chatMessageParameters`
      if let assistantMessage = parameters.messages.first {
         chatMessageParameters.append(assistantMessage)
      }
      
      /// # Step 2: Create a user message with the given content.
      let userMessage = createUserMessage(content)
      chatMessageParameters.append(userMessage)
      /// # Step 2.1 : do not forget to also add that new user message to the parameters that will be used when continuing a conversation is needed.
      /// e.g: After a function call
      var localParameters = parameters
      localParameters.messages.append(userMessage)
      
      assert(localParameters.messages.count == 2, "We should have 2 messages at this point")

      do {
         // Begin the chat stream with the updated parameters.
         let stream = try await service.startStreamedChat(parameters: localParameters)
         for try await result in stream {
            // Extract the first choice from the stream results, if none exist, exit the loop.
            guard let choice = result.choices.first else { return }
            /// Because we are using the stream API we need to wait to populate
            /// the needed values that comes from the streamed API to construct a valid tool call response.
            /// This is not needed if the stream is set to false in the API completion request.
            /// # Step 2: check if the model wanted to call a function
            if let toolCalls = choice.delta.toolCalls {
               
               /// # Step 3: Define the available functions to be called `IMPORTANT`
               availableFunctions = [
                  .createImage: generateImage(arguments: model:),
                  .buildAssistant: generateAssistantParameters(arguments: model:)
               ]
               assert(availableFunctions.count == FunctionCallDefinition.allCases.count, "This is programming error, all the functions declared in FunctionCallDefinition, must provide a function implementation.")
               mapStreamedToolCallsResponse(toolCalls)
            }
            await updateLastAssistantMessage(.init(
                  content: .content(.init(text: choice.delta.content ?? "", isFinished: choice.finishReason != nil)),
                  origin: .received(.gpt)))
         }
         // # extend conversation with assistant's reply.
         // Append the `assistantMessage` in to the `chatMessageParameters` to extend the conversation
         if !functionsToCallsMap.isEmpty {
            
            let assistantMessage = createAssistantMessage()
            chatMessageParameters.append(assistantMessage)
            /// # Step 4: send the info for each function call and function response to the model
            let toolMessages = try await createToolsMessages(model: .custom(parameters.model))
            chatMessageParameters.append(contentsOf: toolMessages)
            
            // Lastly call the chat again, and pass the model from the parameters.
            await continueChatAfterFunctionCall(model: .custom(parameters.model))
         }
      } catch {
         // If an error occurs, update the UI to display the error message.
         await updateLastAssistantMessage(.init(content: .error("\(error)"), origin: .received(.gpt)))
      }
   }
      
   // MARK: - Private Methods
   
   private func mapStreamedToolCallsResponse(
      _ toolCalls: [ToolCall])
   {
      assert(toolCalls.count == 1)
      
      // This is the only way to not override the last function, remember that toolCall.function.name is
      // not nil Only on the first `mapStreamedToolCallsResponse` call.
      func stream(_ name: String?) -> FunctionCallDefinition? {
          if let name = name, let newFunction = FunctionCallDefinition(rawValue: name) {
             FunctionCallDefinition.lastFunction = newFunction
          }
          return FunctionCallDefinition.lastFunction
      }
      for toolCall in toolCalls {
         if let function = stream(toolCall.function.name) {
            if var streamedFunctionCallResponse = functionsToCallsMap[function] {
               streamedFunctionCallResponse.argument += toolCall.function.arguments
               functionsToCallsMap[function] = streamedFunctionCallResponse
            } else {
               if
                  let functionName = toolCall.function.name,
                  let toolCallID = toolCall.id {
                  let streamedFunctionCallResponse = FunctionCallStreamedResponse(
                     name: functionName,
                     id: toolCallID,
                     toolCall: toolCall,
                     argument: toolCall.function.arguments)
                  functionsToCallsMap[function] = streamedFunctionCallResponse
               }
            }
         }
      }
   }
      
   private func createUserMessage(
      _ content: ChatMessageDisplayModel.DisplayContent.DisplayMessageType)
      -> ChatCompletionParameters.Message
   {
      var inputs: [ChatCompletionParameters.Message.ContentType.MessageContent] = []
      if let prompt = content.text.map({ ChatCompletionParameters.Message.ContentType.MessageContent.text($0) }) {
         inputs.append(prompt)
      }
      if let urls = content.urls?.map({ ChatCompletionParameters.Message.ContentType.MessageContent.imageUrl($0) }) {
         inputs.append(contentsOf: urls)
      }
      return ChatCompletionParameters.Message(role: .user, content: .contentArray(inputs))
   }
   
   private func createAssistantMessage()
      -> ChatCompletionParameters.Message
   {
      var toolCalls: [ToolCall] = []
      for (_, functionCallStreamedResponse) in functionsToCallsMap {
         let toolCall = functionCallStreamedResponse.toolCall
         if
            let functionName = toolCall.function.name,
            let toolCallID = toolCall.id {
            let messageToolCall = ToolCall(
               id: toolCallID,
               function: .init(arguments: toolCall.function.arguments, name: functionName))
            toolCalls.append(messageToolCall)
         }
      }
      return .init(role: .assistant, content: .text(""), toolCalls: toolCalls)
   }
   
   private func createToolsMessages(
      model: Model)
      async throws -> [ChatCompletionParameters.Message]
   {
      var toolMessages: [ChatCompletionParameters.Message] = []
      for (key, functionCallStreamedResponse) in functionsToCallsMap {
         if let functionToCall = availableFunctions[key] {
            let name = functionCallStreamedResponse.name
            let id = functionCallStreamedResponse.id
            let arguments = functionCallStreamedResponse.argument
            let content = try await functionToCall(arguments, model)
            let toolMessage = ChatCompletionParameters.Message(
               role: .tool,
               content: .text(content),
               name: name,
               toolCallID: id)
            toolMessages.append(toolMessage)
         }
      }
      return toolMessages
   }
   
   private func continueChatAfterFunctionCall(
      model: Model)
      async
   {
      let paramsForChat = ChatCompletionParameters(
         messages: chatMessageParameters,
         model: model)
      do {
         // Begin the chat stream with the updated parameters.
         let stream = try await service.startStreamedChat(parameters: paramsForChat)
         for try await result in stream {
            // Extract the first choice from the stream results, if none exist, exit the loop.
            guard let choice = result.choices.first else { return }
            
            /// The streamed content to display
               await updateLastAssistantMessage(
                  .init(content: .content(
                     .init(text: choice.delta.content ?? "",
                           isFinished: choice.finishReason != nil)),
                        origin: .received(.gpt)))
         }
      } catch {
         // If an error occurs, update the UI to display the error message.
         await updateLastAssistantMessage(.init(content: .error("\(error)"), origin: .received(.gpt)))
      }
   }
   
   @MainActor
   private func startNewUserDisplayMessage(
      _ content: ChatMessageDisplayModel.DisplayContent.DisplayMessageType)
   {
      let startingMessage = ChatMessageDisplayModel(
         content: .content(content),
         origin: .sent)
      addMessage(startingMessage)
   }
   
   @MainActor
   private func startNewAssistantEmptyDisplayMessage() {
      let newMessage = ChatMessageDisplayModel(
         content: .content(.init(text: "", isFinished: false)),
         origin: .received(.gpt))
      addMessage(newMessage)
   }
   
   @MainActor
   private func updateLastAssistantMessage(
      _ newMessage: ChatMessageDisplayModel)
   {
      guard let id = lastDisplayedMessageID, let index = chatDisplayMessages.firstIndex(where: { $0.id == id }) else { return }
      
      var lastMessage = chatDisplayMessages[index]
      
      switch newMessage.content {
      case .content(let newMedia):
         switch lastMessage.content {
         case .content(let lastMedia):
            var updatedMedia = lastMedia
            if let newText = newMedia.text,
               var lastMediaText = lastMedia.text {
               lastMediaText += newText
               updatedMedia.text = lastMediaText
            } else {
               updatedMedia.text = ""
            }
            if let urls = newMedia.urls {
               updatedMedia.urls = urls
            }
            updatedMedia.isFinished = newMedia.isFinished
            lastMessage.content = .content(updatedMedia)
         case .error:
            break
         case .loading:
            lastMessage.content = newMessage.content
         case .toolCall:
            break // There is not code interpreter in this context
         }
      case .error, .loading:
         // This is because at this level we already have a error message passed at the callsite.
         lastMessage.content = newMessage.content
      case .toolCall:
         break // There is not code interpreter in this context
      }
      
      chatDisplayMessages[index] = ChatMessageDisplayModel(
         id: id,
         content: lastMessage.content,
         origin: newMessage.origin)
   }
   
   @MainActor
   private func addMessage(_ message: ChatMessageDisplayModel) {
      let newMessageId = message.id
      lastDisplayedMessageID = newMessageId
      withAnimation {
         chatDisplayMessages.append(message)
      }
   }
   
   // MARK: - Private Properties
   
   private let service: OpenAIService
   private var lastDisplayedMessageID: String?
   /// To be used for a new request
   private var chatMessageParameters: [ChatCompletionParameters.Message] = []
   private var functionsToCallsMap: [FunctionCallDefinition: FunctionCallStreamedResponse] = [:]
   private var availableFunctions: [FunctionCallDefinition: (@MainActor (String, Model?) async throws -> String)] = [:]
}

// MARK: Functions

extension ChatProvider {
   
   // The return types are always string as are used for the tool message.
   // The steps of a function specified here are:
   /// 1 - Execute certain action
   /// 2- Return a string that can be used for the model as a follow up message.

   @MainActor
   private func generateImage(
      arguments: String,
      model: Model?)
      async throws
      -> String
   {
      print("FUNCTIONCALL Generate image \(arguments)")
      guard 
         let dictionary = arguments.toDictionary(),
         let prompt = dictionary["prompt"] as? String else {
         return "Image creation failed. Please try again later."
      }
      let count = (dictionary["count"] as? Int) ??  1
      
      let assistantMessage = ChatMessageDisplayModel(
         content: .loading(.dalle),
         origin: .received(.gpt))
      updateLastAssistantMessage(assistantMessage)
      
      let urls = try await service.createImages(
         parameters: .init(prompt: prompt, model: .dalle2(.small), numberOfImages: count)).data.compactMap(\.url)
      
      let dalleAssistantMessage = ChatMessageDisplayModel(
         content: .content(.init(text: nil, urls: urls, isFinished: true)),
         origin: .received(.dalle))
      updateLastAssistantMessage(dalleAssistantMessage)
      
      // This means that user started a build assistant flow
      if let url = urls.first, assistantParameters.name != nil {
         assistantParameters.avatarURL = url.absoluteString
      }
      return prompt
   }
   
   @MainActor
   private func generateAssistantParameters(
      arguments: String,
      model: Model?)
      -> String
   {
      print("FUNCTIONCALL Generate Assistant \(arguments)")
      guard
         let dictionary = arguments.toDictionary(),
         let model,
         let name = dictionary["name"] as? String
      else {
         return ""
      }
      let description = dictionary["description"] as? String
      let instructions = dictionary["instructions"] as? String
      let codeInterpreter = dictionary["code_interpreter"] as? Bool
      let retrieval = dictionary["retrieval"] as? Bool
      let dalle = dictionary["dalle"] as? Bool
      let avatarDescription = dictionary["avatar_description"] as? String
      
      var assistantParameters = AssistantParameters(
         action: .create(model: model.value),
         name: name,
         description: description,
         instructions: instructions)
      
      if codeInterpreter != nil {
         assistantParameters.tools.append(AssistantObject.Tool(type: .codeInterpreter))
      }
      if retrieval != nil {
         assistantParameters.tools.append(AssistantObject.Tool(type: .retrieval))
      }
      if dalle != nil {
         assistantParameters.tools.append(AssistantFunctionCallDefinition.createImage.functionTool)
      }
      self.assistantParameters = assistantParameters
      
      var toolMessage = "Your assisstant \(name) has beeen updated and it is almost ready!, you can finish the configuration on the configuration tab."
      if let avatarDescription {
         toolMessage += "Your image \(avatarDescription) has been created."
      }
      return toolMessage
   }
}

// MARK: Helpers

private extension String {
   
   func toDictionary() -> [String: Any]? {
      guard let jsonData = self.data(using: .utf8) else {
         print("Failed to convert JSON string to Data.")
         return nil
      }
      do {
         let dict = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any]
         return dict
      } catch let error {
         print("Failed to deserialize JSON: \(error.localizedDescription)")
         return nil
      }
   }
}

extension IntOrStringValue: Equatable {
   public static func == (lhs: IntOrStringValue, rhs: IntOrStringValue) -> Bool {
      switch (lhs, rhs) {
      case (let .string(lhsString), let .string(rhsString)):
          return lhsString == rhsString
      case (let .int(lhsInt), let .int(rhsInt)):
         return lhsInt == rhsInt
      default:
          return false
      }
   }
}
