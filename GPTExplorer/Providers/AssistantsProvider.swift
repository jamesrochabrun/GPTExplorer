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
   var errorMessage: String?
   var assistantsParameters: AssistantParameters?
   var deletionStatus: AssistantObject.DeletionStatus?
      
   static let avatarMetadataKey = "assistant_avatar"
   
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
      do {
         return try await service.listAssistants(limit: limit, order: order, after: after, before: before).data
      } catch let error as APIError  {
         errorMessage = error.displayDescription
         return []
      }
    }
   
   func deleteAssistant(
      id: String)
      async throws
   {
      do {
         deletionStatus =  try await service.deleteAssistant(id: id)
      } catch let error as APIError  {
         errorMessage = error.displayDescription
      }
   }
   
   func createAssistant(
      parameters: AssistantParameters)
      async throws
   {
      do {
         let _ = try await service.createAssistant(parameters: parameters)
      } catch let error as APIError  {
         errorMessage = error.displayDescription
      }
   }
   
   func modifyAssistant(
      id: String,
      parameters: AssistantParameters)
      async throws
   {
      do {
         let _ = try await service.modifyAssistant(id: id, parameters: parameters)
      } catch let error as APIError  {
         errorMessage = error.displayDescription
      }
   }
   
   func createAvatar(
      prompt: String)
      async throws
   {
      do {
         let avatarURL = try await service.createImages(parameters: .init(prompt: prompt, model: .dalle3(.largeSquare))).data.compactMap(\.url).first
         self.avatarURL = avatarURL
      } catch let error as APIError  {
         errorMessage = error.displayDescription
      }
   }
   
   // Edition asssistant Purposes
   func retrieveAssistantParameters(
      id: String, 
      model: String?)
      async throws -> AssistantParameters?
   {
      do {
         return try await service.retrieveAssistant(id: id).assistantParameters(model)
      } catch let error as APIError  {
         errorMessage = error.displayDescription
         return nil
      }
   }
}
