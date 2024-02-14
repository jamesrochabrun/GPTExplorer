//
//  ChatScreen.swift
//  GPTExplorer
//
//  Created by James Rochabrun on 12/8/23.
//

import SwiftUI
import SwiftOpenAI

struct ChatScreen: View {
   
   init(service: OpenAIService) {
      self.service = service
      _chatProvider = State(initialValue: ChatProvider(service: service))
   }
   
   var body: some View {
      NavigationView {
         AudioSpeechContainer(
            service: service,
            currentModel: .custom(currentModel),
            showAudioSpeech: $showAudioSpeech.orFalse) {
               mainContent
            }
      }
      .sheet(isPresented: $showModelsPicker) {
         ModelsListScreen(service: service, selectedModel: $currentModel)
            .presentationDetents([.medium, .large, .fraction(0.75), .height(200)], selection: $modelsPickerDetent)
            .presentationContentInteraction(.scrolls)
      }
      .sheet(isPresented: $showParametersPicker) {
         ChatParametersEditScreen(parameters: $chatCompletionParameters)
            .presentationDetents([.medium, .large, .fraction(0.75), .height(200)], selection: $modelsPickerDetent)
            .presentationContentInteraction(.scrolls)
      }
   }
   
   var headerView: some View {
      HStack(spacing: 0) {
         IconButton(iconName: "list.bullet") {}
            .opacity(0)
            .accessibilityHidden(true)
         Spacer()
         ActionButton(currentModel, actionIcon: .init(systemName: "chevron.right")) {
            showModelsPicker = true
         }
         .frame(maxWidth: .infinity)
         .actionButtonStyle(.plainTrailing)
         Spacer()
         IconButton(iconName: "slider.vertical.3") {
            showParametersPicker = true
         }
         .iconButtonStyle(.plain)
      }
      .padding(.horizontal)
   }
   
   var inputView: some View {
      ChatTextArea(
         selectedImageURLS: $selectedImageURLS,
         selectedImages: $selectedImages,
         prompt: $prompt, 
         showAudioSpeech: $showAudioSpeech) {
            Task {
               /// Loading UI
               isLoading = true
               defer { isLoading = false }
               // Clears text field.
               let userPrompt = prompt
               prompt = ""
               
               /// Create the Parameters
               
               let isVision = !selectedImageURLS.isEmpty

               chatCompletionParameters.model = isVision ? Model.gpt4VisionPreview.value : currentModel
               chatCompletionParameters.toolChoice = isVision ? nil : chatCompletionParameters.toolChoice
               chatCompletionParameters.tools = isVision ? nil : chatCompletionParameters.tools
               chatCompletionParameters.maxTokens = isVision ? 300 : chatCompletionParameters.maxTokens
               
               // Create a system message AKA instruction.
               let systemMessage = ChatCompletionParameters.Message(role: .system, content: .text("You are an artist powered by AI, if the messages has a tool message you will weight that bigger in order to create a response, and you are providing me an image, you always respond in readable language and never providing URLs of images, most of the times you add an emoji on your responses if makes sense, do not describe the image."))
               
               chatCompletionParameters.messages = [systemMessage]
               
               // Create the initial users content
               let userContent = ChatMessageDisplayModel.DisplayContent.DisplayMessageType(text: userPrompt, urls: selectedImageURLS, isFinished: true)
                               
               resetImageInputs()
               /// TODO: I think we need to also clear the `selectedItems` in `PhotoPicker`

               try await chatProvider.chat(content: userContent, chatCompletionParameters)
            }
         }
   }
   
   private var mainContent: some View {
      ScrollViewReader { proxy in
         VStack {
            headerView
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
            inputView
         }
      }
   }
   
   /// Called when the user taps on the send button. Clears the selected images and prompt.
   private func resetImageInputs() {
      selectedImages = []
      selectedImageURLS = []
   }
   
   private let service: OpenAIService
   @State private var isLoading = false
   @State private var prompt = ""
   @State private var chatProvider: ChatProvider
   @State private var selectedImageURLS: [URL] = []
   @State private var selectedImages: [Image] = []
   @State private var chatCompletionParameters = ChatCompletionParameters(
      messages: [],
      model: Model.gpt35Turbo1106,
      toolChoice: .auto,
      tools: [FunctionCallDefinition.createImage.functionTool])
   @State private var selectedModel: Model = .gpt35Turbo1106
   @State private var showAudioSpeech: Bool? = false
   @State private var showModelsPicker = false
   @State private var showParametersPicker = false
   @State private var modelsPickerDetent = PresentationDetent.medium
   @State private var currentModel = Model.gpt41106Preview.value
}


#Preview {
   ChatScreen(service: OpenAIServiceFactory.service(apiKey: ""))
}


