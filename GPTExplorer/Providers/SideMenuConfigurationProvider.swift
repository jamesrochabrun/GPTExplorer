//
//  SideMenuConfigurationProvider.swift
//  GPTExplorer
//
//  Created by James Rochabrun on 11/20/23.
//

import Foundation
import SwiftOpenAI
import SwiftUI

enum SideMenuItem: Identifiable {
   
   var id: String {
      switch self {
      case .assistant(let assistant):
         return assistant.id
      case .thread(let thread):
         return thread.id
      case .none: return "none"
      }
   }
   
   case assistant(AssistantObject)
   case thread(ThreadObject)
   case none
}

@Observable class SideMenuConfigurationProvider {
   
   // MARK: - Private Properties
   
   enum Section: String, CaseIterable, Identifiable {
      
      case assistants
      case threads
      
      var id: String { rawValue.capitalized }
   }
   
   var errorMessage: String?
   let threadProvider: ThreadProvider
   let assistantsProvider: AssistantsProvider
   let navigationProvider: NavigationProvider
   var mapItems: [Section: [SideMenuItem]] = [:]
   
   // MARK: - Initializer
   
   init(service: OpenAIService)
   {
      self.assistantsProvider = AssistantsProvider(service: service)
      self.threadProvider = ThreadProvider(service: service)
      self.navigationProvider = .init()
   }
   
   // MARK: Assistants

   private func listAssistants(
       limit: Int? = nil,
       order: String? = nil,
       after: String? = nil,
       before: String? = nil)
       async throws -> [AssistantObject]
   {
      try await assistantsProvider.listAssistants(limit: limit, order: order, after: after, before: before)
   }
    
   // MARK: Threads
    
   private func listThreads()
      async throws -> [ThreadObject]
   {
      do {
         return try await threadProvider.listThreads()
      } catch let error as APIError {
         errorMessage = error.displayDescription
         return []
     }
   }
   
   func deleteThreadFromMapStorageWith(threadID: String) {
      var threads = mapItems[.threads]
      threads?.removeAll(where: { item in
         item.id == threadID
      })
      mapItems[.threads] = threads
   }
   
   func addThreadToMapStorage(_ thread: ThreadObject) {
      mapItems[.threads]?.append(.thread(thread))
   }
   
   func updateSideMenu(sections: Set<Section>) async throws {
       do {
           // Conditionally start the asynchronous tasks
           async let assistantsResult = sections.contains(.assistants) ? try listAssistants() : nil
           async let threadsResult = sections.contains(.threads) ? try listThreads() : nil
           
           // Await the results and update mapItems if the section was requested
           if sections.contains(.assistants), let assistants = try await assistantsResult {
               mapItems[.assistants] = assistants.map { .assistant($0) }
           }
           if sections.contains(.threads), let threads = try await threadsResult {
               mapItems[.threads] = threads.map { .thread($0) }
           }
       } catch let error as APIError {
           errorMessage = error.displayDescription
       }
   }
//   
   // MARK: Private
   private var threadItems: [SideMenuItem] = []
   private var assistantItems: [SideMenuItem] = []
}
