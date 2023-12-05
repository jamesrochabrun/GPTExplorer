//
//  FilesProvider.swift
//  GPTExplorer
//
//  Created by James Rochabrun on 12/4/23.
//

import SwiftOpenAI
import SwiftUI

// TODO: Use the assistants API
/// https://platform.openai.com/docs/api-reference/assistants/getAssistantFile
/// List assistant filesBeta instead of object fileIDS?
/// fix the error: the issue is that the assistat has a file passed in to the parameter, so first ty to get the assistant files and see if if matches the filids!

final class FilesProvider {
   
   private let service: OpenAIService
   
   var files: [FileObject] = []
   var uploadedFile: FileObject? = nil
   var deletedStatus: FileObject.DeletionStatus? = nil
   var retrievedFile: FileObject? = nil
   var fileContent: [[String: Any]] = []

   init(service: OpenAIService) {
      self.service = service
   }
   
   func listFiles() async throws {
      files = try await service.listFiles().data
   }
   
   func uploadFile(
      parameters: FileParameters)
      async throws -> FileObject?
   {
      try await service.uploadFile(parameters: parameters)
   }
   
   func deleteFileWith(
      id: String)
      async throws -> FileObject.DeletionStatus?
   {
      try await service.deleteFileWith(id: id)
   }
   
   func retrieveFileWith(
      id: String)
      async throws -> FileObject?
   {
      try await service.retrieveFileWith(id: id)
   }
   
   func retrieveContentForFileWith(
      id: String)
      async throws
   {
      fileContent = try await service.retrieveContentForFileWith(id: id)
   }
}
