//
//  CreateAssistantChatScreen.swift
//  GPTExplorer
//
//  Created by James Rochabrun on 12/9/23.
//

import Foundation
import SwiftUI
import SwiftOpenAI

struct CreateAssistantChatScreen: View {
   
   init(
      provider: ChatProvider,
      assistantParameters: Binding<AssistantParameters>,
      showAudioSpeech: Binding<Bool?>)
   {
      _chatProvider = State(initialValue: provider)
      _assistantParameters = assistantParameters
      _showAudioSpeech = showAudioSpeech
   }
   
   var body: some View {
      NavigationView {
         ScrollViewReader { proxy in
            VStack {
               Group {
                  if chatProvider.chatDisplayMessages.isEmpty {
                     assistantEmptyView
                  } else {
                     chatList
                  }
               }
               .onChange(of: chatProvider.chatDisplayMessages.last?.content) {
                  let lastMessage = chatProvider.chatDisplayMessages.last
                  if let id = lastMessage?.id {
                     proxy.scrollTo(id, anchor: .bottom)
                  }
               }
               .onChange(of: chatProvider.assistantParameters) { oldValue, newValue in
                  if oldValue != newValue {
                     assistantParameters = newValue
                  }
               }
               textArea
            }
         }
      }
   }
   
   var assistantEmptyView: some View {
      VStack {
         Spacer()
         EmptyAssistantPlaceholderView(
            imageURL: nil,
            title: "Create an assistant",
            subtitle: "You can also do this in the Configure tab.") {
               Image(systemName: "oval.bottomhalf.filled")
            }
         Spacer()
      }
   }
   
   var chatList: some View {
      List(chatProvider.chatDisplayMessages) { message in
         ChatMessageRow(message: message)
            .listRowSeparator(.hidden)
      }
      .listStyle(.plain)
   }
   
   var textArea: some View {
      ChatTextArea(
         selectedImageURLS: $selectedImageURLS,
         selectedImages: $selectedImages,
         prompt: $prompt,
         showAudioSpeech: $showAudioSpeech) {
            Task {
               isLoading = true
               defer { isLoading = false }
               // Clears text field.
               let userPrompt = prompt
               prompt = ""
               
               /// Create the Parameters
               
               let isVision = !selectedImageURLS.isEmpty
               
               chatCompletionParameters.model = isVision ? Model.gpt4VisionPreview.value : chatCompletionParameters.model
               chatCompletionParameters.toolChoice = isVision ? nil : chatCompletionParameters.toolChoice
               chatCompletionParameters.tools = isVision ? nil : chatCompletionParameters.tools
               chatCompletionParameters.maxTokens = isVision ? 300 : chatCompletionParameters.maxTokens
               
               // Create a system message AKA instruction.
               let systemMessage = ChatCompletionParameters.Message(role: .system, content: .text("You are an artist powered by AI, if the messages has a tool message you will weight that bigger in order to create a response, and you are providing me an image, you always respond in readable language and never providing URLs of images, most of the times you add an emoji on your responses if makes sense, do not describe the image."))
               
               chatCompletionParameters.messages = [systemMessage]
               
               // Create the initial users content
               let userContent = ChatMessageDisplayModel.DisplayContent.DisplayMessageType(text: userPrompt, urls: selectedImageURLS)
               
               resetImageInputs()
               /// TODO: I think we need to also clear the `selectedItems` in `PhotoPicker`
               
               try await chatProvider.chat(content: userContent, chatCompletionParameters)
            }
         }
   }

   /// Called when the user taps on the send button. Clears the selected images and prompt.
   private func resetImageInputs() {
      selectedImages = []
      selectedImageURLS = []
   }
   
   @State private var isLoading = false
   @Binding private var showAudioSpeech: Bool?
   @State private var prompt = ""
   @State private var chatProvider: ChatProvider
   @State private var selectedImageURLS: [URL] = []
   @State private var selectedImages: [Image] = []
   @State private var chatCompletionParameters = ChatCompletionParameters(
      messages: [],
      model: Model.gpt35Turbo1106,
      toolChoice: .auto,
      tools: FunctionCallDefinition.allCases.map { $0.functionTool })
   @State private var selectedModel: Model = .gpt35Turbo1106
   @Binding private var assistantParameters: AssistantParameters
}

