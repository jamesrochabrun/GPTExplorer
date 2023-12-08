//
//  AudioModels.swift
//  GPTExplorer
//
//  Created by James Rochabrun on 12/6/23.
//

import Foundation
import SwiftOpenAI

enum Voice: String, CaseIterable {
   
   case alloy
   case echo
   case fable
   case onyx
   case nova
   case shimmer
}

enum VoiceChatState: Equatable {
   case idle
//   case recordingSpeech // nope
   case processingSpeech // nope
   case playingSpeech // nope?
   case recording
   case pausedCancel
   case error(AudioError)
   
   var displayDescription: String {
      switch self {
      case .idle:
         return "idle"
//      case .recordingSpeech:
//         return "Recording speech"
      case .processingSpeech:
         return "Processing speech"
      case .playingSpeech:
         return "Playing speech"
      case .error(let audioError):
         return audioError.rawValue
      case .recording:
         return "Recording"
      case .pausedCancel:
         return "Paused"
      }
   }
}

enum AudioError: String, Error {
   case permissionRequestError = "Microphon Permission Request Error"
   case configurationError = "Configuration Error"
   case startCaptureAudioError = "Start Capturing Audio Error"
   case finishCaptureAudioError = "Finish Capturing Audio Error"
   case processSpeechError = "Process Speech Error"
   
}
