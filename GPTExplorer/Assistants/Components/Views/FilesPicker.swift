//
//  FilesPicker.swift
//  GPTExplorer
//
//  Created by James Rochabrun on 12/4/23.
//

import SwiftUI
import SwiftOpenAI


enum FilePickerAction: Identifiable, Equatable {
   
   case request(FileParameters)
   case retrieveAndDisplay(id: String)
   
   var id: String {
      switch self {
      case .request(let fileParameters): return fileParameters.id
      case .retrieveAndDisplay(let id): return id
      }
   }
}


struct FilesPicker: View {
   
   @State private var presentImporter = false
   @Binding private var actions: [FilePickerAction]
   @Binding private var fileIDS: [String]
   private let service: OpenAIService
   private let sectionTitle: String?
   private let actionTitle: String
   
   init(
      service: OpenAIService,
      sectionTitle: String? = nil,
      actionTitle: String,
      fileIDS: Binding<[String]>,
      actions: Binding<[FilePickerAction]>)
   {
      self.service = service
      self.sectionTitle = sectionTitle
      self.actionTitle = actionTitle
      _fileIDS = fileIDS
      _actions = actions
   }
      
   var body: some View {
      VStack(alignment: .leading) {
         Group {
            if let sectionTitle {
               InputHeaderView(title: sectionTitle) {
                  ActionButton(actionTitle) {
                     presentImporter = true
                  }
               }
            } else {
               ActionButton(actionTitle) {
                  presentImporter = true
               }
            }
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
                     self.actions.append(.request(parameter))
                     // release access
                     file.stopAccessingSecurityScopedResource()
                  }
               case .failure(let error):
                  print(error)
               }
            }
            .actionButtonStyle(.plain)
         ForEach(actions, id: \.id) { action in
            FileAttachmentView(
               service: service,
               action: action) { fileResponse in
                  fileIDS.append(fileResponse.id)
               } fileDeletedCompletion: { actionToDelete, deletedFileID in
                  /// Remove file ids from network request.
                  fileIDS.removeAll(where: { id in
                     id == deletedFileID
                  })
                  /// Update UI
                  actions.removeAll { action in
                     actionToDelete.id == action.id
                  }
               }
         }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
   }
}


#Preview {
   FilesPicker(service: OpenAIServiceFactory.service(apiKey: ""), sectionTitle: "Knowledge", actionTitle: "Uplodad File", fileIDS: .constant(["s"]), actions: .constant(
      [.retrieveAndDisplay(id: "id1"), 
         .retrieveAndDisplay(id: "id2"),
         .retrieveAndDisplay(id: "id3"), 
         .retrieveAndDisplay(id: "id4"),
         .retrieveAndDisplay(id: "id5"),
         .retrieveAndDisplay(id: "id6")]
   ))
   .padding()
}
