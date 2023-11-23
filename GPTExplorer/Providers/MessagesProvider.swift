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
   
   func addMessage(
      threadID: String,
      parameters: MessageParameter)
      async throws
   {
      do {
         let message = try await service.createMessage(threadID: threadID, parameters: parameters)
         let messageDisplayModel = createMessageDisplayModel(from: message)! // Intentionally force unwrapped
         await addMessage(messageDisplayModel)
      } catch let error as APIError  {
         let chatDisplayMessage = ChatMessageDisplayModel(content: .error(error.displayDescription), origin: .received(.asssistant(.user)))
         await addMessage(chatDisplayMessage)
      }
   }
   
   func retrieveMessage(
      threadID: String,
      messageID: String)
      async throws
   {
      
   }
   
   func modifyMessage(
      threadID: String,
      messageID: String)
      async throws
   {
      
   }
   
   func listMessages(
      threadID: String,
      metadata: [String: String],
      limit: Int? = nil,
      order: String? = nil,
      after: String? = nil,
      before: String? = nil)
      async throws
   {
      let messagesData = try await service.listMessages(
         threadID: threadID,
         limit: limit,
         order: order,
         after: after,
         before: before)
      let assistantName = metadata[ThreadProvider.assistantMetadataName]
      for message in messagesData.data {
         let messageDisplayModel = createMessageDisplayModel(from: message, assistantName: assistantName)!
         await addMessage(messageDisplayModel)
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
   private func addMessage(_ message: ChatMessageDisplayModel) {
      withAnimation {
         chatDisplayMessages.append(message)
      }
   }
   
   private func updateLastDisplayedMessage(_ message: ChatMessageDisplayModel) {
      chatDisplayMessages[chatDisplayMessages.count - 1] = message
   }
}
