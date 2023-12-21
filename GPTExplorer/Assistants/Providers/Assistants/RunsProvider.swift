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
   var lastRunStepObject: RunStepObject?
   var runSteps: [RunStepObject] = []
   
   // MARK: - Initializer
   
   init(service: OpenAIService) {
      self.service = service
   }
   
   func createRun(
      threadID: String,
      parameters: RunParameter)
      async throws -> ResultItem<RunObject>
   {
      do {
         let run = try await service.createRun(threadID: threadID, parameters: parameters)
         return .init(item: run, state: nil)
      } catch let error as APIError  {
         errorMessage = error.displayDescription
         return .init(item: nil, state: .createRunError(threadID: threadID, assistantID: parameters.assistantID, message: error.displayDescription))
      }
   }
   
   func cancelRun(
      runID: String,
      threadID: String)
      async throws -> ResultItem<RunObject>
   {
      do {
         let canceledRun = try await service.cancelRun(threadID: threadID, runID: runID)
         return .init(item: canceledRun, state: .cancelRunSuccess(message: "Run with ID \(canceledRun.id) was canceled."))
      } catch let error as APIError  {
         return .init(item: nil, state: .cancelRunError(runID: runID, threadID: threadID, message: error.displayDescription))
      }
   }
   
   func setRunSteps(
      threadID: String,
      runID: String)
      async throws
   {
      do {
         runSteps = try await service.listRunSteps(threadID: threadID, runID: runID, limit: nil, order: nil, after: nil, before: nil).data
      } catch let error as APIError {
         errorMessage = error.displayDescription
         throw error
      }
   }
   
   func getLastRunSteps(
      threadID: String,
      runID: String)
      async throws -> (messageCreationStep: RunStepObject?, toolCallsStep: RunStepObject?) {
      do {
         let timeoutDuration = 30_000_000_000 // 30 seconds in nanoseconds
         var runStepObjects: (messageCreationStep: RunStepObject?, toolCallsStep: RunStepObject?) = (nil, nil)
         
         try await withThrowingTaskGroup(of: (RunStepObject?, RunStepObject?).self) { group in
            // Polling task
            group.addTask { [weak self] in
               return try await self?.pollForCompletionLastRuns(threadID: threadID, runID: runID) ?? (nil, nil)
            }
            
            // Timeout task
            group.addTask {
               try await Task.sleep(nanoseconds: UInt64(timeoutDuration))
               throw APIError.timeOutError
            }
            
            // Wait for the first task to complete
            for try await result in group {
               runStepObjects = result
               break
            }
            
            // Cancel any remaining tasks (either the polling task or the timeout task)
            group.cancelAll()
         }
         
         return runStepObjects
      } catch let error as APIError {
         errorMessage = error.displayDescription
         return (nil, nil)
      }
   }
   
   // MARK: Private
   
   private func pollForCompletionLastRuns(
      threadID: String,
      runID: String)
      async throws -> (messageCreationStep: RunStepObject?, toolCallsStep: RunStepObject?)
   {
      var lastMessageCreationStep: RunStepObject? = nil
      var lastToolCallsStep: RunStepObject? = nil
      let maxRetries = 10
      var currentRetryCount = 0
      var isCompleted = false
      
      while !isCompleted && currentRetryCount < maxRetries {
         if Task.isCancelled {
            break
         }
         
         let data = try await getRunSteps(threadID: threadID, runID: runID)
         for step in data {
            if let status = RunStepObject.Status(rawValue: step.status), status != .inProgress {
               switch step.stepDetails.type {
               case "message_creation":
                  lastMessageCreationStep = step
               case "tool_calls":
                  if let toolCalls = step.stepDetails.toolCalls,
                     toolCalls.contains(where: { $0.type == "code_interpreter" && !($0.toolCall.codeInterpreter?.outputs.isEmpty ?? true) }) {
                     lastToolCallsStep = step
                  }
               default:
                  break
               }
            }
         }
         
         if lastMessageCreationStep != nil && lastToolCallsStep != nil {
            isCompleted = true  // Set the flag to true to break the loop
         } else {
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
            currentRetryCount += 1
         }
      }
      return (lastMessageCreationStep, lastToolCallsStep)
   }
      
   private func getRunSteps(
      threadID: String,
      runID: String)
      async throws -> [RunStepObject]
   {
      do {
         return try await service.listRunSteps(threadID: threadID, runID: runID, limit: nil, order: nil, after: nil, before: nil).data
      } catch let error as APIError {
         errorMessage = error.displayDescription
         throw error
      }
   }
}
