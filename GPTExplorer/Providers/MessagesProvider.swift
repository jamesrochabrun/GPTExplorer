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
         if let firstTextContent = message.content.first(where: { content in
            if case .text = content {
               return true
            } else {
               return false
            }
         }) {
            switch firstTextContent {
            case .text(let content):
               let chatDisplayMessage = ChatMessageDisplayModel(
                  id: message.id,
                  content: .content(.init(text: content.text.value)),
                  origin: .received(.asssistant(.user)))
               await addMessage(chatDisplayMessage)
            default:
               break
            }
         }
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
      let messages = messagesData.data
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
