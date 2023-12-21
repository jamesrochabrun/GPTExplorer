//
//  AudioSpeechContainer.swift
//  GPTExplorer
//
//  Created by James Rochabrun on 12/20/23.
//

import SwiftUI
import SwiftOpenAI

struct AudioSpeechContainer<Content: View>: View {
   
   let mainContent: Content
   let service: OpenAIService
   let currentModel: Model
   @Binding var showAudioSpeech: Bool
   
   init(
      service: OpenAIService,
      currentModel: Model,
      showAudioSpeech: Binding<Bool>,
      @ViewBuilder content: () -> Content)
   {
      self.service = service
      self.currentModel = currentModel
      _showAudioSpeech = showAudioSpeech
      self.mainContent = content()
   }
   
   var body: some View {
      ZStack {
         mainContent
         if showAudioSpeech {
            AudioSpeechScreen(
               audioProvider: .init(
                  service: service,
                  responseModel: currentModel),
               showScreen: $showAudioSpeech
            )
         }
      }
      .animation(.easeInOut, value: showAudioSpeech)
      .sensoryFeedback(.impact, trigger: showAudioSpeech)
   }
}

#Preview("Show Audio Screen") {
   AudioSpeechContainer(
      service: OpenAIServiceFactory.mockService(),
      currentModel: .gpt35Turbo0613,
      showAudioSpeech: .constant(true)) {
         Text("Some Content")
      }
}

#Preview("Hide Audio Screen") {
   AudioSpeechContainer(
      service: OpenAIServiceFactory.mockService(),
      currentModel: .gpt35Turbo0613,
      showAudioSpeech: .constant(false)) {
         Text("Some Content")
      }
}
