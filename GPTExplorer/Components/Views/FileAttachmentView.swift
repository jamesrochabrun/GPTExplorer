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
      action: FilePickerAction,
      fileUploadedCompletion: @escaping (_ file: FileObject) -> Void,
      fileDeletedCompletion: @escaping (_ parameters: FilePickerAction, _ id: String) -> Void)
   {
      self.fileProvider = FilesProvider(service: service)
      self.action = action
      self.fileUploadedCompletion = fileUploadedCompletion
      self.fileDeletedCompletion = fileDeletedCompletion
   }
   
   func newUploadedFileView(
      parameters: FileParameters)
      -> some View
   {
      AttachmentView(fileName: fileObject?.filename ?? parameters.fileName, actionTrigger: $deleted, isLoading: fileObject == nil || deleted)
         .disabled(fileObject == nil)
         .opacity(fileObject == nil ? 0.3 : 1)
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
   }
   
   func previousUploadedFileView(
      id: String)
      -> some View
   {
      AttachmentView(fileName: fileObject?.filename ?? "Document", actionTrigger: $deleted, isLoading: fileObject == nil || deleted)
         .onFirstAppear {
            Task {
               fileObject = try await fileProvider.retrieveFileWith(id: id)
            }
         }
   }

   var body: some View {
      Group {
         switch action {
         case .request(let parameters):
            newUploadedFileView(parameters: parameters)
         case .retrieveAndDisplay(let id):
            previousUploadedFileView(id: id)
         }
      }
      .onChange(of: deleted) { oldValue, newValue in
         if oldValue != newValue, newValue {
            Task {
               if let fileObject {
                  fileDeleteStatus = try await fileProvider.deleteFileWith(id: fileObject.id)
               }
            }
         }
      }
      .onChange(of: fileDeleteStatus) { oldValue, newValue in
         if oldValue != newValue, let newValue, newValue.deleted {
            fileDeletedCompletion(action, newValue.id)
         }
      }
   }
   
   // MARK: Private
   
   private let fileProvider: FilesProvider
   private let fileUploadedCompletion: (_ file: FileObject) -> Void
   private let fileDeletedCompletion: (_ action: FilePickerAction, _ id: String) -> Void
   private let action: FilePickerAction
   @State private var fileObject: FileObject?
   @State private var fileDeleteStatus: FileObject.DeletionStatus?
   @State private var deleted: Bool = false
}

