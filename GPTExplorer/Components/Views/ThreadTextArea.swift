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
      
   @Binding var prompt: String
   let addAndRunAction: () -> Void
   @Binding var isAddAndRunActionLoading: Bool?
   let addMessageAction: () -> Void
   @Binding var isAddMessageActionLoading: Bool?
   let fileIDS: [String]?
   
   init(
      prompt: Binding<String>,
      isAddAndRunActionLoading: Binding<Bool?>,
      isAddMessageActionLoading: Binding<Bool?>,
      fileIDS: [String]? = nil,
      addAndRunAction: @escaping () -> Void,
      addMessageAction: @escaping () -> Void)
   {
      self._prompt = prompt
      _isAddAndRunActionLoading = isAddAndRunActionLoading
      _isAddMessageActionLoading = isAddMessageActionLoading
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
         ActionButton("Add an run", actionIcon: Image(systemName: "play"), isLoading: $isAddAndRunActionLoading) {
            addAndRunAction()
         }
         .disabled(prompt.isEmpty)
         .actionButtonStyle(.plain)
         ActionButton("Add", isLoading: $isAddMessageActionLoading) {
            addMessageAction()
         }
         .disabled(prompt.isEmpty)
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
         prompt: .constant("Some input"),
         isAddAndRunActionLoading: .constant(true),
         isAddMessageActionLoading: .constant(true),
         addAndRunAction: { },
         addMessageAction: { })
      ThreadTextArea(
         prompt: .constant("Some input"),
         isAddAndRunActionLoading: .constant(false),
         isAddMessageActionLoading: .constant(true),
         fileIDS: ["Screenshot: 2023: 10-09 at 9:35.png"],
         addAndRunAction: { },
         addMessageAction: { })

   }
}
