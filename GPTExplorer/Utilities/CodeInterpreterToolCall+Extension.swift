//
//  CodeInterpreterToolCall+Extension.swift
//  GPTExplorer
//
//  Created by James Rochabrun on 12/12/23.
//

import SwiftOpenAI

extension CodeInterpreterToolCall: Equatable {
   public static func == (lhs: CodeInterpreterToolCall, rhs: CodeInterpreterToolCall) -> Bool {
      lhs.input == rhs.input
   }
}

extension CodeInterpreterOutput: Equatable {
   public static func ==(lhs: CodeInterpreterOutput, rhs: CodeInterpreterOutput) -> Bool {
       switch (lhs, rhs) {
       case let (.logs(a), .logs(b)):
          return a.logs == b.logs && a.type == b.type
       case let (.images(a), .images(b)):
          return a.type == b.type && a.image == b.image
       default:
           return false
       }
   }
}

extension CodeInterpreterImageOutput.Image: Equatable {
   public static func == (lhs: CodeInterpreterImageOutput.Image, rhs: CodeInterpreterImageOutput.Image) -> Bool {
      lhs.fileID == rhs.fileID
   }
}
