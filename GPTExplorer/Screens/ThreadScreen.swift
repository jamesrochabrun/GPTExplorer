//
//  ThreadScreen.swift
//  GPTExplorer
//
//  Created by James Rochabrun on 11/20/23.
//

import SwiftUI
import SwiftOpenAI

// MARK: ThreadScreen

struct ThreadScreen: View {
      
   // MARK: Initialization
      
   init(
      service: OpenAIService,
      provider: SideMenuConfigurationProvider,
      item: Binding<SideMenuItem>)
   {
      self.service = service
      _provider =  State(initialValue: provider)
      _navigationProvider = State(initialValue: provider.navigationProvider)
      _messagesProvider = State(initialValue: MessagesProvider(service: service))
      _runsProvider = State(initialValue: RunsProvider(service: service))
      self._item = item
      switch item.wrappedValue {
      case .assistant(let assistantObject):
         _currentAssistant = State(initialValue: assistantObject)
      case .thread(let thread):
         _currentThread = State(initialValue: thread)
      default:
         fatalError("This is programming error")
      }
   }
   
   var threadContent: some View {
      NavigationView {
         mainContent
      }
      .onFirstAppear {
         Task {
            // We need to request the current assistatnt associated to this thread at the moment we display this
            // screen for the first time.
            if let assistantID = currentThread?.assistantID {
               currentAssistant = try await provider.retrieveAssistant(id: assistantID).item
            }
         }
      }
      .safeAreaInset(edge: .bottom) {
         bottomTextArea
            .padding(.bottom, 34)
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
         case .threadDeletedSuccess(_, _):
            Button("Ok", role: .cancel) {
               dismissScreen()
            }
         case .threadDeletedError(let id, _):
            ActionButton("Cancel", actionIcon: nil, isLoading: .constant(false)) {}
            ActionButton("Retry", actionIcon: nil, isLoading: .constant(false)) {
               Task {
                  try await deleteThreadWith(id: id)
               }
            }
         case .threadCreatedError(let metadata, _):
            ActionButton("Cancel", actionIcon: nil, isLoading: .constant(false)) {}
            ActionButton("Retry", actionIcon: nil, isLoading: .constant(false)) {
               Task {
                  try await createThreadWith(metadata: metadata)
               }
            }
         default:
            EmptyView()
         }
      }
      .onChange(of: messagesProvider.errorMessage) { oldValue, newValue in
         if let newValue = newValue, oldValue != newValue {
            currentErrorMessage = newValue
         }
      }
      .onChange(of: runsProvider.errorMessage) { oldValue, newValue in
         if let newValue = newValue, oldValue != newValue {
            currentErrorMessage = newValue
         }
      }
      .alert(currentErrorMessage ?? "", isPresented: Binding<Bool>(
         get: { currentErrorMessage != nil },
         set: {
            if !$0 {
             clearErrorMessages()
            }
         }
      )) {
         // Alert configuration, if needed
      }
      .alert("Are you sure you want to delete this thread?", isPresented: $showDeleteThreadAlert) {
         Button("Yes", role: .destructive) {
            Task {
               if let threadID = currentThread?.id {
                  try await deleteThreadWith(id: threadID)
               }
            }
         }
      }
      .onChange(of: currentAssistant) { oldValue, newValue in
         if oldValue != newValue {
            if newValue == nil {
               /// if `newValue` is nil means that `currentAssistant` has been deleted, so we navigate to the chat screen.
               navigationProvider.changeToSelectedItem = (selectedItem: .chat, animated: false)
            }
         }
      }
      .sheet(isPresented: $showAssistantConfigurationModal) {
         AssistantConfigurationScreen(currentAssistant: $currentAssistant, assistantID: currentThread?.assistantID, provider: provider)
      }
   }
   
   var body: some View {
      ZStack {
         threadContent
         if showAudioSpeech == true {
            AudioSpeechScreen(audioProvider: .init(service: provider.service), showScreen: $showAudioSpeech.orFalse)
               .transition(.opacity) // Fade transition
         }
      }
      .animation(.linear, value: showAudioSpeech) // Smooth fade animation
   }
   
   @ViewBuilder
   var mainContent: some View {
      VStack(spacing: 0) {
         headerView
         switch item {
         case .assistant:
            if messagesProvider.chatDisplayMessages.isEmpty {
               assistantPlaceholder
            } else {
               list
            }
         case .thread(let thread):
            list
               .task {
                  Task {
                     isLoadingListItems = true
                     try await messagesProvider.listMessages(threadID: thread.id, assistantName: assistantName)
                     isLoadingListItems = false
                  }
               }
         default:
            EmptyView()
         }
      }
   }
   
   var headerView: some View {
      HStack(spacing: 0) {
         IconButton(iconName: "list.bullet") {}
            .opacity(0)
            .accessibilityHidden(true)
         Spacer()
         ActionButton(assistantName, actionIcon: Image(systemName: "chevron.right")) {
            showAssistantConfigurationModal = true
         }
         .frame(maxWidth: .infinity)
         .actionButtonStyle(.plainTrailing)
         Spacer()
         IconButton(iconName: "trash") {
            showDeleteThreadAlert = true
         }
         .iconButtonStyle(.plain)
         .disabled(currentThread == nil)
      }
      .padding(.horizontal)
   }
   
   private var assistantName: String {
      currentAssistant?.name ?? currentThread?.assistantName ?? "Assistant"
   }
   
   func clearErrorMessages() {
      currentErrorMessage = nil
      messagesProvider.errorMessage = nil
      runsProvider.errorMessage = nil
   }
   
   @ViewBuilder
   var assistantPlaceholder: some View {
      if let currentAssistant {
         VStack {
            Spacer()
            EmptyPlaceholderView(
               imageURL: currentAssistant.metadata[AssistantMetadataKeys.avatarMetadataKey],
               placeholder: Image(systemName: "oval.bottomhalf.filled"),
               title: currentAssistant.name ?? "NO NAME",
               subtitle: currentAssistant.description)
            Spacer()
         }
      } else {
         EmptyView()
      }
   }
   
   @ViewBuilder
   var list: some View {
      if isLoadingListItems {
         VStack {
            Spacer()
            ProgressView()
            Spacer()
         }
      } else {
         List(messagesProvider.chatDisplayMessages) { message in
            ChatMessageRow(message: message)
               .listRowSeparator(.hidden)
         }
         .listStyle(.plain)
      }
   }
   
   var bottomTextArea: some View {
      ThreadTextArea(
         prompt: $prompt,
         isAddAndRunActionLoading: $isAddAndRunActionLoading,
         isAddMessageActionLoading: $isAddMessageActionLoading, 
         showAudioSpeech: $showAudioSpeech)
      {
         Task {
            let input = prompt
            switch item {
            case .assistant(let assistant):
               isAddAndRunActionLoading = true
               // If the item is assistant, no thread has been created:
               // - Create a new thread only for first time.
               if currentThread == nil {
                  try await createThreadWith(assistant: assistant)
               }
               // - Add the message to the thread.
               if let threadID = currentThread?.id {
                  prompt = ""
                  try await addAndRun(threadID: threadID, assistantID: assistant.id, prompt: input)
                  startThread()
               }
               isAddAndRunActionLoading = false
            case .thread(let thread):
               let threadID = thread.id
               let assistantID = thread.assistantID!
               isAddAndRunActionLoading = true
               let input = prompt
               prompt = ""
               try await addAndRun(threadID: threadID, assistantID: assistantID, prompt: input)
               isAddAndRunActionLoading = false
            default:
               break
            }
            try await provider.defineThreadSnippetForMetadata(thread: currentThread, prompt: input)
         }
      } addMessageAction: {
         Task {
            let input = prompt
            switch item {
            case .assistant(let assistant):
               isAddMessageActionLoading = true
               // If the item is assistant, no thread has been created:
               // - Create a new thread only for first time.
               if currentThread == nil {
                  try await createThreadWith(assistant: assistant)
               }
               // - Add the message to the thread.
               if let threadID = currentThread?.id {
                  prompt = ""
                  try await addMessage(threadID: threadID, prompt: input)
                  startThread()
               }
               isAddMessageActionLoading = false
            case .thread(let thread):
               let threadID = thread.id
               isAddMessageActionLoading = true
               prompt = ""
               try await addMessage(threadID: threadID, prompt: input)
               isAddMessageActionLoading = false
            default:
               break
            }
            try await provider.defineThreadSnippetForMetadata(thread: currentThread, prompt: input)
         }
      }
   }
   
   // MARK: Private
   
   private func createThreadWith(
      assistant: AssistantObject)
      async throws
   {
      let threadMetadata = [
         ThreadMetadataKeys.assistantMetadataID: assistant.id,
         ThreadMetadataKeys.assistantMetadataName: assistant.name ?? "",
         ThreadMetadataKeys.assistantMetadataDescription: assistant.description ?? "",
      ]
      try await createThreadWith(metadata: threadMetadata)
   }
   
   private func createThreadWith(
      metadata: [String: String])
      async throws
   {
      let threadResponse = try await provider.createThread(metadata: metadata)
      currentThread = threadResponse.item
      currentProviderState = threadResponse.state
   }
   
   private func deleteThreadWith(id: String) async throws {
      let deletionResponse = try await provider.deleteThread(id: id)
      if deletionResponse.item?.deleted == true {
         currentThread = nil
      }
      currentProviderState = deletionResponse.state
   }
   
   private func dismissScreen() {
      navigationProvider.changeToSelectedItem = (selectedItem: .chat, animated: true)
      currentThread = nil
   }
   
   private func startThread() {
      guard let currentThread else {
         fatalError("currentThread should not be nil")
      }
      navigationProvider.changeToSelectedItem = (selectedItem: .thread(currentThread), animated: true)
   }
   
   private func addMessage(
      threadID: String,
      prompt: String)
      async throws
   {
      let paramaters = MessageParameter(role: .user, content: prompt)
      // TODO: here we can modify the thread metadata with the prompt
      
      guard let message = try await messagesProvider.createMessage(threadID: threadID, parameters: paramaters) else { return }
      guard let messageDisplayModel = messagesProvider.createMessageDisplayModel(from: message) else { return }
      await messagesProvider.addMessage(messageDisplayModel)
   }
   
   private func addAndRun(
      threadID: String,
      assistantID: String,
      prompt: String)
      async throws
   {
      let paramaters = MessageParameter(role: .user, content: prompt)
      
      // TODO: here we can modify the thread metadata with the prompt
      guard let userMessage = try await messagesProvider.createMessage(threadID: threadID, parameters: paramaters) else { return }
      guard let userMessageDisplayModel = messagesProvider.createMessageDisplayModel(from: userMessage) else { return }
      await messagesProvider.addMessage(userMessageDisplayModel)
      
      guard let run = try await runsProvider.runTheThread(threadID: threadID, parameters: RunParameter(assistantID: assistantID))
      else { return }
      
      guard let lastRunStep = try await runsProvider.getRunSteps(threadID: threadID, runID: run.id)
      else { return }
      
      // TODO remove force unwrapp after testing
      let assistantMessage = try await messagesProvider.retrieveMessage(threadID: threadID, messageID: lastRunStep.stepDetails.messageCreation.messageID)!
      let assistantMessageDisplayModel = messagesProvider.createMessageDisplayModel(from: assistantMessage, assistantName: assistantName)!
      
      await messagesProvider.addMessage(assistantMessageDisplayModel)
   }
   
   private let service: OpenAIService
   @Binding private var item: SideMenuItem
   @State private var navigationProvider: NavigationProvider
   @State private var messagesProvider: MessagesProvider
   @State private var runsProvider: RunsProvider
   @State private var provider: SideMenuConfigurationProvider
   @State private var isLoadingListItems = false
   @State private var currentAssistant: AssistantObject?
   @State private var currentThread: ThreadObject?
   @State private var prompt = ""
   @State private var currentProviderState: ProviderState?
   @State private var showDeleteThreadAlert = false
   @State private var showAssistantConfigurationModal = false
   @State private var isAddAndRunActionLoading: Bool? = false
   @State private var isAddMessageActionLoading: Bool? = false
   @State private var showAudioSpeech: Bool? = false
   @Environment(\.presentationMode) private var presentationMode
   
   /// USED FOR NOW ONLY FOR RUNS AND MESSAGES
   @State private var currentErrorMessage: String? = nil
   

}

// MARK: Mock+Preview

//#Preview {
//   ThreadScreen(service: OpenAIServiceFactory.service(apiKey: ""), item: .constant(.assistant(.init(id: UUID().uuidString, object: "", createdAt: 0, name: "Robocop", description: "", model: "", instructions: "", tools: [], fileIDS: [], metadata: [:]))), didCreateThread: { _ in }, didDeleteThread: { _ in })
//}
//
//#Preview {
//   ThreadScreen(service: OpenAIServiceFactory.service(apiKey: ""), item: .constant(.thread(.init(id: "", object: "", createdAt: 0, metadata: [:]))), didCreateThread: { _ in }, didDeleteThread: { _ in })
//      .disabled(true)
//}
