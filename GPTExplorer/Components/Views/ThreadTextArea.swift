//
//  ThreadTextArea.swift
//  GPTExplorer
//
//  Created by James Rochabrun on 11/21/23.
//

import Foundation
import SwiftUI
import SwiftOpenAI

struct ThreadTextArea: View {
      
   @State private var prompt: String = ""
   let addAndRunAction: (String) -> Void
   let addMessageAction: (String) -> Void
   let fileIDS: [String]?
   
   init(
      fileIDS: [String]? = nil,
      addAndRunAction: @escaping (String) -> Void,
      addMessageAction: @escaping (String) -> Void)
   {
      self.fileIDS = fileIDS
      self.addAndRunAction = addAndRunAction
      self.addMessageAction = addMessageAction
   }

   var body: some View {
      VStack(alignment: .leading, spacing: Sizes.spacingExtraLarge) {
         textField
         files
         actions
      }
      .padding(.vertical, Sizes.spacingExtraLarge)
      .padding(.horizontal, Sizes.spacingExtraLarge)
      .background(
         RoundedRectangle(cornerRadius: Sizes.spacingExtraLarge)
            .stroke(.gray.opacity(0.5), lineWidth: 1)
      )
      .background(.background)
      .padding(.horizontal)
   }
   
   var textField: some View {
      TextField(
         "How Can I help you today?",
         text: $prompt,
         axis: .vertical)
   }
   
   var actions: some View {
      HStack {
         ActionButton("Add an run", actionIcon: Image(systemName: "play")) {
            addAndRunAction(prompt)
         }
         .actionButtonStyle(.plain)
         ActionButton("Add") {
            addMessageAction(prompt)
         }
         .actionButtonStyle(.secondary)
         IconButton(iconName: "paperclip") {
         }
         .iconButtonStyle(.secondary)
      }
   }
   
   @ViewBuilder
   var files: some View {
      if let fileIDS, !fileIDS.isEmpty {
         VStack(spacing: 0) {
            ForEach(fileIDS, id: \.self) { fileID in
               HStack {
                  Image(systemName: "doc")
                     .resizable()
                     .aspectRatio(contentMode: .fit)
                     .frame(width: 10)
                     .foregroundColor(.secondary)
                  Text(fileID)
                     .font(.caption2)
               }
               .padding(.horizontal, Sizes.spacingMedium)
               .padding(.vertical, Sizes.spacingMedium)
               .background(
                  RoundedRectangle(cornerRadius: 8)
                     .stroke(.gray.opacity(0.5), lineWidth: 0.5)
               )
            }
         }
         .animation(.bouncy, value: fileIDS.isEmpty)
      }
   }
}

#Preview {
   VStack {
      ThreadTextArea(
         addAndRunAction: { _ in },
         addMessageAction: { _ in })
      ThreadTextArea(
         fileIDS: ["Screenshot: 2023: 10-09 at 9:35.png"],
         addAndRunAction: { _ in },
         addMessageAction: { _ in })

   }
}
