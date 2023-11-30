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
   
   var runs: [RunObject] = []
   var lastRunStepObject: RunStepObject?
   
   
   // MARK: - Initializer
   
   init(service: OpenAIService) {
      self.service = service
   }
   
   func runTheThread(
      threadID: String,
      parameters: RunParameter)
      async throws -> RunObject?
   {
      do {
         return try await service.createRun(threadID: threadID, parameters: parameters)
      } catch let error as APIError  {
         errorMessage = error.displayDescription
         return nil
      }
   }
   
   func getRunSteps(
      threadID: String,
      runID: String)
      async throws -> RunStepObject?
   {
      do {
         let timeoutDuration = 20_000_000_000 // 20 seconds in nanoseconds
         var runStepObject: RunStepObject? = nil
         
         try await withThrowingTaskGroup(of: RunStepObject?.self) { group in
            // Polling task
            group.addTask {
               return try await self.pollForCompletion(threadID: threadID, runID: runID)
            }
            
            // Timeout task
            group.addTask {
               try await Task.sleep(nanoseconds: UInt64(timeoutDuration))
               throw APIError.timeOutError
            }
            
            // Wait for the first task to complete
            for try await result in group {
               if let result = result {
                  runStepObject = result
                  break
               }
            }
            
            // Cancel any remaining tasks (either the polling task or the timeout task)
            group.cancelAll()
         }
         
         return runStepObject
      } catch let error as APIError {
         errorMessage = error.displayDescription
         return nil
      }
   }
   
   
   private func pollForCompletion(
      threadID: String,
      runID: String)
      async throws -> RunStepObject?
   {
      var isCompleted = false
      var lastStep: RunStepObject? = nil
      let maxRetries = 10  // Maximum number of retries
      var currentRetryCount = 0
      
      while !isCompleted && currentRetryCount < maxRetries {
         // Check for task cancellation
         if Task.isCancelled {
            break  // Exit the loop if the task has been cancelled
         }
         
         let data = try await service.listRunSteps(threadID: threadID, runID: runID, limit: nil, order: nil, after: nil, before: nil)         
         if let firstStep = data.data.first, let status = RunStepObject.Status(rawValue: firstStep.status), status != .inProgress {
            isCompleted = true
            lastStep = firstStep
         } else {
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
            currentRetryCount += 1
         }
      }
      return lastStep
   }
   
}
