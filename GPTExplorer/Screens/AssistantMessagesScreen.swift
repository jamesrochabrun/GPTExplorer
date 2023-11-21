//
//  AssistantMessagesScreen.swift
//  GPTExplorer
//
//  Created by James Rochabrun on 11/20/23.
//

import SwiftUI
import SwiftOpenAI

// MARK: AssistantMessagesScreen

struct AssistantMessagesScreen: View {
   
   let assistant: AssistantObject
   
   var body: some View {
      Text(assistant.name!)
   }
}

// MARK: Mock+Preview

//#Preview {
//   AssistantMessagesScreen(assistant: .)
//}
