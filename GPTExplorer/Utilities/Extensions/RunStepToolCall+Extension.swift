//
//  RunStepToolCall+Extension.swift
//  GPTExplorer
//
//  Created by James Rochabrun on 12/12/23.
//

import SwiftOpenAI

extension RunStepToolCall: Equatable {
    public static func == (lhs: RunStepToolCall, rhs: RunStepToolCall) -> Bool {
        switch (lhs, rhs) {
        case let (.codeInterpreterToolCall(lhsValue), .codeInterpreterToolCall(rhsValue)):
            return lhsValue == rhsValue
        case let (.fileSearchToolCall(lhsValue), .fileSearchToolCall(rhsValue)):
            return lhsValue == rhsValue
        case let (.functionToolCall(lhsValue), .functionToolCall(rhsValue)):
            return lhsValue == rhsValue
        default:
            return false
        }
    }
}

// MARK: CodeInterpreterToolCall+Equatable

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

// MARK: FileSearchToolCall+Equatable

extension FileSearchToolCall: Equatable {
   public static func == (lhs: FileSearchToolCall, rhs: FileSearchToolCall) -> Bool {
      lhs.fileSearch == rhs.fileSearch
   }
}

// MARK: FunctionToolCall+Equatable

extension FunctionToolCall: Equatable {
    public static func == (lhs: FunctionToolCall, rhs: FunctionToolCall) -> Bool {
        return lhs.name == rhs.name && lhs.arguments == rhs.arguments && lhs.output == rhs.output
    }
}

