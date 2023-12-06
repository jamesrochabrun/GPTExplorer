//
//  AssistantParameters+Extension.swift
//  GPTExplorer
//
//  Created by James Rochabrun on 11/24/23.
//

import SwiftOpenAI

extension AssistantObject: Equatable {
   public static func == (lhs: AssistantObject, rhs: AssistantObject) -> Bool {
      lhs.id == rhs.id &&
      lhs.name == rhs.name &&
      lhs.object == rhs.object &&
      lhs.description == rhs.description &&
      lhs.model ==  rhs.model &&
      lhs.instructions == rhs.instructions &&
      lhs.tools == rhs.tools &&
      lhs.fileIDS == rhs.fileIDS &&
      lhs.metadata == rhs.metadata
   }
}

extension AssistantObject.Tool: Equatable {
   public static func == (lhs: AssistantObject.Tool, rhs: AssistantObject.Tool) -> Bool {
      lhs.displayToolType == rhs.displayToolType
   }
}

extension AssistantParameters: Equatable {
   
   public static func == (lhs: SwiftOpenAI.AssistantParameters, rhs: SwiftOpenAI.AssistantParameters) -> Bool {
      lhs.model == rhs.model &&
      lhs.name == rhs.name &&
      lhs.description == rhs.description &&
      lhs.instructions == rhs.instructions  &&
      lhs.fileIDS == rhs.fileIDS &&
      lhs.metadata == rhs.metadata &&
      lhs.tools == rhs.tools
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
