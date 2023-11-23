//
//  SideMenuConfigurationProvider.swift
//  GPTExplorer
//
//  Created by James Rochabrun on 11/20/23.
//

import Foundation
import SwiftOpenAI
import SwiftUI

extension AssistantObject: Identifiable {}

enum SideMenuItem: Identifiable {
   
   var id: String {
      switch self {
      case .assistant(let assistant):
         return assistant.id
      case .thread(let thread):
         return thread.id
      }
   }
   
   case assistant(AssistantObject)
   case thread(ThreadObject)
}

@Observable class SideMenuConfigurationProvider {
   
   // MARK: - Private Properties
   
   static let avatarMetadataKey = "assistant_avatar"
   static let assistantMetadataID = "assistant_id"
   
   var assistant: AssistantObject?
   private var assistantItems: [SideMenuItem] = []
   private var threadItems: [SideMenuItem] = []
   private var mapItems: [Int: [SideMenuItem]] = [:]
      
   let threadProvider: ThreadProvider
   let assistantsProvider: AssistantsProvider
   let messagesProvider: MessagesProvider
   
   var errorMessage: String?

   var items: [[SideMenuItem]] {
      let sortedKeys = mapItems.keys.sorted()
      return sortedKeys.map { mapItems[$0] ?? [] }
   }
   
   static let assistantObjectSection = 0
   static let threadObjectSection = 1
   // MARK: - Initializer
   
   init(service: OpenAIService)
   {
      self.assistantsProvider = AssistantsProvider(service: service)
      self.threadProvider = ThreadProvider(service: service)
      self.messagesProvider = MessagesProvider(service: service)
   }
   
   // MARK: Assistants
   
   func listAssistants(
      limit: Int? = nil,
      order: String? = nil,
      after: String? = nil,
      before: String? = nil)
      async throws
   {
      do {
         let assistants = try await assistantsProvider.listAssistants(limit: limit, order: order, after: after, before: before)
         dump(assistants)
         for assistant in assistants {
            dump(assistant)
         }
         mapItems[Self.assistantObjectSection] = assistants.map { .assistant($0) }
      } catch let error as APIError {
         errorMessage = error.displayDescription
      }
   }
   
   func deleteAssistant(
      id: String)
      async throws
   {
      do {
         let deletionStatus = try await assistantsProvider.deleteAssistant(id: id)
         print("Deletion status \(deletionStatus)")
      } catch let error as APIError  {
         errorMessage = error.displayDescription
      }
   }
   
   func createAssistant(
      parameters: AssistantParameters)
      async throws
   {
      do {
         let localAssistant = try await assistantsProvider.createAssistant(parameters: parameters)
         dump(assistant)
         assistant = localAssistant
      } catch let error as APIError  {
         errorMessage = error.displayDescription
      }
   }
   
   // MARK: Threads
   
   func listThreads()
      async throws
   {
      do {
         let threads = try await threadProvider.listThreads()
         mapItems[Self.threadObjectSection] = threads.map { .thread($0) }
      } catch let error as APIError  {
         errorMessage = error.displayDescription
      }
   }
}
