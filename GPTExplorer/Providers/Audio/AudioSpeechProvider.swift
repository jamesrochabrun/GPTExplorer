//
//  AudioSpeechProvider.swift
//  GPTExplorer
//
//  Created by James Rochabrun on 12/6/23.
//

import AVFoundation
import SwiftOpenAI
import SwiftUI

@Observable final class AudioSpeechProvider: NSObject {
   
   private let service: OpenAIService
   private var audioPlayer: AVAudioPlayer!
   private var audioRecorder: AVAudioRecorder!
#if !os(macOS)
   var recordingSession = AVAudioSession.sharedInstance()
#endif
   var animationTimer: Timer?
   var recordingTimer: Timer?
   var amplitude = 0.0
   var prevAmplitude: Double?
   var processingSpeechTask: Task<Void, Never>?
   
   static let animationInterval = 0.15
   
   var capturedURL: URL {
      FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
         .first!.appendingPathComponent("recording.m4a")
   }
   
   init(service: OpenAIService) {
      self.service = service
      super.init()
#if !os(macOS)
      do {
#if os(iOS)
         try recordingSession.setCategory(.playAndRecord, options: .defaultToSpeaker)
#else
         try recordingSession.setCategory(.playAndRecord, options: .default)
#endif
         try recordingSession.setActive(true)
         AVAudioApplication.requestRecordPermission { [unowned self] allowed in
            if !allowed {
               self.state = .error(.permissionRequestError)
            }
         }
      } catch {
         self.state = .error(.configurationError)
      }
#endif
   }
   
   var state = VoiceChatState.initial {
      didSet { print(state) }
   }
      
   var isIdle: Bool {
      if case .idle = state {
         return true
      }
      return false
   }
   
   var assistantViewOpacity: CGFloat {
      switch state {
      case .recording, .idle, .playingSpeech: return 1
      default: return 0
      }
   }
      
   func startCaptureAudio() {
      reset()
      state = .recording
      do {
         audioRecorder = try AVAudioRecorder(url: capturedURL,
                                             settings: [
                                                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                                                AVSampleRateKey: 8000,//12000, // test 
                                                AVNumberOfChannelsKey: 1,
                                                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
                                             ])
         audioRecorder.isMeteringEnabled = true
         audioRecorder.delegate = self
         audioRecorder.record()

         animationTimer = Timer.scheduledTimer(withTimeInterval: Self.animationInterval, repeats: true) { [weak self] _ in
            guard let self else { return }
            guard self.audioRecorder != nil else { return }
            self.audioRecorder.updateMeters()
            let power = min(1, max(0, 1 - abs(Double(self.audioRecorder.averagePower(forChannel: 0)) / 50) ))
            self.amplitude = power
         }
         
         recordingTimer = Timer.scheduledTimer(withTimeInterval: 1.6, repeats: true) { [weak self]_ in
            guard let self else { return }
            guard self.audioRecorder != nil else { return }
            self.audioRecorder.updateMeters()
            let amplitude = min(1, max(0, 1 - abs(Double(self.audioRecorder.averagePower(forChannel: 0)) / 50) ))
            if self.prevAmplitude == nil {
               self.prevAmplitude = amplitude
               return
            }
            if let prevAmplitude = self.prevAmplitude, prevAmplitude < 0.25 && amplitude < 0.175 {
               self.finishCaptureAudio()
               return
            }
            self.prevAmplitude = amplitude
         }
         
      } catch {
         reset()
         state = .error(.startCaptureAudioError)
      }
   }
   
   func finishCaptureAudio() {
      reset()
      do {
         let data = try Data(contentsOf: capturedURL)
         processingSpeechTask = processSpeechTask(audioData: data)
      } catch {
         state = .error(.finishCaptureAudioError)
         reset()
      }
   }
   
   func processSpeechTask(audioData: Data) -> Task<Void, Never> {
      Task { @MainActor [unowned self] in
         do {
            self.state = .processingSpeech
            let prompt = try await service.createTranscription(parameters: .init(fileName: "recording.m4a", file: audioData)).text
            
            try Task.checkCancellation()
            let responseText = try await service.startChat(parameters: .init(messages: [.init(role: .user, content: .text(prompt))], model: .gpt41106Preview)).choices.first?.message.content ?? ""
            
            try Task.checkCancellation()
            let speech = try await service.createSpeech(parameters: .init(model: .tts1, input: responseText, voice: .alloy))
            
            try Task.checkCancellation()
            try self.playAudio(data: speech.output)
         } catch {
            if Task.isCancelled { return }
            state = .error(.processSpeechError)
            reset()
         }
      }
   }
   
   func playAudio(data: Data) throws {
      state = .playingSpeech
      audioPlayer = try AVAudioPlayer(data: data)
      audioPlayer?.isMeteringEnabled = true
      audioPlayer?.delegate = self
      audioPlayer?.play()
      
      animationTimer = Timer.scheduledTimer(withTimeInterval: Self.animationInterval, repeats: true) { [weak self] _ in
         guard let self = self else { return }
         guard let audioPlayer = self.audioPlayer else { return }
         audioPlayer.updateMeters()
         self.amplitude = min(1, max(0, 1 - abs(Double(audioPlayer.averagePower(forChannel: 0)) / 160)))
      }
   }
   
   func stopRecording() {
      reset()
      state = .pausedCancel
   }
   
   func cancelProcessingTask() {
      processingSpeechTask?.cancel()
      processingSpeechTask = nil
      reset()
      state = .idle
   }
   
   func reset() {
      amplitude = 0
      prevAmplitude = nil
      audioRecorder?.stop()
      audioRecorder = nil
      audioPlayer?.stop()
      audioPlayer = nil
      recordingTimer?.invalidate()
      recordingTimer = nil
      animationTimer?.invalidate()
      animationTimer = nil
   }

}

extension AudioSpeechProvider: AVAudioRecorderDelegate, AVAudioPlayerDelegate  {
   
   func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
      if !flag {
         reset()
         state = .idle
      }
   }
   
   func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
      reset()
      state = .idle
   }
}
