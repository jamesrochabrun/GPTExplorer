//
//  ChatMessageDisplayModel.swift
//  GPTExplorer
//
//  Created by James Rochabrun on 11/21/23.
//

import Foundation
import SwiftOpenAI

struct ChatMessageDisplayModel: Identifiable {
   
   let id: String
   var content: DisplayContent
   let origin: MessageOrigin
   let runMetadata: RunMetadata?
   
   struct RunMetadata: Identifiable {
      
      let runID: String
      let threadID: String
      
      var isEmpty: Bool {
         runID.isEmpty || threadID.isEmpty
      }
      
      var id: String {
         runID + threadID
      }
   }

   enum DisplayContent: Equatable {

      case content(message: DisplayMessageType, toolCall: [RunStepToolCall]? = nil)
      case loading(LoadingSource)
      case error(String)

      static func ==(lhs: DisplayContent, rhs: DisplayContent) -> Bool {
         switch (lhs, rhs) {
         case let (.content(messageA, toolCallA), .content(messageB, toolCallB)):
            return messageA == messageB && toolCallA == toolCallB
         case let (.loading(a), .loading(b)):
            return a == b
         case let (.error(a), .error(b)):
            return a == b
         default:
            return false
         }
      }

      struct DisplayMessageType: Equatable {
         var text: String?
         var urls: [URL]? = nil
         var isFinished: Bool
      }
      
      enum LoadingSource: Equatable {
         case dalle
      }
   }

   init(
      id: String = UUID().uuidString,
      content: DisplayContent,
      origin: MessageOrigin,
      runMetadata: RunMetadata? = nil)
   {
      self.id = id
      self.content = content
      self.origin = origin
      self.runMetadata = runMetadata
   }

   enum MessageOrigin {

      case received(ReceivedSource)
      case sent

      enum ReceivedSource {
         case gpt
         case dalle
         case asssistant(Assistant)
         
         enum Assistant {
            case user
            case assistant(String)
         }
      }
   }
}
