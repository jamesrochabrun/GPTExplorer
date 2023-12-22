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
        case let (.retrieveToolCall(lhsValue), .retrieveToolCall(rhsValue)):
            return lhsValue == rhsValue
        case let (.functionToolCall(lhsValue), .functionToolCall(rhsValue)):
            return lhsValue == rhsValue
        default:
            return false
        }
    }
}

extension RetrievalToolCall: Equatable {
    public static func == (lhs: RetrievalToolCall, rhs: RetrievalToolCall) -> Bool {
        return lhs.retrieval == rhs.retrieval
    }
}

extension FunctionToolCall: Equatable {
    public static func == (lhs: FunctionToolCall, rhs: FunctionToolCall) -> Bool {
        return lhs.name == rhs.name && lhs.arguments == rhs.arguments && lhs.output == rhs.output
    }
}

