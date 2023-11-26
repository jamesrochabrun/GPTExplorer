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
   
   var item: SideMenuItem

   // MARK: Initialization

   init(
      service: OpenAIService,
      item: SideMenuItem)
   {
      self.service = service
      _threadProvider = State(initialValue: ThreadProvider(service: service))
      _messagesProvider = State(initialValue: MessagesProvider(service: service))
      _runsProvider = State(initialValue: RunsProvider(service: service))
      self.item = item
   }
   
   var body: some View {
      Group {
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
                  try await messagesProvider.listMessages(threadID: thread.id, metadata: thread.metadata)
               }
            }
         }
      }
      .safeAreaInset(edge: .bottom) {
         bottomTextArea
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
       .alert(currentErrorMessage ?? "", isPresented: Binding<Bool>(
           get: { currentErrorMessage != nil },
           set: { if !$0 { currentErrorMessage = nil } }
       )) {
           // Alert configuration, if needed
       }
      .navigationBarItems(trailing: Button(action: {
         showDeleteThreadAlert = true
      }) {
         Image(systemName: "trash")
            .tint(ThemeColor.brandColor)
      }
         .disabled(threadProvider.threadObject == nil)
      )
      .alert("Are you sure you want to delete this thread?", isPresented: $showDeleteThreadAlert) {
         Button("Yes", role: .destructive) {
            Task {
               try await threadProvider.deleteThread(id: threadProvider.threadObject!.id)
               self.presentationMode.wrappedValue.dismiss()
            }
         }
         Button("Nope", role: .cancel) {}
      }
      .toolbar {
          ToolbarItem(placement: .principal) {
             Menu.init(content: {
                Button {
                   showAssistantConfigurationModal = true
                }  label: {
                   Text("Edit assistant")
                }
             }, label: {
                return ActionButton(assistantName(), actionIcon: Image(systemName: "chevron.right")) {}
                   .actionButtonStyle(.plainTrailing)
             })
      }}
      .sheet(isPresented: $showAssistantConfigurationModal) {
         AssistantConfigurationScreen(service: service, assistantID: assistantID())
         /// Think weel how we want to manage this so we dont pay too much money
//            .onDisappear {
//               Task {
//                  try await assistantpro
//               }
//            }
      }
   }
   
   func assistantName() -> String {
      let assistantName: String?
      switch item {
      case .assistant(let assistantObject):
         assistantName = assistantObject.name
      case .thread(let threadObject):
         assistantName = threadObject.metadata[ThreadProvider.assistantMetadataName]
      }
      return assistantName ?? "Assistant"
   }
   
   func assistantID() -> String? {
      let assistantID: String?
      switch item {
      case .assistant(let assistantObject):
         assistantID = assistantObject.id
      case .thread(let threadObject):
         assistantID = threadObject.metadata[ThreadProvider.assistantMetadataID]
      }
      return assistantID
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
   
   var list: some View {
      List(messagesProvider.chatDisplayMessages) { message in
         ChatMessageRow(message: message)
            .listRowSeparator(.hidden)
      }
      .listStyle(.plain)
   }
   
   var bottomTextArea: some View {
      ThreadTextArea { prompt in
       
         Task {
            switch item {
            case .assistant(let assistant):
               // If the item is assistant, no thread has been created:
               // - Create a new thread only for first time.
               if threadProvider.threadObject == nil {
                  try await startThreadFor(assistant)
               }
               // - Add the message to the thread.
               if let threadID = threadProvider.threadObject?.id {
                  let paramaters = MessageParameter(role: "user", content: prompt)
                  
                  // TODO: here we can modify the thread metadata with the prompt
                  try await messagesProvider.addMessage(threadID: threadID, parameters: paramaters)
                  try await runsProvider.createRun(threadID: threadID, parameters: RunParameter(assistantID: assistant.id))
               }
            case .thread(let thread):
               threadProvider.threadObject = thread
               let paramaters = MessageParameter(role: "user", content: prompt)
               try await messagesProvider.addMessage(threadID: threadProvider.threadObject!.id, parameters: paramaters)
               let assistantID = thread.metadata[ThreadProvider.assistantMetadataID]!
               
               // TODO: figure it out what we want to do here with the run
               try await runsProvider.createRun(threadID: thread.id, parameters: RunParameter(assistantID: assistantID))
            }
         }
         
      } addMessageAction: { prompt in
         Task {
            switch item {
            case .assistant(let assistant):
               // If the item is assistant, no thread has been created:
               // - Create a new thread only for first time.
               if threadProvider.threadObject == nil {
                  try await startThreadFor(assistant)
               }
               // - Add the message to the thread.
               if let threadID = threadProvider.threadObject?.id {
                  let paramaters = MessageParameter(role: "user", content: prompt)
                  
                  // TODO: here we can modify the thread metadata with the prompt
                  try await messagesProvider.addMessage(threadID: threadID, parameters: paramaters)
               }
            case .thread(let thread):
               threadProvider.threadObject = thread
               let paramaters = MessageParameter(role: "user", content: prompt)
               try await messagesProvider.addMessage(threadID: threadProvider.threadObject!.id, parameters: paramaters)
            }
         }
      }
   }
   
   private func startThreadFor(
      _ assistant: AssistantObject)
      async throws
   {
      let threadMetadata = [
         ThreadProvider.assistantMetadataID: assistant.id,
         ThreadProvider.assistantMetadataName: assistant.name ?? "",
         ThreadProvider.assistantMetadataDescription: assistant.description ?? "",
      ]
      try await threadProvider.createThread(parameters: CreateThreadParameters(metadata: threadMetadata))
   }
   
   // MARK: Private

   private let service: OpenAIService
   @State private var currentErrorMessage: String? = nil
   @State private var threadProvider: ThreadProvider
   @State private var messagesProvider: MessagesProvider
   @State private var runsProvider: RunsProvider
   @State private var prompt: String = ""
   @State private var threadProviderFailed = false
   @State private var messagesProviderFailed = false
   @State private var runsProviderFailed = false
   @State private var showDeleteThreadAlert = false
   @State private var showAssistantConfigurationModal = false
   @Environment(\.presentationMode) private var presentationMode
}

// MARK: Mock+Preview

//#Preview {
//   ThreadScreen(service: OpenAIServiceFactory.service(apiKey: ""), item: )
//}
