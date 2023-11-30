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
   
   var didDeleteThread: () -> Void
   
   init(
      service: OpenAIService,
      item: Binding<SideMenuItem>,
      didDeleteThread: @escaping () -> Void)
   {
      self.service = service
      _threadProvider = State(initialValue: ThreadProvider(service: service))
      _messagesProvider = State(initialValue: MessagesProvider(service: service))
      _runsProvider = State(initialValue: RunsProvider(service: service))
      self._item = item
      self.didDeleteThread = didDeleteThread
   }
   
   var body: some View {
      NavigationView {
         mainContent
      }
      .safeAreaInset(edge: .bottom) {
         bottomTextArea
            .padding(.bottom, 34)
      }
      .onChange(of: threadProvider.errorMessage) { oldValue, newValue in
         if let newValue = newValue, oldValue != newValue {
            currentErrorMessage = newValue
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
      .onChange(of: threadProvider.successMessage) { oldValue, newValue in
         if let newValue = newValue, oldValue != newValue {
            currentSuccessMessage = newValue
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
      .alert(currentSuccessMessage ?? "", isPresented: Binding<Bool>(
         get: { currentSuccessMessage != nil },
         set: {
            if !$0 {
               currentSuccessMessage = nil
            }
         }
      )) {
         // Alert configuration, if needed
         Button("Ok", role: .cancel) {
            didDeleteThread()
            
            // TODO: open the menu
            // update the thread side menu provide
            // In short you should send a completion that this is deleted.
         }
      }
      .alert("Are you sure you want to delete this thread?", isPresented: $showDeleteThreadAlert) {
         Button("Yes", role: .destructive) {
            Task {
               try await threadProvider.deleteThread(id: threadProvider.threadObject!.id)
            }
         }
      }
      .sheet(isPresented: $showAssistantConfigurationModal) {
         AssistantConfigurationScreen(service: service, assistantID: assistantID())
      }
   }
   
   @ViewBuilder
   var mainContent: some View {
      VStack(spacing: 0) {
         headerView
         switch item {
         case .assistant:
            // if this is reached means there are no messages, no thread created, we create one
            if messagesProvider.chatDisplayMessages.isEmpty {
               assistantPlaceholder
            } else {
               list
            }
         case .thread(let thread):
            list
               .task {
                  threadProvider.threadObject = thread
                  Task {
                     isLoadingListItems = true
                     try await messagesProvider.listMessages(threadID: thread.id, assistantName: assistantName())
                     isLoadingListItems = false
                  }
               }
         case .none:
            Text("TODO (chat)")
         }
      }
   }
   
   var headerView: some View {
      HStack(spacing: 0) {
         IconButton(iconName: "list.bullet") {}
            .opacity(0)
            .accessibilityHidden(true)
         Spacer()
         ActionButton(assistantName(), actionIcon: Image(systemName: "chevron.right")) {
            showAssistantConfigurationModal = true
         }
         .frame(maxWidth: .infinity)
         .actionButtonStyle(.plainTrailing)
         Spacer()
         IconButton(iconName: "trash") {
            showDeleteThreadAlert = true
         }
         .iconButtonStyle(.plain)
         .disabled(threadProvider.threadObject == nil)
      }
      .padding(.horizontal)
   }
   
   func assistantName() -> String {
      let assistantName: String?
      switch item {
      case .assistant(let assistantObject):
         assistantName = assistantObject.name
      case .thread(let threadObject):
         assistantName = threadObject.assistantName
      case .none:
         assistantName = nil
      }
      return assistantName ?? "Assistant"
   }
   
   func assistantID() -> String? {
      let assistantID: String?
      switch item {
      case .assistant(let assistantObject):
         assistantID = assistantObject.id
      case .thread(let threadObject):
         assistantID = threadObject.assistantID
      case .none:
         assistantID = ""
      }
      return assistantID
   }
   
   func clearErrorMessages() {
      currentErrorMessage = nil
      threadProvider.errorMessage = nil
      messagesProvider.errorMessage = nil
      runsProvider.errorMessage = nil
   }
   
   @ViewBuilder
   var assistantPlaceholder: some View {
      if case .assistant(let assistant) = item {
         VStack {
            Spacer()
            EmptyPlaceholderView(
               imageURL: assistant.metadata[AssistantsProvider.avatarMetadataKey],
               placeholder: Image(systemName: "oval.bottomhalf.filled"),
               title: assistant.name ?? "NO NAME",
               subtitle: assistant.description)
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
         isAddMessageActionLoading: $isAddMessageActionLoading)
      {
         Task {
            let input = prompt
            switch item {
            case .assistant(let assistant):
               isAddAndRunActionLoading = true
               // If the item is assistant, no thread has been created:
               // - Create a new thread only for first time.
               if threadProvider.threadObject == nil {
                  try await startThreadFor(assistant)
               }
               // - Add the message to the thread.
               if let threadID = threadProvider.threadObject?.id {
                  prompt = ""
                  try await addAndRun(threadID: threadID, assistantID: assistant.id, prompt: input)
               }
               isAddAndRunActionLoading = false
            case .thread(let thread):
               threadProvider.threadObject = thread
               let threadID = threadProvider.threadObject!.id
               let assistantID = thread.assistantID!
               isAddAndRunActionLoading = true
               let input = prompt
               prompt = ""
               try await addAndRun(threadID: threadID, assistantID: assistantID, prompt: input)
               isAddAndRunActionLoading = false
            case .none:
               break
            }
            try await threadProvider.defineThreadSnippetForMetadata(prompt: input)
         }
      } addMessageAction: {
         Task {
            let input = prompt
            switch item {
            case .assistant(let assistant):
               isAddMessageActionLoading = true
               // If the item is assistant, no thread has been created:
               // - Create a new thread only for first time.
               if threadProvider.threadObject == nil {
                  try await startThreadFor(assistant)
               }
               // - Add the message to the thread.
               if let threadID = threadProvider.threadObject?.id {
                  prompt = ""
                  try await addMessage(threadID: threadID, prompt: input)
               }
               isAddMessageActionLoading = false
            case .thread(let thread):
               threadProvider.threadObject = thread
               let threadID = threadProvider.threadObject!.id
               isAddMessageActionLoading = true
               prompt = ""
               try await addMessage(threadID: threadID, prompt: input)
               isAddMessageActionLoading = false
            case .none:
               break
            }
            try await threadProvider.defineThreadSnippetForMetadata(prompt: input)
         }
      }
   }
   
   // MARK: Private
   
   private func startThreadFor(
      _ assistant: AssistantObject)
      async throws
   {
      let threadMetadata = [
         ThreadMetadataKeys.assistantMetadataID: assistant.id,
         ThreadMetadataKeys.assistantMetadataName: assistant.name ?? "",
         ThreadMetadataKeys.assistantMetadataDescription: assistant.description ?? "",
      ]
      try await threadProvider.createThread(parameters: CreateThreadParameters(metadata: threadMetadata))
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
      let assistantMessageDisplayModel = messagesProvider.createMessageDisplayModel(from: assistantMessage, assistantName: assistantName())!
      
      await messagesProvider.addMessage(assistantMessageDisplayModel)
   }
   
   private let service: OpenAIService
   @Binding private var item: SideMenuItem
   @State private var isLoadingListItems = false
   @State private var prompt = ""
   @State private var currentErrorMessage: String? = nil
   @State private var currentSuccessMessage: String? = nil
   @State private var threadProvider: ThreadProvider
   @State private var messagesProvider: MessagesProvider
   @State private var runsProvider: RunsProvider
   @State private var threadProviderFailed = false
   @State private var messagesProviderFailed = false
   @State private var runsProviderFailed = false
   @State private var showDeleteThreadAlert = false
   @State private var showAssistantConfigurationModal = false
   @State private var isAddAndRunActionLoading: Bool? = false
   @State private var isAddMessageActionLoading: Bool? = false
   @Environment(\.presentationMode) private var presentationMode
}

// MARK: Mock+Preview

#Preview {
   ThreadScreen(service: OpenAIServiceFactory.service(apiKey: ""), item: .constant(.assistant(.init(id: UUID().uuidString, object: "", createdAt: 0, name: "Robocop", description: "", model: "", instructions: "", tools: [], fileIDS: [], metadata: [:]))), didDeleteThread: {})
}

#Preview {
   ThreadScreen(service: OpenAIServiceFactory.service(apiKey: ""), item: .constant(.thread(.init(id: "", object: "", createdAt: 0, metadata: [:]))), didDeleteThread: {})
}
