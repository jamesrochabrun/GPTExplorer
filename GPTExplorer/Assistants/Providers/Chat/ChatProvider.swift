//
//  ChatProvider.swift
//  GPTExplorer
//
//  Created by James Rochabrun on 12/8/23.
//

import SwiftUI
import SwiftOpenAI

/**
 This is a demo in how to implement parallel function calling when using the completion API stream = true
 */

struct FunctionCallStreamedResponse {
   let name: String
   let id: String
   let toolCall: ToolCall
   var argument: String
}

enum FunctionCallDefinition: String, CaseIterable {
   
   static var lastFunction: FunctionCallDefinition?

   case createImage = "create_image"
   case buildAssistant = "build_assistant"
   // Add more functions if needed, parallel function calling is supported.

   var functionTool: ChatCompletionParameters.Tool {
      switch self {
      case .createImage:
         return .init(function: .init(
            name: self.rawValue,
            description: "Call this function if the request asks to generate an image",
            parameters: .init(
               type: .object,
               properties: [
                  "prompt": .init(type: .string, description: "The exact prompt passed in."),
                  "count": .init(type: .integer, description: "The number of images requested")
               ],
               required: ["prompt", "count"])))
      case .buildAssistant:
         return .init(function: .init(
            name: self.rawValue,
            description: "Call this function if the request is associated to build an assistant to certain parameters, the values we need to extract are, name, description, instructions., enabling tools such code interpreter, retrieval or Dalle",
            parameters: .init(
               type: .object,
               properties: [
                  "name": .init(type: .string, description: "The name for the assistant."),
                  "description": .init(type: .string, description: "The assistant's description"),
                  "instructions": .init(type: .string, description: "The assistant's instructions"),
                  "code_interpreter": .init(type: .boolean, description: "A bool se to true if user requests code interpreter tool"),
                  "retrieval": .init(type: .boolean, description: "A bool se to true if user requests code retrieval tool"),
                  "dalle": .init(type: .boolean, description: "A bool se to true if user requests dalle image generator tool"),
                  "avatar_description": .init(type: .string, description: "The description of the image that was requested by the user.")
               ],
               required: ["name"])))
      }
   }
}

@Observable class ChatProvider {
   
   // MARK: - Private Properties
   
   private let service: OpenAIService
   private var lastDisplayedMessageID: String?
   /// To be used for a new request
   private var chatMessageParameters: [ChatCompletionParameters.Message] = []
   private var functionsToCallsMap: [FunctionCallDefinition: FunctionCallStreamedResponse] = [:]
   private var availableFunctions: [FunctionCallDefinition: (@MainActor (String) async throws -> String)] = [:]
   
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
      /// # Step 2.1 : do not forget to also add that new user message to the parameters that will be used for the chat request.
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
               
               /// # Step 3: Define the available functions to be called IMPORTANT
               availableFunctions = [
                  .createImage: generateImage(arguments:),
                  .buildAssistant: generateAssistantParameters(arguments:)
               ]
               
               /// IMPORTANT,
               assert(availableFunctions.count == FunctionCallDefinition.allCases.count, "This is programming error, all the functions declared in FunctionCallDefinition, must provide a function implementation.")

