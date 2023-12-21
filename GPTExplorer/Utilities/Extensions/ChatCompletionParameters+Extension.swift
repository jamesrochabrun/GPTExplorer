//
//  ChatCompletionParameters+Extension.swift
//  GPTExplorer
//
//  Created by James Rochabrun on 12/20/23.
//

import SwiftOpenAI

extension ChatCompletionParameters.ResponseFormat: Hashable, Equatable {
   public static func == (lhs: ChatCompletionParameters.ResponseFormat, rhs: ChatCompletionParameters.ResponseFormat) -> Bool {
      lhs.type == rhs.type
   }
   
   public func hash(into hasher: inout Hasher) {
      hasher.combine(type)
   }
}
