//
//  SideMenuConfigurationProvider.swift
//  GPTExplorer
//
//  Created by James Rochabrun on 11/20/23.
//

import Foundation
import SwiftOpenAI
import SwiftUI

extension FileObject.DeletionStatus: Equatable {
   public static func == (lhs: FileObject.DeletionStatus, rhs: FileObject.DeletionStatus) -> Bool {
      lhs.id == rhs.id
   }
}

extension FileObject: Equatable {
   public static func == (lhs: FileObject, rhs: FileObject) -> Bool {
      lhs.id == rhs.id
   }
}

extension FileParameters: Equatable, Identifiable {
   public static func == (lhs: FileParameters, rhs: FileParameters) -> Bool {
      lhs.file == rhs.file &&
      lhs.fileName == rhs.fileName &&
      lhs.purpose == rhs.purpose
   }
   
   public var id: String {
      fileName
   }
}

extension ModifyThreadParameters: Equatable {
   public static func == (lhs: ModifyThreadParameters, rhs: ModifyThreadParameters) -> Bool {
      lhs.metadata == rhs.metadata
   }
}

enum ProviderState: Equatable {
   
   case threadDeletedSuccess(id: String, message: String)
   case threadDeletedError(id: String, message: String)
   case threadUpdatedSuccess(id: String, message: String)
   case threadUpdatedError(id: String, parameters: ModifyThreadParameters, message: String)
   case threadCreatedError(metadata: [String: String], message: String)
   case listThreadsError(message: String)
   case deleteThreadsSuccess(message: String)
   case deleteThreadsError(message: String)

   case assistantDeletedSuccess(id: String, message: String)
   case assistantDeletedError(id: String, message: String)
   case assistantUpdatedSuccess(id: String, message: String)
   case assistantUpdatedError(id: String, message: String)
   case assistantCreatedSuccess(message: String)
   case assistantCreatedError(parameters: AssistantParameters, message: String)
   case assistantAvatarCreatedError(prompt: String, message: String)
   case asssitantRetrievedError(id: String, message: String)
   case listAssistantsError(message: String)
   
   case udpateSideMenuError(sections: Set<SideMenuConfigurationProvider.Section>, message: String)
   
   case uploadedFileError(message: String)
   
   var message: String {
      switch self {
      case .threadDeletedSuccess(_, let message): return message
      case .threadDeletedError(_, let message): return message
      case .threadUpdatedSuccess(_, let message): return message
      case .threadUpdatedError(_, _, let message): return message
      case .threadCreatedError(_, let message): return message
      case .listThreadsError(let message): return message
      case .deleteThreadsSuccess(let message): return message
      case .deleteThreadsError(let message): return message
      case .assistantDeletedSuccess(_, let message): return message
      case .assistantDeletedError(_, let message): return message
      case .assistantUpdatedSuccess(_, let message): return message
      case .assistantUpdatedError(_, let message): return message
      case .assistantCreatedError(_, let message): return message
      case .assistantAvatarCreatedError(_, let message): return message
      case .asssitantRetrievedError(_, let message): return message
      case .listAssistantsError(let message): return message
      case .udpateSideMenuError(_, let message): return message
      case .assistantCreatedSuccess(message: let message): return message
      case .uploadedFileError(let message): return message
      }
   }
}

// MARK: ThreadMetadataKeys

enum ThreadMetadataKeys {
   
   static let assistantMetadataID = "assistant_id"
   static let assistantMetadataName = "assistant_name"
   static let assistantMetadataDescription = "assistant_description"
   static let assistantMessageSnippet = "assistant_message_snippet"
}


enum AssistantMetadataKeys {
   
   static let avatarMetadataKey = "assistant_avatar"
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

enum SideMenuItem: Identifiable, Equatable {
   
   static func == (lhs: SideMenuItem, rhs: SideMenuItem) -> Bool {
      lhs.id == rhs.id
   }
   
   var id: String {
      switch self {
      case .assistant(let assistant):
         return assistant.id
      case .thread(let thread):
         return thread.id
      case .chat: return "chat"
      case .action(let action): return action.rawValue
      }
   }
   
   enum Action: String {
      case createAssistant
   }
   
   case assistant(AssistantObject)
   case thread(ThreadObject)
   case action(Action)
   case chat
}

@Observable class SideMenuConfigurationProvider {
   
   // MARK: - Private Properties
   
   enum Section: String, CaseIterable, Identifiable {
      
      case actions = "Actions"
      case chat = "Chat"
      case assistants = "Assistants"
      case threads = "Threads"
      
