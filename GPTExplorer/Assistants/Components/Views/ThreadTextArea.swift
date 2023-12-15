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
   @Binding var showAudioSpeech: Bool?
   
   init(
      prompt: Binding<String>,
      isAddAndRunActionLoading: Binding<Bool?>,
      isAddMessageActionLoading: Binding<Bool?>,
      showAudioSpeech: Binding<Bool?>,
      fileIDS: [String]? = nil,
      addAndRunAction: @escaping () -> Void,
      addMessageAction: @escaping () -> Void)
   {
      self._prompt = prompt
      _isAddAndRunActionLoading = isAddAndRunActionLoading
      _isAddMessageActionLoading = isAddMessageActionLoading
      _showAudioSpeech = showAudioSpeech
      self.fileIDS = fileIDS
      self.addAndRunAction = addAndRunAction
      self.addMessageAction = addMessageAction
   }

   var body: some View {
      VStack(alignment: .leading, spacing: Sizes.spacingExtraLarge) {
         textField
         files
         actions
           // .fixedSize(horizontal: true, vertical: false)
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
   
   var filesButton: some View {
      IconButton(iconName: "paperclip") {
      }
      .iconButtonStyle(.tertiary)
   }
   
   var addMessageButton: some View {
      IconButton(iconName: "plus", isLoading: $isAddMessageActionLoading) {
         addMessageAction()
      }
      .iconButtonStyle(.tertiary)
      .disabled(prompt.isEmpty)
   }
   
   var runMessageButton: some View {
      ActionButton("Run", actionIcon: Image(systemName: "play.circle"), isLoading: $isAddAndRunActionLoading) {
         addAndRunAction()
      }
      .disabled(prompt.isEmpty)
      .actionButtonStyle(.plain)
   }
   
   @ViewBuilder
   var audioSpeachButton: some View {
      if showAudioSpeech != nil, prompt.isEmpty {
         IconButton(iconName: "beats.headphones") {
            showAudioSpeech = true
         }
         .iconButtonStyle(.circleTertiary)
      }
   }
   
   var actions: some View {
      HStack {
         filesButton
         Spacer()
         addMessageButton
         runMessageButton
         audioSpeachButton
      }
      .animation(.easeInOut, value: prompt.isEmpty)
   }
   
   @ViewBuilder
   var files: some View {
      if let fileIDS, !fileIDS.isEmpty {
         VStack(spacing: 0) {
            ForEach(fileIDS, id: \.self) { fileID in
               // TODO: Use file uploader
               AttachmentView(fileName: fileID, actionTrigger: .constant(false), isLoading: false)
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
         showAudioSpeech: .constant(false),
         addAndRunAction: { },
         addMessageAction: { })
      ThreadTextArea(
         prompt: .constant("Some input"),
         isAddAndRunActionLoading: .constant(false),
         isAddMessageActionLoading: .constant(true),
         showAudioSpeech: .constant(false),
         fileIDS: ["Screenshot: 2023: 10-09 at 9:35.png"],
         addAndRunAction: { },
         addMessageAction: { })
      
      ThreadTextArea(
         prompt: .constant("Some input"),
         isAddAndRunActionLoading: .constant(false),
         isAddMessageActionLoading: .constant(false),
         showAudioSpeech: .constant(true),
         fileIDS: ["Screenshot: 2023: 10-09 at 9:35.png"],
         addAndRunAction: { },
         addMessageAction: { })
      .disabled(true)
   }
}
