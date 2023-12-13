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

      case content(DisplayMessageType)
      case codeInterpreter(CodeInterpreterToolCall)
      case error(String)

      static func ==(lhs: DisplayContent, rhs: DisplayContent) -> Bool {
         switch (lhs, rhs) {
         case let (.content(a), .content(b)):
             return a == b
         case let (.codeInterpreter(a), .codeInterpreter(b)):
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
            case codeInterpreter
         }
      }
   }
}
