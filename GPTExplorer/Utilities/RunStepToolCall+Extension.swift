//
//  RunStepToolCall+Extension.swift
//  GPTExplorer
//
//  Created by James Rochabrun on 12/12/23.
//

import SwiftOpenAI

extension RunStepToolCall {
   
   var codeInterpreter: CodeInterpreterToolCall? {
      switch self {
      case .codeInterpreterToolCall(let codeInterpreter): return codeInterpreter
      default: return nil
      }
   }
}
