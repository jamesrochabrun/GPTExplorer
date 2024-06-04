//
//  MessagesProvider.swift
//  GPTExplorer
//
//  Created by James Rochabrun on 11/21/23.
//

import Foundation
import SwiftUI
import SwiftOpenAI

@Observable class MessagesProvider {
   
   private let service: OpenAIService
   var chatDisplayMessages: [ChatMessageDisplayModel] = []
   var errorMessage: String?

   // MARK: - Initializer
   
   init(service: OpenAIService) {
      self.service = service
   }
   
   func createMessage(
      threadID: String,
      parameters: MessageParameter)
      async throws -> ResultItem<MessageObject>
   {
      do {
         let message = try await service.createMessage(threadID: threadID, parameters: parameters)
         return .init(item: message, state: nil)
      } catch let error as APIError  {
         let dataFromMessage = extractIDs(from: error.displayDescription)
         return .init(item: nil, state: .createMessageError(runID: dataFromMessage.runID, threadID: dataFromMessage.threadID, message: error.displayDescription))
      }
   }
   
   // We need to "hack" a bit to get the threadID and runID provided in the error message.
   private func extractIDs(from input: String) -> (threadID: String, runID: String) {
       let threadPattern = "thread_([a-zA-Z0-9]+)"
       let runPattern = "run_([a-zA-Z0-9]+)"

       guard let threadRange = input.range(of: threadPattern, options: .regularExpression),
             let runRange = input.range(of: runPattern, options: .regularExpression) else {
           return ("", "")
       }
       let threadID = String(input[threadRange])
       let runID = String(input[runRange])
      return (threadID: threadID, runID: runID)
   }

   func retrieveMessage(
      threadID: String,
      messageID: String)
      async throws -> ResultItem<MessageObject>
   {
      do {
         let message = try await service.retrieveMessage(threadID: threadID, messageID: messageID)
         return .init(item: message, state: nil)
      } catch let error as APIError  {
         return .init(item: nil, state: .retrieveMessageError(threadID: threadID, messageID: messageID, message: error.displayDescription))
      }
   }
   
   func modifyMessage(
      threadID: String,
      messageID: String,
      parameters: ModifyMessageParameters)
      async throws -> MessageObject?
   {
      do {
         return try await service.modifyMessage(threadID: threadID, messageID: messageID, parameters: parameters)
      } catch let error as APIError  {
         errorMessage = error.displayDescription
         return nil
      }
   }
   
   func listMessages(
      threadID: String,
      assistantName: String)
      async throws
   {
     // let after = chatDisplayMessages.last?.id
      chatDisplayMessages.removeAll()
      do {
         let messagesData = try await service.listMessages(
            threadID: threadID,
            limit: nil,
            order: "asc",
            after: nil,
            before: nil,
            runID: nil)
         for message in messagesData.data {
            if let messageDisplayModel = createMessageDisplayModel(
               from: message,
               assistantName: assistantName, 
               runID: message.runID,
               threadID: message.threadID).item
            {
               await addMessage(messageDisplayModel)
            }
         }
      } catch let error as APIError  {
         errorMessage = error.displayDescription
      }
   }
   
   func createMessageDisplayModel(
      from message: MessageObject,
      assistantName: String? = nil,
      runID: String? = nil,
      threadID: String? = nil)
      -> ResultItem<ChatMessageDisplayModel>
   {
      let origin: ChatMessageDisplayModel.MessageOrigin.ReceivedSource.Assistant = message.role == "user" ?  .user : .assistant(assistantName ?? "")
      
      if let firstTextContent = message.content.first(where: { content in
         if case .text = content {
            return true
         } else {
            return false
         }
      }) {
         switch firstTextContent {
         case .text(let content):
            var runMetadata: ChatMessageDisplayModel.RunMetadata?
            if let runID, let threadID {
               runMetadata = .init(runID: runID, threadID: threadID)
            }
            let displayMessage = ChatMessageDisplayModel(
               id: message.id,
               content: .content(message: .init(text: content.text.value, isFinished: true)),
               origin: .received(.asssistant(origin)),
               runMetadata: runMetadata)
            return .init(item: displayMessage, state: nil)
         default:
            return .init(item: nil, state: .createMessageDisplayError(message: "Unable to display message"))
         }
      }
      return .init(item: nil, state: .createMessageDisplayError(message: "Unable to display message"))
   }
   
   func retrieveMessageFile(
      threadID: String,
      messageID: String,
      fileID: String)
      async throws
   {
      
   }
   
   func listMessageFiles(
      threadID: String,
      messageID: String,
      limit: Int?,
      order: String?,
      after: String?,
      before: String?)
      async throws
   {
      
   }
   
   // MARK: UI
   
   @MainActor
   func addMessage(_ message: ChatMessageDisplayModel) {
      withAnimation {
         chatDisplayMessages.append(message)
      }
   }
   
   private func updateLastDisplayedMessage(_ message: ChatMessageDisplayModel) {
      chatDisplayMessages[chatDisplayMessages.count - 1] = message
   }
}


