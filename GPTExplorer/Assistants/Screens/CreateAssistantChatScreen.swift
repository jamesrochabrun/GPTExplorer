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
   
   @State private var isLoading = false
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
   
   init(
      provider: ChatProvider,
      assistantParameters: Binding<AssistantParameters>)
   {
      _chatProvider = State(initialValue: provider)
      _assistantParameters = assistantParameters
   }
   
   var body: some View {
      NavigationView {
         mainContent
      }
   }
   
   private var mainContent: some View {
      ScrollViewReader { proxy in
         VStack {
            List(chatProvider.chatDisplayMessages) { message in
               ChatMessageRow(message: message)
                  .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
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
            ChatTextArea(
               selectedImageURLS: $selectedImageURLS,
               selectedImages: $selectedImages,
               prompt: $prompt) {
                  Task {
                     isLoading = true
                     defer { isLoading = false }
                     // Clears text field.
                     let userPrompt = prompt
                     prompt = ""
                     
                     /// Create the Parameters
                     
                     let isVision = !selectedImageURLS.isEmpty

                     chatCompletionParameters.model = isVision ? Model.gpt4VisionPreview.rawValue : chatCompletionParameters.model
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
      }
   }
   
   /// Called when the user taps on the send button. Clears the selected images and prompt.
    private func resetImageInputs() {
       selectedImages = []
       selectedImageURLS = []
    }
}

