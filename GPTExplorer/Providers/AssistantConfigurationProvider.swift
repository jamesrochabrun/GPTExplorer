//
//  AssistantConfigurationProvider.swift
//  GPTExplorer
//
//  Created by James Rochabrun on 11/20/23.
//

import Foundation
import SwiftOpenAI

extension AssistantObject: Identifiable {}

@Observable class AssistantConfigurationProvider {
   
   // MARK: - Private Properties
   
   static let avatarMetadataKey = "assistant_avatar"
   
   private let service: OpenAIService
   
   var assistant: AssistantObject?
   var assistants: [AssistantObject] = []

   var avatarURL: URL?
   
   // MARK: - Initializer
   
   init(service: OpenAIService) {
      self.service = service
   }
   
   func listAssistants()
      async throws
   {
      do {
         let assistants = try await service.listAssistants(limit: nil, order: nil, after: nil, before: nil)
         dump(assistants)
         for assistant in assistants.data {
            dump(assistant)
         }
         self.assistants = assistants.data
      } catch {
        // fatalError("\(error)")
      }
   }
   
   func deleteAssistant(
      id: String)
      async throws
   {
      do {
         let deletionStatus = try await service.deleteAssistant(id: id)
         print("Deletion status \(deletionStatus)")
      } catch {
         fatalError("\(error)")
      }
   }
   
   func createAssistant(
      parameters: AssistantParameters)
      async throws
   {
      do {
         let localAssistant = try await service.createAssistant(parameters: parameters)
         dump(assistant)
         assistant = localAssistant
      } catch {
         fatalError("\(error)")
      }
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
