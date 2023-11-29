//
//  ThreadProvider.swift
//  GPTExplorer
//
//  Created by James Rochabrun on 11/21/23.
//

import Foundation
import SwiftOpenAI

@Observable class ThreadProvider {
   
   private let service: OpenAIService
   let threadsIDStorage = UserDefaultsIDStorage<String>(key: "threadsIDStorage")
   static let assistantMetadataID = "assistant_id"
   static let assistantMetadataName = "assistant_name"
   static let assistantMetadataDescription = "assistant_description"
   static let assistantMessageSnippet = "assistant_message_snippet"

   var threadObject: ThreadObject?
   var errorMessage: String?
   var deletionStatus: ThreadObject.DeletionStatus?

   // MARK: - Initializer
   
   init(service: OpenAIService) {
      self.service = service
   }
   
   func createThread(
      parameters: CreateThreadParameters)
      async throws
   {
      do {
         let newThread = try await service.createThread(parameters: parameters)
         threadsIDStorage.add(id: newThread.id)
         threadObject = newThread
         dump(newThread)
      } catch let error as APIError  {
         errorMessage = error.displayDescription
      }
   }
   
   func retrieveThread(
      id: String)
      async throws
   {
      do {
         threadObject = try await service.retrieveThread(id: id)
      } catch let error as APIError  {
         errorMessage = error.displayDescription
      }
   }
   
   func modifyThread(
      id: String,
      parameters: ModifyThreadParameters)
      async throws
   {
      do {
         threadObject = try await service.modifyThread(id: id, parameters: parameters)
      } catch let error as APIError  {
         errorMessage = error.displayDescription
      }
   }
   
   func deleteThread(
      id: String)
      async throws
   {
      do {
         deletionStatus = try await service.deleteThread(id: id)
         if deletionStatus?.deleted == true {
            threadsIDStorage.remove(id: id)
         }
      } catch let error as APIError  {
         errorMessage = error.displayDescription
      }
   }
   
   func listThreads()
      async throws -> [ThreadObject]
   {
       // Get all the thread ids
       let ids = threadsIDStorage.retrieve()

       // Array to hold tasks
       var tasks: [Task<ThreadObject, Error>] = []

       // Start a new task for each thread retrieval
       for id in ids {
           let task = Task { try await service.retrieveThread(id: id) }
           tasks.append(task)
       }

       // Array to hold the results
       var threads: [ThreadObject] = []

       // Await for each task to complete and gather results
       for task in tasks {
           let threadObject = try await task.value
           threads.append(threadObject)
       }
      
      return threads
   }
   
   func deleteThreads()
      async throws -> [ThreadObject.DeletionStatus]
   {
      let ids = threadsIDStorage.retrieve()

      var tasks: [Task<ThreadObject.DeletionStatus, Error>] = []

      for id in ids {
          let task = Task { try await service.deleteThread(id: id) }
          tasks.append(task)
      }

      var deletionStatuses: [ThreadObject.DeletionStatus] = []

      for task in tasks {
          let deletionStatus = try await task.value
         deletionStatuses.append(deletionStatus)
      }
      
      return deletionStatuses
   }
}
