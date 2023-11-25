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
   
   enum Section: Int {
      case assistants
      case threads
   }
   
   var assistant: AssistantObject?
   private var assistantItems: [SideMenuItem] = []
   private var threadItems: [SideMenuItem] = []
   private var mapItems: [Section: [SideMenuItem]] = [:]
      
   let threadProvider: ThreadProvider
   let assistantsProvider: AssistantsProvider
   
   var errorMessage: String?

   var items: [[SideMenuItem]] {
      let sortedKeys = mapItems.keys.map { $0.rawValue }.sorted()
      return sortedKeys.map { mapItems[Section(rawValue: $0) ?? .assistants] ?? [] }
   }
   
   // MARK: - Initializer
   
   init(service: OpenAIService)
   {
      self.assistantsProvider = AssistantsProvider(service: service)
      self.threadProvider = ThreadProvider(service: service)
   }
   
   // MARK: Assistants
   

   func listAssistants(
       limit: Int? = nil,
       order: String? = nil,
       after: String? = nil,
       before: String? = nil)
       async throws -> [AssistantObject]
   {
       let assistants = try await assistantsProvider.listAssistants(limit: limit, order: order, after: after, before: before)
       for assistant in assistants {
           dump(assistant)
       }
       return assistants
   }
    
   // MARK: Threads
    
   func listThreads() 
      async throws -> [ThreadObject]
   {
      try await threadProvider.listThreads()
   }
   
   func updateSideMenuContent() 
      async throws
   {
      do {
         async let assistantsResult = try listAssistants()
         async let threadsResult = try listThreads()
         
         let (assistants, threads) = try await (assistantsResult, threadsResult)
         mapItems[.assistants] = assistants.map { .assistant($0) }
         mapItems[.threads] = threads.map { .thread($0) }
      } catch let error as APIError {
         errorMessage = error.displayDescription
      }
   }
}
