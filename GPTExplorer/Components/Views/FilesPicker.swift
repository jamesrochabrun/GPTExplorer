//
//  FilesPicker.swift
//  GPTExplorer
//
//  Created by James Rochabrun on 12/4/23.
//

import SwiftUI
import SwiftOpenAI

struct FilesPicker: View {
   
   @State private var presentImporter = false
   @State private var fileParameters: [FileParameters] = []
   
   @Binding private var fileIDS: [String]
   private let service: OpenAIService
   
   init(
      service: OpenAIService,
      fileIDS: Binding<[String]>)
   {
      self.service = service
      _fileIDS = fileIDS
   }
   
   var body: some View {
      VStack {
         InputHeaderView(title: "Knowledge") {
            ActionButton("Upload Files") {
               presentImporter = true
            }
            .fileImporter(
               isPresented: $presentImporter,
               allowedContentTypes: [.pdf, .text, .mp3, .mpeg],
               allowsMultipleSelection: true) { result in
                  switch result {
                  case .success(let files):
                     files.forEach { file in
                        // gain access to the directory
                        let gotAccess = file.startAccessingSecurityScopedResource()
                        if !gotAccess { return }
                        // access the directory URL
                        /// DO stuff
                        let data = try! Data(contentsOf: file.absoluteURL)
                        let parameter = FileParameters(fileName: file.lastPathComponent, file: data, purpose: "assistants")
                        self.fileParameters.append(parameter)
                        // release access
                        file.stopAccessingSecurityScopedResource()
                     }
                  case .failure(let error):
                     print(error)
                  }
               }
               .actionButtonStyle(.plain)
         }
         ForEach(fileParameters, id: \.id) { parameter in
            FileAttachmentView(
               service: service,
               parameters: parameter) { fileResponse in
                  fileIDS.append(fileResponse.id)
               } fileDeletedCompletion: { fileParam, deletedFileID in
                  /// Remove file ids from network request.
                  fileIDS.removeAll(where: { id in
                     id == deletedFileID
                  })
                  /// Update UI
                  fileParameters.removeAll { params in
                     fileParam.fileName == params.fileName
                  }
               }
         }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
   }
}