      var id: String { rawValue.capitalized }
   }
   
   let threadsIDStorage: UserDefaultsIDStorage<String> = UserDefaultsIDStorage<String>(key: "threadsIDStorage")
   let service: OpenAIService
   let filesProvider: FilesProvider
   let navigationProvider: NavigationProvider
   var mapItems: [Section: [SideMenuItem]] = [
      Section.actions: [.action(.createAssistant)],
      Section.chat: [.chat]
   ]
   
   // MARK: - Initializer
   
   init(service: OpenAIService)
   {
      self.service = service
      self.navigationProvider = .init()
      filesProvider = FilesProvider(service: service)
   }
   
   // MARK: Assistants
  
   private func listAssistants(
      limit: Int? = nil,
      order: String? = nil,
      after: String? = nil,
      before: String? = nil)
      async throws
      -> [AssistantObject]
   {
      do {
         return try await service.listAssistants(limit: limit, order: order, after: after, before: before).data
      } catch let error as APIError {
         debugPrint("Unable to list Assistants error: \(error.displayDescription)")
         return []
      }
    }
   
   func deleteAssistant(
      id: String)
      async throws -> ResultItem<AssistantObject.DeletionStatus>
   {
      do {
         let deletionStatus = try await service.deleteAssistant(id: id)
         if deletionStatus.deleted {
            deleteAssistantFromMapStorageWith(id: id)
            return .init(item: deletionStatus, state: .assistantDeletedSuccess(id: id, message: "Assistant ID: \(id) \n DELETED"))
         } else {
            throw APIError.invalidData
         }
      } catch let error as APIError  {
         switch error {
         case .invalidData:
            return .init(item: nil, state: .assistantDeletedError(id: id, message: "Unable to Delete assistant with id: \(id)"))
         default:
            return .init(item: nil, state: .assistantDeletedError(id: id, message: error.displayDescription))
         }
      }
   }
   
   private func deleteAssistantFromMapStorageWith(id: String) {
      var assistants = mapItems[.assistants]
      assistants?.removeAll(where: { item in
         item.id == id
      })
      mapItems[.assistants] = assistants
   }
   
   func createAssistant(
      parameters: AssistantParameters)
      async throws -> ResultItem<AssistantObject>
   {
      do {
         let assistantObject = try await service.createAssistant(parameters: parameters)
         addOrUpdateAssisantToMapStorage(assistantObject)
         return .init(item: assistantObject, state: .assistantCreatedSuccess(message: "\(assistantObject.name ?? "Assistant") has been created!"))
      } catch let error as APIError  {
         return .init(item: nil, state: .assistantCreatedError(parameters: parameters, message: error.displayDescription))
      }
   }
   
   private func addOrUpdateAssisantToMapStorage(_ assistant: AssistantObject) {
      // Check if mapItems contains the threads key and initialize it if not
      if mapItems[.assistants] == nil {
          mapItems[.assistants] = []
      }
      // Find the index of the existing thread based on the id
      if let index = mapItems[.assistants]?.firstIndex(where: { $0.id == assistant.id }) {
          // Replace the existing assistant at the found index
          mapItems[.assistants]?[index] = .assistant(assistant)
      } else {
          // Append the new assistant if not found
          mapItems[.assistants]?.append(.assistant(assistant))
      }
   }
   
   func modifyAssistant(
      id: String,
      parameters: AssistantParameters)
      async throws -> ResultItem<AssistantObject>
   {
      do {
         let assistantObject = try await service.modifyAssistant(id: id, parameters: parameters)
         addOrUpdateAssisantToMapStorage(assistantObject)
         return .init(item: assistantObject, state: .assistantUpdatedSuccess(id: id, message: "Assistant with id \(id) UPDATED"))
      } catch let error as APIError  {
         return .init(item: nil, state: .assistantUpdatedError(id: id, message: error.displayDescription))
      }
   }
   
   func createAvatar(
      prompt: String)
      async throws -> ResultItem<URL>
   {
      do {
         let avatarURL = try await service.createImages(parameters: .init(prompt: prompt, model: .dalle3(.largeSquare))).data.compactMap(\.url).first
         return .init(item: avatarURL, state: .deleteThreadsError(message: "YOU DOG"))
      } catch let error as APIError  {
         return .init(item: nil, state: .assistantAvatarCreatedError(prompt: prompt, message: error.displayDescription))
      }
   }
   
