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
         .padding(.horizontal, 60)
         if case let .error(error) = audioProvider.state  {
            VStack {
               Text(error.rawValue)
                  .foregroundStyle(.red)
                  .font(.caption)
            }
            .padding()
         }
         Text(audioProvider.state.displayDescription)
            .font(.footnote)
            .padding()
         Spacer()
            .frame(height: 60)
      }
      .onChange(of: audioProvider.state) { oldValue, newValue in
         if oldValue != newValue, newValue == .idle {
            audioProvider.startCaptureAudio()
         }
      }
      .onFirstAppear {
         audioProvider.startCaptureAudio()
      }
      .onDisappear {
         audioProvider.reset()
      }
      .background(Color(.systemBackground))
   }
   
   @ViewBuilder
   var overlayView: some View {
      switch audioProvider.state {
      case .idle, .error:
         // We trigger the audio on first appear
         EmptyView()
      case .processingSpeech:
         CircleBouncingView(animationDuration: 0.5)
            .frame(width: 90, height: 90)
      case .pausedCancel:
         CircleBouncingView(animationDuration: 1)
            .frame(width: 20, height: 20)
//
      default:
         EmptyView()
      }
   }

   var stopOrPauseRecordingButton: some View {
      IconButton(iconName: audioProvider.state == .pausedCancel ? "play.circle" : "stop.circle") {
         switch audioProvider.state {
         case .recording, .idle, .error, .processingSpeech, .playingSpeech:
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


struct CircleBouncingView: View {
   
   var animationDuration: Double
   @State private var isScaledUp = false
   
   var body: some View {
      Circle()
         .scaleEffect(isScaledUp ? 1.5 : 1) // 1.5 is 150% size, 1 is 100% size
         .onAppear {
            withAnimation(Animation.easeInOut(duration: animationDuration).repeatForever(autoreverses: true)) {
               isScaledUp.toggle()
            }
         }
   }
}

struct EDD: View {
    var body: some View {
        HStack {
           IconButton(iconName:  "play.circle") {
           }
           .iconButtonStyle(.circleSecondary)


            Spacer()

           IconButton(iconName: "xmark.circle") {
          
           }
           .iconButtonStyle(.circleMediumSecondary)

            Spacer()
           
           IconButton(iconName:  "play.circle") {
           }
           .iconButtonStyle(.circleSecondary)
           .hidden()
      
          // .frame(width: 0)


        }
        .frame(maxWidth: .infinity)
    }
}

#Preview(body: {
   EDD()
})
