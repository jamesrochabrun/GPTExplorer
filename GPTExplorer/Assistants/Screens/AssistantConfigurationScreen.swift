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
      provider: SideMenuConfigurationProvider,
      service: OpenAIService)
   {
      _navigationProvider = State(initialValue: provider.navigationProvider)
      _provider = State(initialValue: provider)
      _currentAssistant = currentAssistant
      self.assistantID = assistantID
      chatProvider = ChatProvider(service: service)
      self.service = service
   }
   
   enum Configuration: String, CaseIterable {
      case create = "Create"
      case configure = "Configure"
   }
   
   var configuration: some View {
      ScrollView {
         VStack(spacing: Sizes.spacingExtraLarge) {
            titleHeader
            modelsPicker
            avatarView
            inputViews
            knowledge
            capabilities
         }
         .animation(.easeInOut, value: fileIDS)
         .padding()
         .padding(.horizontal, Sizes.spacingLarge)
      }
      .background(colorScheme == .dark ? Color.black : Color.white)
      .safeAreaInset(edge: .bottom) {
         footerActions
      }
   }
   
   var create: some View {
      CreateAssistantChatScreen(
         service: service,
         provider: chatProvider,
         assistantParameters: $parameters,
         showAudioSpeech: $showAudioSpeech)
   }
   
   var mainContent: some View {
      VStack {
         Picker("", selection: $selectedSegment) {
            Text(Configuration.create.rawValue).tag(Configuration.create)
            Text(Configuration.configure.rawValue).tag(Configuration.configure)
         }
         .padding()
         .pickerStyle(SegmentedPickerStyle())
         ZStack {
            switch selectedSegment {
            case .create:
               create
            case .configure:
               configuration
            }
         }
         .animation(.easeInOut, value: selectedSegment)
      }
   }
   
   var body: some View {
      ZStack {
         mainContent
         if showAudioSpeech == true {
            // TODO: Avoid force unwrap!
            AudioSpeechScreen(
               audioProvider: .init(service: provider.service, responseModel: .custom(parameters.model!)),
               showScreen: $showAudioSpeech.orFalse)
               .transition(.opacity) // Fade transition
         }
      }
      .animation(.linear, value: showAudioSpeech) // Smooth fade animation
      .sensoryFeedback(.impact, trigger: showAudioSpeech)
      .onChange(of: fileIDS) { oldValue, newValue in
         if oldValue != newValue {
            parameters.fileIDS = newValue
         }
      }
      .onChange(of: avatarURL) { oldValue, newValue in
         if let newValue = newValue, oldValue != newValue {
            parameters.avatarURL = newValue.absoluteString
         }
      }
      .onChange(of: parameters) { oldValue, newValue in
         if oldValue != newValue,
            let avatarURL = newValue.avatarURL {
            self.avatarURL = URL(string: avatarURL)
         }
      }
      .onFirstAppear {
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
            ActionButton("Cancel", actionIcon: nil, isLoading: .constant(false)) {}
            ActionButton("Retry", actionIcon: nil, isLoading: .constant(false)) {
               Task {
                  try await setAvatarURL(prompt: prompt)
               }
            }
         case .assistantUpdatedError(let id, message: _):
            ActionButton("Cancel", actionIcon: nil, isLoading: .constant(false)) {}
            ActionButton("Retry", actionIcon: nil, isLoading: .constant(false)) {
               Task {
                  try await modifyAssistantWith(id: id)
               }
            }
         case .assistantCreatedSuccess, .assistantUpdatedSuccess, .assistantDeletedSuccess:
            Button("Ok", role: .cancel) {
               dismissScreen()
            }
         case .asssitantRetrievedError(let id,  _):
            ActionButton("Cancel", actionIcon: nil, isLoading: .constant(false)) {
            }
            ActionButton("Retry", actionIcon: nil, isLoading: .constant(false)) {
               Task {
                  try await setInitialParametersForAssistantWith(id: id)
               }
            }
         case .assistantDeletedError(let id, _):
            ActionButton("Cancel", actionIcon: nil, isLoading: .constant(false)) {}
            ActionButton("Retry", actionIcon: nil, isLoading: .constant(false)) {
               Task {
                  try await deleteAssistantWith(id: id)
               }
            }
         default:
            EmptyView()
         }
      }
      .sheet(isPresented: $showModelsPicker) {
         ModelsListView(service: service, selectedModel: $parameters.model.orEmpty)
            .presentationDetents([.medium, .large, .fraction(0.75), .height(200)], selection: $modelsPickerDetent)
            .presentationContentInteraction(.scrolls)
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
      
      if let parameters = assistantResponse.item?.assistantParameters() {
         self.parameters = parameters
         if let fileIDS = parameters.fileIDS {
            filePickerInitialActions = fileIDS.map { .retrieveAndDisplay(id: $0) }
            self.fileIDS = fileIDS
         }
      }
      if
         let avatarURLString = parameters.avatarURL,
         let avatarURL = URL(string: avatarURLString)
      {
         self.avatarURL = avatarURL
      }
      currentProviderState = assistantResponse.state
   }
   
   var footerActions: some View {
      HStack {
         ActionButton("Delete", isLoading: $isLoadingDeleteAction) {
            showDeleteAssistantAlert = true
         }
         .disabled(currentAssistant == nil)
         ActionButton("Save", isLoading: $isLoadingSaveAction) {
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
         Menu {
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
         } label: {
            URLImageView(url: avatarURL)
         }
      } else {
         Menu {
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
         } label: {
            Circle()
               .stroke(.gray, style: StrokeStyle(lineWidth: 1, dash: [5, 5]))
               .frame(width: 100, height: 100)
               .overlay(
                  Image(systemName: "plus")
                     .resizable()
                     .frame(width: 20, height: 20)
                     .tint(.gray)
               )
         }
      }
   }
   
   private func setAvatarURL(prompt: String) async throws {
      let avatarURLResponse = try await provider.createAvatar(prompt: prompt)
      self.avatarURL = avatarURLResponse.item
      self.currentProviderState = avatarURLResponse.state
   }
   
   private func createAssistant() async throws {
      isLoadingSaveAction = true
      defer { isLoadingSaveAction = false }
      let assistantResponse = try await provider.createAssistant(parameters: parameters)
      currentAssistant = assistantResponse.item
      currentProviderState = assistantResponse.state
   }
   
   private func modifyAssistantWith(
      id: String)
      async throws
   {
      isLoadingSaveAction = true
      defer { isLoadingSaveAction = false }
      let updatedAssistantResponse = try await provider.modifyAssistant(id: id, parameters: parameters)
      currentAssistant = updatedAssistantResponse.item ?? currentAssistant
      currentProviderState = updatedAssistantResponse.state
   }
   
   private func deleteAssistantWith(id: String) async throws {
      isLoadingDeleteAction = true
      defer { isLoadingDeleteAction = false }
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
            CustomTextField(text: $parameters.name.orEmpty, placeholder: "")
         }
         InputHeaderView(title: "Description") {
            CustomTextField(text: $parameters.description.orEmpty, placeholder: "")
         }
         InputHeaderView(title: "Instructions") {
            ZStack {
               RoundedRectangle(cornerRadius: 4)
                  .stroke(.gray)
               TextEditor(text: $parameters.instructions.orEmpty)
                  .foregroundStyle(.primary)
                  .clipShape(RoundedRectangle(cornerRadius: 4))
                  .frame(minHeight: 100)
            }
         }
      }
   }
   
   @State private var presentImporter = false
   
   var knowledge: some View {
      FilesPicker(
         service: provider.service,
         sectionTitle: "Knowledge",
         actionTitle: "Upload files",
         fileIDS: $fileIDS,
         actions: $filePickerInitialActions)
   }
   
   var capabilities: some View {
      InputHeaderView(title: "Capabilities") {
         VStack(spacing: Sizes.spacingExtraLarge) {
            CheckboxRow(title: "Code interpreter", isChecked: isCodeInterpreterOn)
            CheckboxRow(title: "Retrieval", isChecked: isRetrievalOn)
            CheckboxRow(title: "DALL·E Image Generation", isChecked: isDalleToolOn)
         }
      }
      .inputViewStyle(.init(verticalPadding: Sizes.spacingExtraLarge))
   }
   
   var modelsPicker: some View {
      ActionButton(parameters.model ?? "Select Model", actionIcon: .init(systemName: "chevron.right")) {
         showModelsPicker = true
      }
      .actionButtonStyle(.plainTrailing)
   }
      
   // MARK: Private
   
   private let service: OpenAIService
   private let assistantID: String?
   private let chatProvider: ChatProvider
   @Binding private var currentAssistant: AssistantObject?
   @State private var provider: SideMenuConfigurationProvider
   @State private var parameters: AssistantParameters = AssistantParameters(action: .create(model: Model.gpt41106Preview.value))
   @State private var isAvatarLoading = false
   @Environment(\.presentationMode) private var presentationMode
   @State private var showDeleteAssistantAlert = false
   @State private var currentProviderState: ProviderState?
   @State private var avatarURL: URL?
   @State private var isLoadingSaveAction: Bool? = false
   @State private var isLoadingDeleteAction: Bool? = false
   @State private var navigationProvider: NavigationProvider
   @State private var selectedSegment: Configuration = .create
   @State private var showAudioSpeech: Bool? = false
   @State private var showModelsPicker = false
   @State private var modelsPickerDetent = PresentationDetent.medium

   @Environment (\.colorScheme) var colorScheme
                   
   /// Files management
   ///  Updated by files picker. This value will be later added to parameters.fileID's on save button.
   @State private var fileIDS: [String] = []
   /// Used mostly to display already uploaded files if any.
   @State private var filePickerInitialActions: [FilePickerAction] = []

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
   
   private var isRetrievalOn: Binding<Bool> {
      Binding(
         get: {
            let contains =
            self.parameters.tools.contains { $0.displayToolType == .retrieval } == true
            return contains
         },
         set: { newValue in
            if newValue {
               self.parameters.tools.append(AssistantObject.Tool(type: .retrieval))
            } else {
               self.parameters.tools.removeAll { $0.displayToolType == .retrieval }
            }
         }
      )
   }
}

extension String {
    var fileName: String {
        return (self as NSString).lastPathComponent
    }
}

#Preview {
   let service = OpenAIServiceFactory.service(apiKey: "")
   return AssistantConfigurationScreen(
      currentAssistant: .constant(nil),
      assistantID: nil,
      provider: SideMenuConfigurationProvider(service: service), service: service)
}


/**
 var body: some View {
    NavigationView {
       ZStack {
          mainContent
          if showAudioSpeech == true {
             AudioSpeechScreen(audioProvider: .init(service: service), showScreen: $showAudioSpeech.orFalse)
                .transition(.opacity) // Fade transition
          }
       }
       .animation(.linear, value: showAudioSpeech) // Smooth fade animation
       .sensoryFeedback(.impact, trigger: showAudioSpeech)
 
    }
 }
 
 */
