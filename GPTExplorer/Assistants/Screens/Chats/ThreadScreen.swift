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
      _item = item
      switch item.wrappedValue {
      case .assistant(let assistantObject):
         _currentAssistant = State(initialValue: assistantObject)
      case .thread(let thread):
         _currentThread = State(initialValue: thread)
      default:
         fatalError("This is programming error")
      }
   }
   
   var body: some View {
      NavigationView {
         AudioSpeechContainer(
            service: provider.service,
            currentModel: .custom(currentAssistant?.model ?? ""),
            showAudioSpeech: $showAudioSpeech.orFalse) {
               threadContent
            }      }
      .onFirstAppear {
         Task {
            try await retrieveAssistantFromThreadMetadata()
         }
      }
   }
   
   var threadContent: some View {
      VStack(spacing: 0) {
         mainContent
         bottomTextArea
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
         case .asssitantRetrievedError:
            ActionButton("Cancel", actionIcon: nil, isLoading: .constant(false)) {}
            ActionButton("Retry", actionIcon: nil, isLoading: .constant(false)) {
               Task {
                  try await retrieveAssistantFromThreadMetadata()
               }
            }
         case .threadDeletedSuccess:
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
         case .createMessageError(let runID, let threadID, _):
            ActionButton("Cancel", actionIcon: nil, isLoading: .constant(false)) {}
            ActionButton("Cancel Run", actionIcon: nil, isLoading: .constant(false)) {
               Task {
                  try await cancelRun(runID: runID, threadID: threadID)
               }
            }
         case .messageCreationIDError, .getRunStepsError, .lastRunStepsError:
            ActionButton("Ok", actionIcon: nil, isLoading: .constant(false)) {}
         case .createRunError(let threadID, let assistantID, _):
            ActionButton("Cancel", actionIcon: nil, isLoading: .constant(false)) {}
            ActionButton("Retry", actionIcon: nil, isLoading: .constant(false)) {
               Task {
                  try await createRun(threadID: threadID, assistantID: assistantID)
               }
            }
         case .cancelRunError(let runID, let threadID, _):
            ActionButton("Cancel", actionIcon: nil, isLoading: .constant(false)) {}
            ActionButton("Retry", actionIcon: nil, isLoading: .constant(false)) {
               Task {
                  try await cancelRun(runID: runID, threadID: threadID)
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
         AssistantConfigurationScreen(
            currentAssistant: $currentAssistant,
            assistantID: currentThread?.assistantID,
            provider: provider,
            service: service)
      }
      .sheet(item: $runMetadata) { runMetadata in
         RunDetailsScreen(runsProvider: runsProvider, runMetadata: runMetadata)
      }
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
   
   @ViewBuilder
   var assistantPlaceholder: some View {
      if let currentAssistant {
         VStack {
            Spacer()
            EmptyAssistantPlaceholderView(
               imageURL: currentAssistant.avatarURL,
               title: currentAssistant.name ?? "Assistant",
               subtitle: currentAssistant.description) {
                  Image(systemName: "oval.bottomhalf.filled")
               }
            Spacer()
         }
      } else {
         EmptyView()
      }
   }
   
   @ViewBuilder
   var list: some View {
      ScrollViewReader { proxy in
         if isLoadingListItems {
            VStack {
               Spacer()
               ProgressView()
               Spacer()
            }
         } else {
            List(messagesProvider.chatDisplayMessages) { message in
               ChatMessageRow(message: message, runMetadata: $runMetadata)
                  .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
            .onChange(of: messagesProvider.chatDisplayMessages.last?.content) {
               let lastMessage = messagesProvider.chatDisplayMessages.last
               if let id = lastMessage?.id {
                  proxy.scrollTo(id, anchor: .bottom)
               }
            }
         }
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
               // - 1 Create a new thread only for first time.
               if currentThread == nil {
                  try await createThreadWith(assistant: assistant)
               }
               if let thread = currentThread {
                  prompt = ""
                  // - 2 Add the message to the Run.
                  try await prepareMessageForRun(threadID: thread.id, prompt: input)
                  // - 3 Create the run.
                  try await createRun(threadID: thread.id, assistantID: assistant.id)

                  // - 4 Navigate to the newly created thread.
                  navigateTo(thread: thread)
               }
               isAddAndRunActionLoading = false
            case .thread(let thread):
               let threadID = thread.id
               let assistantID = thread.assistantID!
               isAddAndRunActionLoading = true
               let input = prompt
               prompt = ""
               try await prepareMessageForRun(threadID: threadID, prompt: input)
               try await createRun(threadID: thread.id, assistantID: assistantID)
               isAddAndRunActionLoading = false
            default:
               break
            }
            try await provider.setInitialSnippetFor(thread: currentThread, prompt: input)
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
               // - 1 Add the message to the thread.
               if let thread = currentThread {
                  prompt = ""
                  try await addMessage(threadID: thread.id, prompt: input)
                  // - 2 Navigate to the newly created thread.
                  navigateTo(thread: thread)
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
            try await provider.setInitialSnippetFor(thread: currentThread, prompt: input)
         }
      }
   }
   
   // MARK: Private
   
   private var assistantName: String {
      currentAssistant?.name ?? currentThread?.assistantName ?? "Assistant"
   }
   
   private func clearErrorMessages() {
      currentErrorMessage = nil
      messagesProvider.errorMessage = nil
      runsProvider.errorMessage = nil
   }
   
   /// To be used if `item` is not `.assistant` and we need to retrieve an assistant from the metadata thread.
   private func retrieveAssistantFromThreadMetadata()
      async throws
   {
      if let assistantID = currentThread?.assistantID {
         currentAssistant = try await provider.retrieveAssistant(id: assistantID).item
      }
   }
   
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
   
   private func deleteThreadWith(id: String) 
      async throws
   {
      let deletionResponse = try await provider.deleteThread(id: id)
      if deletionResponse.item?.deleted == true {
         currentThread = nil
      }
      currentProviderState = deletionResponse.state
   }
   
   private func cancelRun(
      runID: String, 
      threadID: String)
      async throws
   {
      let cancelRunResponse = try await runsProvider.cancelRun(runID: runID, threadID: threadID)
      // TODO: Do we need the canceled run?
      currentProviderState = cancelRunResponse.state
   }
   
   private func dismissScreen() {
      navigationProvider.changeToSelectedItem = (selectedItem: .chat, animated: true)
      currentThread = nil
   }
   
   private func navigateTo(
      thread: ThreadObject)
   {
      navigationProvider.changeToSelectedItem = (selectedItem: .thread(thread), animated: true)
   }
   
   private func addMessage(
      threadID: String,
      prompt: String)
      async throws
   {
      let paramaters = MessageParameter(role: .user, content: prompt)
      // Tip: here we can modify the thread metadata with the prompt
      let messageResponse = try await messagesProvider.createMessage(threadID: threadID, parameters: paramaters)
      guard let message = messageResponse.item else {
         currentProviderState = messageResponse.state
         return
      }
      let messageDisplayModelResponse = messagesProvider.createMessageDisplayModel(from: message)
      guard let messageDisplayModel = messageDisplayModelResponse.item else {
         currentProviderState = messageDisplayModelResponse.state
         return
      }
      await messagesProvider.addMessage(messageDisplayModel)
   }
   
   private func prepareMessageForRun(
      threadID: String,
      prompt: String)
      async throws
   {
      let paramaters = MessageParameter(role: .user, content: prompt)
      
      // Tip: here we can modify the thread metadata with the prompt
      let messageResponse = try await messagesProvider.createMessage(threadID: threadID, parameters: paramaters)
      
      guard let message = messageResponse.item else {
         currentProviderState = messageResponse.state
         return
      }
      
      let messageDisplayModelResponse = messagesProvider.createMessageDisplayModel(from: message)
      guard let messageDisplayModel = messageDisplayModelResponse.item else {
         currentProviderState = messageDisplayModelResponse.state
         return
      }
      
      await messagesProvider.addMessage(messageDisplayModel)
   }
      
   private func createRun(
      threadID: String,
      assistantID: String)
      async throws
   {
      let runResponse = try await runsProvider.createRun(threadID: threadID, parameters: RunParameter(assistantID: assistantID))
      
      guard let run = runResponse.item else {
         // Remeber that this will show repeated information to user. We may want to avoid this.
         currentProviderState = runResponse.state
         return
      }
      let lastRunStepResponse = try await runsProvider.getLastRunSteps(threadID: threadID, runID: run.id)
      
      guard let lastRunStep = lastRunStepResponse.item else {
         currentProviderState = lastRunStepResponse.state
         return
      }
      
      if let lastMessageCreationStep = lastRunStep.messageCreationStep {
         try await configureMessageCreationStep(lastMessageCreationStep, threadID: threadID, runID: run.id)
      }
      
      if let lastToolCallStep = lastRunStep.toolCallsStep {
         await configureToolCallStep(lastToolCallStep)
      }
   }
   
   private func configureMessageCreationStep(
      _ step: RunStepObject,
      threadID: String,
      runID: String)
      async throws
   {
      guard let messageID = step.stepDetails.messageCreation?.messageID else {
         currentProviderState = .messageCreationIDError(message: "Failed to get a valid message ID from step details.")
         return
      }
      let messageResponse = try await messagesProvider.retrieveMessage(threadID: threadID, messageID: messageID)
      
      guard let message = messageResponse.item else {
         currentProviderState = messageResponse.state
         return
      }
       let assistantMessageDisplayModelResponse = messagesProvider.createMessageDisplayModel(
         from: message,
         assistantName: assistantName,
         runID: runID,
         threadID: threadID)
      
      if let assistantMessageDisplayModel = assistantMessageDisplayModelResponse.item {
         await messagesProvider.addMessage(assistantMessageDisplayModel)
      } else {
         currentProviderState = assistantMessageDisplayModelResponse.state
      }
   }
   
   private func configureToolCallStep(_ step: RunStepObject) 
      async
   {
      for toolCall in step.stepDetails.toolCalls ?? [] {
         switch toolCall.toolCall {
         case .codeInterpreterToolCall(let codeInterpreterToolCall):
            let displayToolCallContent = ChatMessageDisplayModel.DisplayContent.toolCall(.codeInterpreterToolCall(codeInterpreterToolCall))
            let displayMessage = ChatMessageDisplayModel(
               content: displayToolCallContent,
               origin: .received(.asssistant(.toolCall(.codeInterpreter))))
            await messagesProvider.addMessage(displayMessage)
         case .functionToolCall(let functionToolCall):
            let displayToolCallContent = ChatMessageDisplayModel.DisplayContent.toolCall(.functionToolCall(functionToolCall))
            let displayMessage = ChatMessageDisplayModel(
               content: displayToolCallContent,
               origin: .received(.asssistant(.toolCall(.function))))
            await messagesProvider.addMessage(displayMessage)
         case .retrieveToolCall(let retrieveToolCall):
            let displayToolCallContent = ChatMessageDisplayModel.DisplayContent.toolCall(.retrieveToolCall(retrieveToolCall))
            let displayMessage = ChatMessageDisplayModel(
               content: displayToolCallContent,
               origin: .received(.asssistant(.toolCall(.retrieval))))
            await messagesProvider.addMessage(displayMessage)
         }
      }
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
   @State private var runMetadata: ChatMessageDisplayModel.RunMetadata? = nil
   @Environment(\.presentationMode) private var presentationMode
   
   /// USED FOR NOW ONLY FOR RUNS AND MESSAGES
   @State private var currentErrorMessage: String? = nil
}

// MARK: Mock+Preview

#Preview("Assistant") {
   let mockService = OpenAIServiceFactory.mockService()
   return ThreadScreen(
      service: mockService,
      provider: .init(service: mockService),
      item: .constant(
         .assistant(.init(id: UUID().uuidString, object: "", createdAt: 0, name: "Robocop", description: "", model: "", instructions: "", tools: [], fileIDS: [], metadata: [:]))))
}

#Preview("Thread") {
   let mockService = OpenAIServiceFactory.mockService()
   return ThreadScreen(
      service: mockService,
      provider: .init(service: mockService),
      item: .constant(.thread(.init(id: "", object: "", createdAt: 0, metadata: [:]))))
}
