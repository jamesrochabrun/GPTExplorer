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
      currentAssistant: Binding<AssistantObject?>,
      assistantID: String?,
      provider: SideMenuConfigurationProvider)
   {
      _provider = State(initialValue: provider)
      _currentAssistant = currentAssistant
      self.assistantID = assistantID
   }
   
   @Binding var currentAssistant: AssistantObject?
   let assistantID: String?

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
      .onChange(of: avatarURL) { oldValue, newValue in
         if let newValue = newValue, oldValue != newValue {
            self.parameters.metadata = [AssistantMetadataKeys.avatarMetadataKey: newValue.absoluteString]
         }
      }.onFirstAppear {
         Task {
            if let currentAssistant {
               try await setInitialParametersForAssistantWith(id: currentAssistant.id)
            } else {
               if let assistantID {
                  try await setInitialParametersForAssistantWith(id: assistantID)
               }
            }
         }
      }
      .alert(currentProviderState?.message ?? "", isPresented: Binding<Bool>(
         get: { currentProviderState != nil },
         set: {
            if !$0 {
               currentProviderState = nil
            }
         }
      )) {
         switch currentProviderState {
         case .assistantAvatarCreatedError(let prompt, _):
            Button("Retry", role: .cancel) {
               Task {
                  try await setAvatarURL(prompt: prompt)
               }
            }
         case .assistantUpdatedError(let id, message: _):
            Button("Retry", role: .cancel) {
               Task {
                  try await modifyAssistantWith(id: id)
               }
            }
         case .assistantCreatedSuccess, .assistantUpdatedSuccess(_, message: _):
            Button("Ok", role: .cancel) {
               dismissScreen()
            }
         case .asssitantRetrievedError(let id,  _):
            Button("Retry", role: .cancel) {
               Task {
                  try await setInitialParametersForAssistantWith(id: id)
               }
            }
         case .assistantDeletedError(let id, _):
            Button("Retry", role: .cancel) {
               Task {
                  try await deleteAssistantWith(id: id)
               }
            }
         default:
            EmptyView()
         }
      }
      .alert("Are you sure you want to delete this Assistant?", isPresented: $showDeleteAssistantAlert) {
         Button("Yes", role: .destructive) {
            Task {
               if let assistantID = currentAssistant?.id {
                  try await deleteAssistantWith(id: assistantID)
               }
            }
         }
         Button("Nope", role: .cancel) {}
      }
   }
   private func setInitialParametersForAssistantWith(id: String)
      async throws
   {
      let assistantResponse = try await provider.retrieveAssistant(id: id)
      currentAssistant = assistantResponse.item
      if
         let parameters = assistantResponse.item?.assistantParameters(currentModel.rawValue),
         let avatarURLString = parameters.metadata![AssistantMetadataKeys.avatarMetadataKey],
         let avatarURL = URL(string: avatarURLString)
      {
         self.avatarURL = avatarURL
         self.parameters = parameters
      }
      currentProviderState = assistantResponse.state
   }
   
   var footerActions: some View {
      HStack {
         ActionButton("Delete") {
            showDeleteAssistantAlert = true
         }
         .disabled(currentAssistant == nil)
         ActionButton("Save") {
            Task {
               if let assistantID = currentAssistant?.id {
                 try await modifyAssistantWith(id: assistantID)
               } else {
                  try await createAssistant()
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
      else if let avatarURL = avatarURL {
         Menu.init(content: {
            Button {
               Task {
                  isAvatarLoading = true
                  defer { isAvatarLoading = false }  // ensure isLoading is set to false when the
                  let prompt = parameters.name ?? "Some random image for an avatar" // TODO: improve prompt
                  try await setAvatarURL(prompt: prompt)
               }
            }  label: {
               Text("Use DALL·E")
            }
         }, label: {
            URLImageView(url: avatarURL)
         })
      } else {
         Menu.init(content: {
            Button {
               Task {
                  isAvatarLoading = true
                  defer { isAvatarLoading = false }  // ensure isLoading is set to false when the
                  let prompt = parameters.name ?? "Some random image for an avatar" // TODO: improve prompt
                  try await setAvatarURL(prompt: prompt)
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
   
   private func setAvatarURL(prompt: String) async throws {
      let avatarURLResponse = try await provider.createAvatar(prompt: prompt)
      self.avatarURL = avatarURLResponse.item
      self.currentProviderState = avatarURLResponse.state
   }
   
   private func createAssistant() async throws {
      let assistantResponse = try await provider.createAssistant(parameters: parameters)
      currentAssistant = assistantResponse.item
      currentProviderState = assistantResponse.state
   }
   
   private func modifyAssistantWith(id: String) async throws  {
      let updatedAssistantResponse = try await provider.modifyAssistant(id: id, parameters: parameters)
      currentAssistant = updatedAssistantResponse.item
      currentProviderState = updatedAssistantResponse.state
   }
   
   private func deleteAssistantWith(id: String) async throws {
      let deletionResponse = try await provider.deleteAssistant(id: id)
      if deletionResponse.item?.deleted == true {
         currentAssistant = nil
      }
      currentProviderState = deletionResponse.state
   }
   
   private func dismissScreen() {
      presentationMode.wrappedValue.dismiss()
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
   
   @State private var provider: SideMenuConfigurationProvider
   @State private var parameters: AssistantParameters = AssistantParameters(action: .create(model: Model.gpt41106Preview.rawValue))
   @State private var currentModel = Model.gpt41106Preview
   @State private var isAvatarLoading = false
   @State private var providerDidFail = false
   @State private var currentSuccessMessage: String? = nil
   @Environment(\.presentationMode) private var presentationMode
   @State private var showDeleteAssistantAlert = false
   @State private var currentProviderState: ProviderState?
   @State private var avatarURL: URL?

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
//
//#Preview {
//   AssistantConfigurationScreen(provider: SideMenuConfigurationProvider(service: OpenAIServiceFactory.service(apiKey: "")), assistantID: nil)
//}
