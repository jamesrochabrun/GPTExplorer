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
   
   // MARK: Initialization
   
   init(
      service: OpenAIService,
      assistantID: String?)
   {
      _provider = State(initialValue: AssistantsProvider(service: service))
      self.assistantID = assistantID
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
            self.parameters.metadata = [AssistantsProvider.avatarMetadataKey: avatarURL.absoluteString]
         }
      }.onFirstAppear {
         Task {
            try await setInitialParametersForExistingAssistant()
         }
      }
      .onChange(of: provider.assistantsParameters) { _, newValue in
         self.parameters = newValue!
      }
      .onChange(of: provider.errorMessage) { oldValue, newValue in
         providerDidFail = oldValue != newValue
      }
      .alert(provider.errorMessage ?? "", isPresented: $providerDidFail) {
      }
      .onChange(of: provider.deletionStatus?.deleted) { _, newValue in
         if newValue == true {
            self.presentationMode.wrappedValue.dismiss()
         }
      }
      .alert("Are you sure you want to delete this Assistant?", isPresented: $showDeleteAssistantAlert) {
         Button("Yes", role: .destructive) {
            Task {
               if let assistantID {
                  try await provider.deleteAssistant(id: assistantID)
               }
            }
         }
         Button("Nope", role: .cancel) {}
      }
   }
   
   private func setInitialParametersForExistingAssistant()
      async throws
   {
      guard 
         let assistantID,
         let parameters = try await provider.retrieveAssistantParameters(id: assistantID, model: nil)
      else { return }
      if
         let avatarURLString = parameters.metadata![AssistantsProvider.avatarMetadataKey],
         let avatarURL = URL(string: avatarURLString)
      {
         provider.avatarURL = avatarURL
      }
      self.parameters = parameters
   }
   
   var footerActions: some View {
      HStack {
         ActionButton("Delete") {
            showDeleteAssistantAlert = true
         }
         .disabled(assistantID == nil)
         ActionButton("Save") {
            Task {
               if let assistantID {
                  try await provider.modifyAssistant(id: assistantID, parameters: parameters)
               } else {
                  try await provider.createAssistant(parameters: parameters)
               }
               // If error message is not nil means that an alert is shown
               // which in that case we don't dismiss the screen
               if provider.errorMessage == nil {
                  self.presentationMode.wrappedValue.dismiss()
               }
            }
         }
         .disabled(parameters.name == nil || parameters.name?.isEmpty == true)
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
         Menu.init(content: {
            Button {
               Task {
                  isAvatarLoading = true
                  defer { isAvatarLoading = false }  // ensure isLoading is set to false when the
                  let prompt = parameters.name ?? "Some random image for an avatar" // TODO: improve prompt
                  try await provider.createAvatar(prompt: prompt)
               }
            }  label: {
               Text("Use DALL·E")
            }
         }, label: {
            Circle()
               .stroke(.gray, style: StrokeStyle(lineWidth: 1, dash: [5, 5]))
               .frame(width: 100, height: 100)
               .overlay(
                  Image(systemName: "plus")
                     .resizable()
                     .frame(width: 20, height: 20)
                     .tint(.gray)
               )
         })
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
   @State private var providerDidFail = false
   @Environment(\.presentationMode) private var presentationMode
   @State private var showDeleteAssistantAlert = false

   private let assistantID: String?

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
   AssistantConfigurationScreen(service: OpenAIServiceFactory.service(apiKey: ""), assistantID: nil)
}
