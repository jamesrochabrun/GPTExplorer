//
//  AssistantsProvider.swift
//  GPTExplorer
//
//  Created by James Rochabrun on 11/22/23.
//

import SwiftUI
import SwiftOpenAI

@Observable class AssistantsProvider {
   
   private let service: OpenAIService
   var avatarURL: URL?
   
   init(service: OpenAIService) {
      self.service = service
   }
   
   func listAssistants(
      limit: Int? = nil,
      order: String? = nil,
      after: String? = nil,
      before: String? = nil)
      async throws
      -> [AssistantObject]
   {
      try await service.listAssistants(limit: limit, order: order, after: after, before: before).data
   }
   
   func deleteAssistant(
      id: String)
      async throws -> AssistantObject.DeletionStatus
   {
      try await service.deleteAssistant(id: id)
   }
   
   func createAssistant(
      parameters: AssistantParameters)
      async throws -> AssistantObject
   {
      try await service.createAssistant(parameters: parameters)
   }
   
   func createAvatar(
      prompt: String)
      async throws
   {
      do {
         let avatarURLs = try await service.createImages(parameters: .init(prompt: prompt, model: .dalle3(.largeSquare))).data.compactMap(\.url)
         self.avatarURL = avatarURLs.first
      } catch {
         fatalError("\(error)")
      }
   }
}
