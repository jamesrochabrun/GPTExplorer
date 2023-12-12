//
//  AudioSpeechScreen.swift
//  GPTExplorer
//
//  Created by James Rochabrun on 12/6/23.
//

import Foundation
import SwiftUI
import SwiftOpenAI

struct AudioSpeechScreen: View {
   
   @State private var audioProvider: AudioSpeechProvider
   @State private var isSymbolAnimating = false
   @Binding var showScreen: Bool
   
   init(
      audioProvider: AudioSpeechProvider,
      showScreen: Binding<Bool>)
   {
      _audioProvider = State(initialValue: audioProvider)
      _showScreen = showScreen
   }
   
   var body: some View {
      VStack {
         Spacer()
         AudioWaveView()
            .power(power: audioProvider.amplitude)
            .opacity(audioProvider.assistantViewOpacity)
            .frame(height: 264)
            .overlay { overlayView }
            .transition(.opacity)
         Spacer()
         HStack {
            stopOrPauseRecordingButton
            Spacer()
            cancelAndDismissButton
            Spacer()
            /// just to center the `cancelAndDismissButton`
            stopOrPauseRecordingButton
               .accessibilityHidden(true)
               .hidden()
         }
         .transition(.opacity)
         .padding(.horizontal, 60)
         if case let .error(error) = audioProvider.state  {
            VStack {
               Text(error.rawValue)
                  .foregroundStyle(.red)
                  .font(.caption)
            }
            .padding()
            .transition(.opacity)
         }
         Text(audioProvider.state.displayDescription)
            .font(.footnote)
            .padding()
            .transition(.opacity)
         Spacer()
            .frame(height: 60)
      }
      .animation(.linear, value: audioProvider.state)
      .onChange(of: audioProvider.state) { oldValue, newValue in
         if oldValue != newValue, newValue == .idle {
            audioProvider.startCaptureAudio()
         }
      }
      .onFirstAppear {
         DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            audioProvider.state = .idle
            audioProvider.startCaptureAudio()
         }
      }
      .onChange(of: audioProvider.state) { oldValue, newValue in
         if oldValue != newValue {
            UISelectionFeedbackGenerator().selectionChanged()
         }
      }
      .onDisappear {
         audioProvider.cancelProcessingTask()
      }
      .background(Color(.systemBackground))
   }
   
   @ViewBuilder
   var overlayView: some View {
      switch audioProvider.state {
      case .initial:
         BouncingCircleView()
            .padding(.horizontal, 50)
            .transition(.opacity)
      case .idle, .error, .playingSpeech, .recording:
         // We trigger the audio on first appear, no need to show UI
         EmptyView()
      case .processingSpeech:
         CircleBouncingView(animationDuration: 0.5)
            .frame(width: 90, height: 90)
            .transition(.opacity)
      case .pausedCancel:
         CircleBouncingView(animationDuration: 1)
            .frame(width: 40, height: 40)
            .transition(.opacity)
      }
   }

   var stopOrPauseRecordingButton: some View {
      IconButton(iconName: audioProvider.state == .pausedCancel ? "play.circle" : "stop.circle") {
         switch audioProvider.state {
         case .recording, .idle, .error, .processingSpeech, .playingSpeech, .initial:
            audioProvider.stopRecording()
         case .pausedCancel:
            audioProvider.startCaptureAudio()
         }
      }
      .iconButtonStyle(.circleSecondary)
   }
   
   var cancelAndDismissButton: some View {
      IconButton(iconName: "xmark.circle") {
         audioProvider.cancelProcessingTask()
         showScreen = false
      }
      .iconButtonStyle(.circleMediumSecondary)
   }
}

#Preview("Idle") {
   let provider = AudioSpeechProvider(service: OpenAIServiceFactory.service(apiKey: ""))
   provider.state = .idle
   return AudioSpeechScreen(audioProvider: provider, showScreen: .constant(false))
}

#Preview("Initial") {
   let provider = AudioSpeechProvider(service: OpenAIServiceFactory.service(apiKey: ""))
   provider.state = .initial
   return AudioSpeechScreen(audioProvider: provider, showScreen: .constant(false))
}

#Preview("Recording") {
   let provider = AudioSpeechProvider(service: OpenAIServiceFactory.service(apiKey: ""))
   provider.state = .recording
   provider.amplitude = 0.2
   return AudioSpeechScreen(audioProvider: provider, showScreen: .constant(false))
}

#Preview("Paused Cancel") {
   let provider = AudioSpeechProvider(service: OpenAIServiceFactory.service(apiKey: ""))
   provider.state = .pausedCancel
   return AudioSpeechScreen(audioProvider: provider, showScreen: .constant(false))
}

#Preview("Processing  Speech") {
   let provider = AudioSpeechProvider(service: OpenAIServiceFactory.service(apiKey: ""))
   provider.state = .processingSpeech
   return AudioSpeechScreen(audioProvider: provider, showScreen: .constant(false))
}

#Preview("Playing  Speech") {
   let provider = AudioSpeechProvider(service: OpenAIServiceFactory.service(apiKey: ""))
   provider.state = .playingSpeech
   return AudioSpeechScreen(audioProvider: provider, showScreen: .constant(false))
}

#Preview("Error") {
   let provider = AudioSpeechProvider(service: OpenAIServiceFactory.service(apiKey: ""))
   provider.state = .error(.configurationError)
   return AudioSpeechScreen(audioProvider: provider, showScreen: .constant(false))
}
