//
//  RunsProvider.swift
//  GPTExplorer
//
//  Created by James Rochabrun on 11/25/23.
//

import SwiftUI
import SwiftOpenAI

@Observable class RunsProvider {
   
   private let service: OpenAIService
   
   var errorMessage: String?

   // MARK: - Initializer
   
   init(service: OpenAIService) {
      self.service = service
   }
   
   func createRun(
      threadID: String,
      parameters: RunParameter)
      async throws
   {
      do {
         let run = try await service.createRun(threadID: threadID, parameters: parameters)
         dump(run)
      } catch let error as APIError  {
         errorMessage = error.displayDescription
      }
   }
}
