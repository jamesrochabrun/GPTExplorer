//
//  FileAttachmentView.swift
//  GPTExplorer
//
//  Created by James Rochabrun on 12/4/23.
//

import SwiftUI
import SwiftOpenAI

struct FileAttachmentView: View {
   
   init(
      service: OpenAIService,
      parameters: FileParameters, 
      fileUploadedCompletion: @escaping (_ file: FileObject) -> Void,
      fileDeletedCompletion: @escaping (_ parameters: FileParameters, _ id: String) -> Void)
   {
      self.fileProvider = FilesProvider(service: service)
      self.parameters = parameters
      self.fileUploadedCompletion = fileUploadedCompletion
      self.fileDeletedCompletion = fileDeletedCompletion
   }

   var body: some View {
      AttachmentView(fileName: fileObject?.filename ?? parameters.fileName, actionTrigger: $deleted)
         .disabled(fileObject == nil)
         .opacity(fileObject == nil ? 0.3 : 1)
         .onChange(of: deleted) { oldValue, newValue in
            if oldValue != newValue, newValue {
               Task {
                  if let fileObject {
                     fileDeleteStatus = try await fileProvider.deleteFileWith(id: fileObject.id)
                  }
               }
            }
         }
         .onFirstAppear {
            Task {
               fileObject = try await fileProvider.uploadFile(parameters: parameters)
            }
         }
         .onChange(of: fileObject) { oldValue, newValue in
            if oldValue != newValue, let newValue {
               fileUploadedCompletion(newValue)
            }
         }
         .onChange(of: fileDeleteStatus) { oldValue, newValue in
            if oldValue != newValue, let newValue, newValue.deleted {
               fileDeletedCompletion(parameters, newValue.id)
            }
         }
   }
   
   // MARK: Private
   
   private let fileProvider: FilesProvider
   private let fileUploadedCompletion: (_ file: FileObject) -> Void
   private let fileDeletedCompletion: (_ parameters: FileParameters, _ id: String) -> Void
   private let parameters: FileParameters
   @State private var fileObject: FileObject?
   @State private var fileDeleteStatus: FileObject.DeletionStatus?
   @State private var deleted: Bool = false
}

