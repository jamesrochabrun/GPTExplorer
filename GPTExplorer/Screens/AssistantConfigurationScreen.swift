//
//  AssistantsConfigurationScreen.swift
//  GPTExplorer
//
//  Created by James Rochabrun on 11/20/23.
//

import Foundation
import SwiftUI
import SwiftOpenAI

// MARK: AssistantFunctionCallDefinition

enum AssistantFunctionCallDefinition: String, CaseIterable {
   
   case createImage = "create_image"

   var functionTool: AssistantObject.Tool {
      switch self {
      case .createImage:
         return .init(type: .function, function: .init(
            name: self.rawValue,
            description: "call this function if the request asks to generate an image",
            parameters: .init(
               type: .object,
               properties: [
                  "prompt": .init(type: .string, description: "The exact prompt passed in."),
                  "count": .init(type: .integer, description: "The number of images requested")
               ],
               required: ["prompt", "count"])))
      }
   }
}

// MARK: AssistantsConfigurationScreen

struct AssistantConfigurationScreen: View {
   
   init(service: OpenAIService) {
      _provider = State(initialValue: AssistantsProvider(service: service))
   }
   
   var body: some View {
      ScrollView {
         VStack(spacing: Sizes.spacingExtraLarge) {
               titleHeader
               avatarView
               inputViews
               capabilities
         }
         .padding()
      }
      .safeAreaInset(edge: .bottom) {
         footerActions
      }
      .onChange(of: provider.avatarURL) { _, avatarURL in
         if let avatarURL {
            self.parameters.metadata = [SideMenuConfigurationProvider.avatarMetadataKey: avatarURL.absoluteString]
         }
      }
   }
   
   var footerActions: some View {
      HStack {
         ActionButton("Delete") {
            // TODO...
//            Task {
//               for assistant in provider.assistants {
//                  try await provider.deleteAssistant(id: assistant.id)
//               }
//            }
         }
         ActionButton("Save") {
            Task {
               try await provider.createAssistant(parameters: parameters)
            }
         }
      }
   }
   
   var titleHeader: some View {
      Text("Configure Assistant")
         .frame(maxWidth: .infinity, alignment: .leading)
         .font(.title2)
         .padding()
   }
   
   @ViewBuilder
   var avatarView: some View {
      if isAvatarLoading {
         Circle()
            .stroke(.gray, style: StrokeStyle(lineWidth: 1, dash: [5, 5]))
            .frame(width: 100, height: 100)
            .overlay(
               Image(systemName: "rays")
                  .resizable()
                  .frame(width: 20, height: 20)
                  .tint(.gray)
                  .symbolEffect(.variableColor.iterative.dimInactiveLayers)
            )
      }
      else if let avatarURL = provider.avatarURL {
         URLImageView(url: avatarURL)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.white, lineWidth: 1))
            .shadow(radius: 10)
      } else {
         Circle()
            .stroke(.gray, style: StrokeStyle(lineWidth: 1, dash: [5, 5]))
            .frame(width: 100, height: 100)
            .overlay(
               Menu.init(content: {
                  Button {
                     Task {
                        isAvatarLoading = true
                        defer { isAvatarLoading = false }  // ensure isLoading is set to false when the
                        let prompt = parameters.description ?? "Some random image for an avatar"
                        try await provider.createAvatar(prompt: prompt)
                     }
                  }  label: {
                     Text("Use DALL·E")
                  }
               }, label: {
                  Image(systemName: "plus")
                     .resizable()
                     .frame(width: 20, height: 20)
                     .tint(.gray)
               })
            )
      }
   }
   
   var inputViews: some View {
      VStack(spacing: Sizes.spacingExtraLarge) {
         InputHeaderView(title: "Name") {
            TextField("", text: $parameters.name.orEmpty, axis: .vertical)
         }
         InputHeaderView(title: "Description") {
            TextField("", text: $parameters.description.orEmpty, axis: .vertical)
         }
         InputHeaderView(title: "Instructions") {
            ZStack {
               RoundedRectangle(cornerRadius: 4)
                  .stroke(.gray.opacity(0.3))
               TextEditor(text: $parameters.instructions.orEmpty)
                  .foregroundStyle(.primary)
                  .clipShape(RoundedRectangle(cornerRadius: 4))
                  .frame(minHeight: 100)
            }
         }
      }
      .textFieldStyle(.roundedBorder)
   }
   
   var capabilities: some View {
      InputHeaderView(title: "Capabilities") {
         VStack(spacing: Sizes.spacingExtraLarge) {
            CheckboxRow(title: "Code interpreter", isChecked: isCodeInterpreterOn)
            CheckboxRow(title: "DALL·E Image Generation", isChecked: isDalleToolOn)

         }
      }
      .inputViewStyle(.init(verticalPadding: Sizes.spacingExtraLarge))
   }
   
   // MARK: Private
   
   @State private var provider: AssistantsProvider
   @State private var parameters: AssistantParameters = AssistantParameters(action: .create(model: Model.gpt41106Preview.rawValue))
   @State private var isAvatarLoading = false

   private var isCodeInterpreterOn: Binding<Bool> {
       Binding(
           get: {
              let contains =
               self.parameters.tools.contains { $0.displayToolType == .codeInterpreter } == true
              return contains
           },
           set: { newValue in
               if newValue {
                  self.parameters.tools.append(AssistantObject.Tool(type: .codeInterpreter))
               } else {
                  self.parameters.tools.removeAll { $0.displayToolType == .codeInterpreter }
               }
           }
       )
   }
   
   private var isDalleToolOn: Binding<Bool> {
       Binding(
           get: {
              let contains =
              self.parameters.tools.contains { $0.displayToolType == .function } == true
              return contains
           },
           set: { newValue in
               if newValue {
                  self.parameters.tools.append(AssistantFunctionCallDefinition.createImage.functionTool)
               } else {
                  self.parameters.tools.removeAll { $0.displayToolType == .function }
               }
           }
       )
   }
}

extension Binding where Value == String? {
    var orEmpty: Binding<String> {
        return Binding<String>(
            get: { self.wrappedValue ?? "" },
            set: { self.wrappedValue = $0 }
        )
    }
}

#Preview {
   AssistantConfigurationScreen(service: OpenAIServiceFactory.service(apiKey: ""))
}
