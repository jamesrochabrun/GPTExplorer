//
//  ThreadProvider.swift
//  GPTExplorer
//
//  Created by James Rochabrun on 11/21/23.
//

import Foundation
import SwiftOpenAI

// MARK: ThreadMetadataKeys

enum ThreadMetadataKeys {
   
   static let assistantMetadataID = "assistant_id"
   static let assistantMetadataName = "assistant_name"
   static let assistantMetadataDescription = "assistant_description"
   static let assistantMessageSnippet = "assistant_message_snippet"
}

extension ThreadObject: Equatable {
   
   public static func == (lhs: ThreadObject, rhs: ThreadObject) -> Bool {
      lhs.id == rhs.id
   }

   var assistantID: String? {
      metadata[ThreadMetadataKeys.assistantMetadataID]
   }
   
   var assistantName: String? {
      metadata[ThreadMetadataKeys.assistantMetadataName]
   }
   
   var displayTitle: String? {
      metadata[ThreadMetadataKeys.assistantMessageSnippet]
   }
   
   var assistantDescription: String? {
      metadata[ThreadMetadataKeys.assistantMetadataDescription]
   }
}

// MARK: ThreadProvider

@Observable class ThreadProvider {
   
   private let service: OpenAIService
   let threadsIDStorage = UserDefaultsIDStorage<String>(key: "threadsIDStorage")

   var errorMessage: String?
   var successMessage: String?
   var deletionStatus: ThreadObject.DeletionStatus?

   // MARK: - Initializer
   
   init(service: OpenAIService) {
      self.service = service
   }
   
   func createThread(
      parameters: CreateThreadParameters)
      async throws -> ThreadObject?
   {
      do {
         let newThread = try await service.createThread(parameters: parameters)
         threadsIDStorage.add(id: newThread.id)
         return newThread
      } catch let error as APIError  {
         errorMessage = error.displayDescription
         return nil
      }
   }
   
   
   func modifyThread(
      id: String,
      parameters: ModifyThreadParameters)
      async throws
   {
      do {
         let _ = try await service.modifyThread(id: id, parameters: parameters)
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
            successMessage = "Thread ID: \(id) \n DELETED"
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
      for task in tasks.enumerated() {
         do {
            let threadObject = try await task.element.value
            threads.append(threadObject)
         } catch {
            print("UNABLE TO RETRIEVE THREAD WITH ID \(ids[task.offset]) PERHAPS IT DOES NOT EXIST")
         }
      }
      return threads
   }
   
   func deleteThreads()
      async throws -> [ThreadObject.DeletionStatus]
   {
      do {
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
      } catch let error as APIError  {
         errorMessage = error.displayDescription
         return []
      }
   }
   
   // MARK: Prompting
   
   func defineThreadSnippetForMetadata(
      thread: ThreadObject?,
      prompt: String)
      async throws
   {
      guard
         let thread,
         thread.metadata[ThreadMetadataKeys.assistantMessageSnippet] == nil
      else {
         return
      }
      do {
         var messages: [ChatCompletionParameters.Message] = []
         messages.append(ChatCompletionParameters.Message(role: .assistant, content: .text(Self.instructionsForThreadTitle)))
         let modifiedUsersPrompt = "Summarize this in no more than 5 words: `\(prompt)`"
         
         messages.append(ChatCompletionParameters.Message(role: .user, content: .text(modifiedUsersPrompt)))
         let response = try await service.startChat(parameters: .init(messages: messages, model: .gpt4))
         let content = (response.choices.first?.message.content ?? "").replacingOccurrences(of: "\"", with: "")
         var threadMetadata = thread.metadata
         threadMetadata[ThreadMetadataKeys.assistantMessageSnippet] = content
         
         try await modifyThread(id: thread.id, parameters: .init(metadata: threadMetadata))
      } catch let error as APIError  {
         errorMessage = error.displayDescription
      }
   }
   
   private static var instructionsForThreadTitle = """
Given a text snippet, your task is to generate a concise and relevant title that accurately reflects the main idea of the snippet. Follow these steps:
Identify Key Terms: Extract the main nouns and verbs from the snippet. These words are usually the most critical in conveying the snippet's primary subject and action.
Eliminate Extra Words: Remove any unnecessary words that don't contribute to the main idea. This includes auxiliary verbs, conjunctions, prepositions, and filler words.
Maintain Core Idea: Ensure that the reduced phrase still encapsulates the essence of the original snippet. The title should be a clear and direct representation of the snippet's main idea.
Rephrase for Coherence: Do not reword the phrase to make it flow better as a title. The goal is to create a coherent and catchy title that is easy to read and understand but that keeps the same wording as the given text.
Apply Title Case: Convert the first letter of each major word in your final phrase to uppercase. Prepositions, conjunctions, and articles should generally be in lowercase unless they are the first word of the title.
Limit Title Length: Aim for brevity. Ideally, the title should be no longer than 5-7 words, capturing the essence of the snippet in a compact form.
The most important: DO NOT ANSWER THE PROMPT AS IT IS A QUESTION, GIVE ME THE TITLE ONLY and do not wrap the content in quotes.
"""
}