               mapStreamedToolCallsResponse(toolCalls)
            }
            
            /// The streamed content to display
            if let newContent = choice.delta.content {
               await updateLastAssistantMessage(.init(
                  content: .content(.init(text: newContent)),
                  origin: .received(.gpt)))
            }
         }
         // # extend conversation with assistant's reply
         // Append the `assistantMessage` in to the `chatMessageParameters` to extend the conversation
         if !functionsToCallsMap.isEmpty {
            
            let assistantMessage = createAssistantMessage()
            chatMessageParameters.append(assistantMessage)
            /// # Step 4: send the info for each function call and function response to the model
            let toolMessages = try await createToolsMessages()
            chatMessageParameters.append(contentsOf: toolMessages)
            
            // Lastly call the chat again
            await continueChat()
         }
         
         // TUTORIAL
      } catch {
         // If an error occurs, update the UI to display the error message.
         await updateLastAssistantMessage(.init(content: .error("\(error)"), origin: .received(.gpt)))
      }
   }
   
   /// This gets triggered multiple time.
   func mapStreamedToolCallsResponse(
      _ toolCalls:  [ToolCall])
   {
      assert(toolCalls.count == 1)
      for toolCall in toolCalls {
         // Intentionally force unwrapped to catch errrors quickly on demo. // This should be properly handled.
         if let function = stream(toolCall.function.name) {
            if var streamedFunctionCallResponse = functionsToCallsMap[function] {
               streamedFunctionCallResponse.argument += toolCall.function.arguments
               functionsToCallsMap[function] = streamedFunctionCallResponse
            } else {
               let streamedFunctionCallResponse = FunctionCallStreamedResponse(
                  name: toolCall.function.name!,
                  id: toolCall.id!,
                  toolCall: toolCall,
                  argument: toolCall.function.arguments)
               functionsToCallsMap[function] = streamedFunctionCallResponse
            }
         }
      }
   }
   
   // This is the only way to not override the last function, remember that toolCall.function.name is
   // not nil Only on the first `mapStreamedToolCallsResponse` call.
   func stream(_ name: String?) -> FunctionCallDefinition? {
       if let name = name, let newFunction = FunctionCallDefinition(rawValue: name) {
          FunctionCallDefinition.lastFunction = newFunction
       }
       return FunctionCallDefinition.lastFunction
   }
   
   func createUserMessage(
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
   
   func createAssistantMessage() -> ChatCompletionParameters.Message {
      var toolCalls: [ToolCall] = []
      for (_, functionCallStreamedResponse) in functionsToCallsMap {
         let toolCall = functionCallStreamedResponse.toolCall
         // Intentionally force unwrapped to catch errrors quickly on demo. // This should be properly handled.
         let messageToolCall = ToolCall(
            id: toolCall.id!,
            function: .init(arguments: toolCall.function.arguments, name: toolCall.function.name!))
         toolCalls.append(messageToolCall)
      }
      return .init(role: .assistant, content: .text(""), toolCalls: toolCalls)
   }
   
   func createToolsMessages() async throws
   -> [ChatCompletionParameters.Message]
   {
      var toolMessages: [ChatCompletionParameters.Message] = []
      for (key, functionCallStreamedResponse) in functionsToCallsMap {
         
         let name = functionCallStreamedResponse.name
         let id = functionCallStreamedResponse.id
         let functionToCall = availableFunctions[key]!
         let arguments = functionCallStreamedResponse.argument
         let content = try await functionToCall(arguments)
         let toolMessage = ChatCompletionParameters.Message(
            role: .tool,
            content: .text(content),
            name: name,
            toolCallID: id)
         toolMessages.append(toolMessage)
      }
      return toolMessages
   }
   
   func continueChat() async {
      
      let paramsForChat = ChatCompletionParameters(
         messages: chatMessageParameters,
         model: .gpt41106Preview)
      do {
         // Begin the chat stream with the updated parameters.
         let stream = try await service.startStreamedChat(parameters: paramsForChat)
         for try await result in stream {
            // Extract the first choice from the stream results, if none exist, exit the loop.
            guard let choice = result.choices.first else { return }
            
            /// The streamed content to display
            if let newContent = choice.delta.content {
               await updateLastAssistantMessage(.init(content: .content(.init(text: newContent)), origin: .received(.gpt)))
            }
         }
      } catch {
         // If an error occurs, update the UI to display the error message.
         await updateLastAssistantMessage(.init(content: .error("\(error)"), origin: .received(.gpt)))
      }
   }
   
   // MARK: - Private Methods
   
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
         content: .content(.init(text: "")),
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
            lastMessage.content = .content(updatedMedia)
         case .error:
            break
         case .loading:
            lastMessage.content = newMessage.content
         case .codeInterpreter:
            break // There is not code interpreter in this context
         }
      case .error, .loading:
         // This is because at this level we already have a error message passed at the callsite.
         lastMessage.content = newMessage.content
      case .codeInterpreter:
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
}

// MARK: Functions

extension ChatProvider {
   
   // The return types are always string as are used for the tool message.
   // The steps of a function specified here are:
   /// 1 - Execute certain action
   /// 2- Return a string that can be used for the model as a follow up message.

   @MainActor
   func generateImage(
      arguments: String)
      async throws
      -> String
   {
      print("FUNCTIONCALL Generate image \(arguments)")
      guard 
         let dictionary = arguments.toDictionary(),
         let prompt = dictionary["prompt"] as? String else {
         return "Image creation failed. Please try again later."
      }
      let count = (dictionary["count"]  as? Int) ??  1
      
      let assistantMessage = ChatMessageDisplayModel(
         content: .loading(.dalle),
         origin: .received(.gpt))
      updateLastAssistantMessage(assistantMessage)
      
      let urls = try await service.createImages(
         parameters: .init(prompt: prompt, model: .dalle2(.small), numberOfImages: count)).data.compactMap(\.url)
      
      let dalleAssistantMessage = ChatMessageDisplayModel(
         content: .content(.init(text: nil, urls: urls)),
         origin: .received(.dalle))
      updateLastAssistantMessage(dalleAssistantMessage)
      
      // This means that user started a build assistant flow
      if let url = urls.first, assistantParameters.name != nil {
         assistantParameters.avatarURL = url.absoluteString
      }
      
      return prompt
   }
   
   @MainActor
   func generateAssistantParameters(
      arguments: String)
      -> String
   {
      print("FUNCTIONCALL Generate Assistant \(arguments)")
      let dictionary = arguments.toDictionary()!
      let name = dictionary["name"] as! String
      let description = dictionary["description"] as? String
      let instructions = dictionary["instructions"] as? String
      let codeInterpreter = dictionary["code_interpreter"] as? Bool
      let retrieval = dictionary["retrieval"] as? Bool
      let dalle = dictionary["dalle"] as? Bool
      let avatarDescription = dictionary["avatar_description"] as? String
      
      var assistantParameters = AssistantParameters(
         action: .create(model: Model.gpt41106Preview.value),
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
