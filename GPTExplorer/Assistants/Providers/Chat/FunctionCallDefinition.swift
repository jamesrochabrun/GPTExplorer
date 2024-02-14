//
//  FunctionCallDefinition.swift
//  GPTExplorer
//
//  Created by James Rochabrun on 2/13/24.
//

import Foundation
import SwiftOpenAI

/**
 This is a demo in how to implement parallel function calling when using the completion API stream = true
 */

struct FunctionCallStreamedResponse {
   let name: String
   let id: String
   let toolCall: ToolCall
   var argument: String
}

enum FunctionCallDefinition: String, CaseIterable {
   
   static var lastFunction: FunctionCallDefinition?

   case createImage = "create_image"
   case buildAssistant = "build_assistant"
   // Add more functions if needed, parallel function calling is supported.

   var functionTool: ChatCompletionParameters.Tool {
      switch self {
      case .createImage:
         return .init(function: .init(
            name: self.rawValue,
            description: "Call this function if the request asks to generate an image",
            parameters: .init(
               type: .object,
               properties: [
                  "prompt": .init(type: .string, description: "The exact prompt passed in."),
                  "count": .init(type: .integer, description: "The number of images requested")
               ],
               required: ["prompt", "count"])))
      case .buildAssistant:
         return .init(function: .init(
            name: self.rawValue,
            description: "Call this function if the request is associated to build an assistant to certain parameters, the values we need to extract are, name, description, instructions., enabling tools such code interpreter, retrieval or Dalle",
            parameters: .init(
               type: .object,
               properties: [
                  "name": .init(type: .string, description: "The name for the assistant."),
                  "description": .init(type: .string, description: "The assistant's description"),
                  "instructions": .init(type: .string, description: "The assistant's instructions"),
                  "code_interpreter": .init(type: .boolean, description: "A bool se to true if user requests code interpreter tool"),
                  "retrieval": .init(type: .boolean, description: "A bool se to true if user requests code retrieval tool"),
                  "dalle": .init(type: .boolean, description: "A bool se to true if user requests dalle image generator tool"),
                  "avatar_description": .init(type: .string, description: "The description of the image that was requested by the user.")
               ],
               required: ["name"])))
      }
   }
}
