//
//  AssistantParameters+Extension.swift
//  GPTExplorer
//
//  Created by James Rochabrun on 11/24/23.
//

import SwiftOpenAI

extension AssistantParameters: Equatable {
   
   public static func == (lhs: SwiftOpenAI.AssistantParameters, rhs: SwiftOpenAI.AssistantParameters) -> Bool {
      lhs.model == rhs.model &&
      lhs.name == rhs.name &&
      lhs.description == rhs.description &&
      lhs.instructions == rhs.instructions  &&
      lhs.fileIDS == rhs.fileIDS &&
      lhs.metadata == rhs.metadata
   }
}

extension AssistantObject {
   
   func assistantParameters(_ model: String?)
      -> AssistantParameters
   {
      .init(
         action: .modify(model: model),
         name: name,
         description: description,
         instructions: instructions,
         tools: tools,
         fileIDS: fileIDS,
         metadata: metadata)
   }
}
