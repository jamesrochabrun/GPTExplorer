//
//  ChatTextArea.swift
//  GPTExplorer
//
//  Created by James Rochabrun on 11/21/23.
//

import SwiftUI

// MARK: InputTextArea

struct ChatTextArea: View {
   
   @Binding var selectedImageURLS: [URL]
   @Binding var selectedImages: [Image]
   @Binding var prompt: String
   let sendButtonAction: () -> Void

   var body: some View {
      HStack(spacing: 0) {
         PhotoPicker(selectedImageURLS: $selectedImageURLS, selectedImages: $selectedImages)
         VStack(alignment: .leading, spacing: 0) {
            if !selectedImages.isEmpty {
               selectedImagesView
               Divider()
                  .foregroundColor(.gray)
            }
            textField
               .padding(6)
         }
         .padding(.vertical, 2)
         .padding(.horizontal, 2)
         .animation(.bouncy, value: selectedImages.isEmpty)
         .background(
            RoundedRectangle(cornerRadius: Sizes.spacingExtraLarge)
               .stroke(.gray, lineWidth: 1)
         )
         .padding(.horizontal, Sizes.spacingMedium)
         sendButton
      }
      .padding(.horizontal)
   }
   
   var selectedImagesView: some View {
      HStack(spacing: 0) {
         ForEach(0..<selectedImages.count, id: \.self) { i in
            selectedImages[i]
               .resizable()
               .frame(width: 60, height: 60)
               .clipShape(RoundedRectangle(cornerRadius: 12))
               .padding(Sizes.spacingExtraSmall)
         }
      }
   }
   
   var sendButton: some View {
      IconButton(iconName: "paperplane", action: sendButtonAction)
   }
   
   var textField: some View {
      TextField(
         "How Can I help you today?",
         text: $prompt,
         axis: .vertical)
   }
}

// MARK: Mock+Preview

#Preview {
   ChatTextArea(
      selectedImageURLS: .constant([urlImageViewMockURL]),
      selectedImages: .constant([Image(systemName: "paperplane")]),
      prompt: .constant("Hello world"),
      sendButtonAction: {})
}
