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
      async throws -> MessageObject?
   {
      do {
         return try await service.createMessage(threadID: threadID, parameters: parameters)
      } catch let error as APIError  {
         errorMessage = error.displayDescription
         return nil
      }
   }

   func retrieveMessage(
      threadID: String,
      messageID: String)
      async throws -> MessageObject?
   {
      do {
         return try await service.retrieveMessage(threadID: threadID, messageID: messageID)
      } catch let error as APIError  {
         errorMessage = error.displayDescription
         return nil
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
            before: nil)
         for message in messagesData.data {
            let messageDisplayModel = createMessageDisplayModel(from: message, assistantName: assistantName)!
            await addMessage(messageDisplayModel)
         }
      } catch let error as APIError  {
         errorMessage = error.displayDescription
      }
   }
   
   func createMessageDisplayModel(
      from message: MessageObject,
      assistantName: String? = nil)
      -> ChatMessageDisplayModel?
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
            print("jamesrochabrun \(content.text.value), id: \(message.id)")

            return ChatMessageDisplayModel(
               id: message.id,
               content: .content(.init(text: content.text.value)),
               origin: .received(.asssistant(origin)))
         default:
            return nil
         }
      }
      return nil
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


