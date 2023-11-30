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
   
   // MARK: - Initializer
   
   init(service: OpenAIService)
   {
      self.assistantsProvider = AssistantsProvider(service: service)
      self.threadProvider = ThreadProvider(service: service)
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
   
   // MARK: Private
   private let threadProvider: ThreadProvider
   private var threadItems: [SideMenuItem] = []
   private let assistantsProvider: AssistantsProvider
   private var assistantItems: [SideMenuItem] = []
   var mapItems: [Section: [SideMenuItem]] = [:]
}
