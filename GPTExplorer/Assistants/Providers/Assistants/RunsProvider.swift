//
//  RunsProvider.swift
//  GPTExplorer
//
//  Created by James Rochabrun on 11/25/23.
//

import SwiftUI
import SwiftOpenAI

typealias LastRunStep = (messageCreationStep: RunStepObject?, toolCallsStep: RunStepObject?)

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
      async throws -> ResultItem<LastRunStep> {
      do {
         let timeoutDuration = 30_000_000_000 // 30 seconds in nanoseconds
         var lastRunStep: ResultItem<LastRunStep> = .init(item: nil, state: nil)
      
         try await withThrowingTaskGroup(of: ResultItem<LastRunStep>.self) { group in
            // Polling task
            group.addTask { [weak self] in
               return try await self?.pollForCompletionLastRuns(threadID: threadID, runID: runID) ?? .init(item: nil, state: nil)
            }
            
            // Timeout task
            group.addTask {
               try await Task.sleep(nanoseconds: UInt64(timeoutDuration))
               throw APIError.timeOutError
            }
            
            // Wait for the first task to complete
            for try await result in group {
               lastRunStep = result
               break
            }
            
            // Cancel any remaining tasks (either the polling task or the timeout task)
            group.cancelAll()
         }
         
         if let item = lastRunStep.item {
            
            if item.messageCreationStep == nil && item.toolCallsStep == nil {
               return .init(item: nil, state: .lastRunStepsError(message: "No Step details found for \(threadID) with \(runID)"))

            } else {
               return .init(item: item, state: nil)
            }
            
         } else {
            return .init(item: nil, state: lastRunStep.state)
         }
               
      } catch let error as APIError {
         return .init(item: nil, state: .lastRunStepsError(message: error.displayDescription))
      }
   }
   
   // MARK: Private
   
   private func pollForCompletionLastRuns(
      threadID: String,
      runID: String)
      async throws -> ResultItem<LastRunStep>
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
         
         let runStepsResponse = try await getRunSteps(threadID: threadID, runID: runID)
         guard let steps = runStepsResponse.item else {
            return .init(item: nil, state: runStepsResponse.state)
         }
         
         for step in steps {
               switch step.stepDetails.type {
               case "message_creation":
                  // We need status to be "completed" so we can get a valid message id.
                  if let status = RunStepObject.Status(rawValue: step.status), status == .completed {
                     lastMessageCreationStep = step
                  }
               case "tool_calls":
                  // TODO!: This can return many tool calls of type "code_interpreter", "retrieval" or "function" consider updating
                  // `LastRunStep` to return an array of tool calls. This is important so we can handle multiple function calls.
                  // For now we just get the first one
                  
                  if let toolCall = step.stepDetails.toolCalls?.first {
                     switch toolCall.toolCall {
                     case .codeInterpreterToolCall(let codeInterpreterToolCall):
                        if !codeInterpreterToolCall.outputs.isEmpty {
                           lastToolCallsStep = step
                        }
                     case .retrieveToolCall(let retrievalToolCall):
                        if let retrieval = retrievalToolCall.retrieval, !retrieval.isEmpty {
                           lastToolCallsStep = step
                        }
                     case .functionToolCall(let functionToolCall):
                        if !functionToolCall.arguments.isEmpty {
                           lastToolCallsStep = step
                        }
                     }
                  }
                  
               default:
                  break
               }
         }
         
         if lastMessageCreationStep != nil && lastToolCallsStep != nil {
            isCompleted = true  // Set the flag to true to break the loop
         } else {
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
            currentRetryCount += 1
         }
      }
      return .init(item: (lastMessageCreationStep, lastToolCallsStep), state: nil)
   }
      
   private func getRunSteps(
      threadID: String,
      runID: String)
      async throws -> ResultItem<[RunStepObject]>
   {
      do {
         let runSteps = try await service.listRunSteps(threadID: threadID, runID: runID, limit: nil, order: nil, after: nil, before: nil).data
         return .init(item: runSteps, state: nil)
      } catch let error as APIError {
         return .init(item: nil, state: .getRunStepsError(message: error.displayDescription))
      }
   }
}