   // Edition asssistant Purposes
   func retrieveAssistantParameters(
      id: String,
      model: String?)
      async throws -> ResultItem<AssistantParameters>
   {
      do {
         let assistantParameters = try await service.retrieveAssistant(id: id).assistantParameters(model)
         return .init(item: assistantParameters, state: nil)
      } catch let error as APIError  {
         return .init(item: nil, state: .asssitantRetrievedError(id: id, message: error.displayDescription))
      }
   }
   
   func retrieveAssistant(
      id: String)
      async throws -> ResultItem<AssistantObject>
   {
      do {
         let assistant = try await service.retrieveAssistant(id: id)
         return .init(item: assistant, state: nil)
      } catch let error as APIError  {
         return .init(item: nil, state: .asssitantRetrievedError(id: id, message: error.displayDescription))
      }
   }
    
    
   // MARK: Threads
    
   private func listThreads()
      async throws -> [ThreadObject]
   {
      do {
         return try await constructAndListThreads()
      } catch let error as APIError {
         debugPrint("Unables to retrieve threads error: \(error.displayDescription)")
         return []
     }
   }
   
   func createThread(
      metadata: [String: String])
      async throws -> ResultItem<ThreadObject>
   {
      do {
         let parameters = CreateThreadParameters(metadata: metadata)
         let newThread = try await service.createThread(parameters: parameters)
         threadsIDStorage.add(id: newThread.id)
         addOrUpdateThreadToMapStorage(newThread)
         return .init(item: newThread, state: nil)
      } catch let error as APIError  {
         return .init(item: nil, state: .threadCreatedError(metadata: metadata, message: error.displayDescription))
      }
   }
   
   private func constructAndListThreads()
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
   
   private func modifyThread(
      id: String,
      parameters: ModifyThreadParameters)
      async throws
   {
      do {
         let newThread = try await service.modifyThread(id: id, parameters: parameters)
         addOrUpdateThreadToMapStorage(newThread)
      } catch let error as APIError  {
         debugPrint("Unable to modify THREAD metadata \(error.displayDescription)")
      }
   }
   
   func deleteThread(
      id: String)
      async throws -> ResultItem<ThreadObject.DeletionStatus>
   {
      do {
         let deletionStatus = try await service.deleteThread(id: id)
         if deletionStatus.deleted {
            threadsIDStorage.remove(id: id)
            deleteThreadFromMapStorageWith(threadID: id)
            return .init(item: deletionStatus, state: .threadDeletedSuccess(id: id, message: "Thread ID: \(id) \n DELETED"))
         } else {
            throw APIError.invalidData
         }
      } catch let error as APIError  {
         switch error {
         case .invalidData:
            return .init(item: nil, state: .threadDeletedError(id: id, message: "Unable to Delete thread with id: \(id)"))
         default:
            return .init(item: nil, state: .threadDeletedError(id: id, message: error.displayDescription))
         }
      }
   }
   
   func deleteThreads()
      async throws -> ResultItem<[ThreadObject.DeletionStatus]>
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
         return .init(item: deletionStatuses, state: .deleteThreadsSuccess(message: "Threads deleted"))
      } catch let error as APIError  {
         return .init(item: nil, state: .deleteThreadsError(message: error.displayDescription))
      }
   }
   
   private func deleteThreadFromMapStorageWith(threadID: String) {
      var threads = mapItems[.threads]
      threads?.removeAll(where: { item in
         item.id == threadID
      })
      mapItems[.threads] = threads
   }
   
   private func addOrUpdateThreadToMapStorage(_ thread: ThreadObject) {
      // Check if mapItems contains the threads key and initialize it if not
      if mapItems[.threads] == nil {
          mapItems[.threads] = []
      }
      
      // Find the index of the existing thread based on the id
      if let index = mapItems[.threads]?.firstIndex(where: { $0.id == thread.id }) {
          // Replace the existing thread at the found index
          mapItems[.threads]?[index] = .thread(thread)
      } else {
          // Append the new thread if not found
          mapItems[.threads]?.append(.thread(thread))
      }
   }
   
   func updateSideMenu(sections: Set<Section>) async throws -> ResultItem<Never> {
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
          return .init(item: nil, state: nil)
       } catch let error as APIError {
          return .init(item: nil, state: .udpateSideMenuError(sections: sections, message: error.displayDescription))
       }
   }

   // MARK: Private
   
   private var threadItems: [SideMenuItem] = []
   private var assistantItems: [SideMenuItem] = []
   
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
         print("THREAD SNIPPET CREATION ERROR \(error.displayDescription)")
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

struct ResultItem<T> {
   
   let item: T?
   let state: ProviderState?
}
