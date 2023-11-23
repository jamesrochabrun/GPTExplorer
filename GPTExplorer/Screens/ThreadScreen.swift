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
   @State private var threadProvider: ThreadProvider
   @State private var messagesProvider: MessagesProvider
   @State private var prompt: String = ""
   @State private var threadProviderFailed = false
   @State private var messagesProviderFailed = false
   @State private var showDeleteThreadAlert = false
   
   init(
      service: OpenAIService,
      item: SideMenuItem)
   {
      _threadProvider = State(initialValue: ThreadProvider(service: service))
      _messagesProvider = State(initialValue: MessagesProvider(service: service))
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
            // if this is reached we should:
            // retrieve the assistant? no! we just need the assistantID which is in the metadata.
            // get the messages
            list
            .task {
               Task {
                  threadProvider.threadObject = thread
                  try await messagesProvider.listMessages(threadID: thread.id, metadata: thread.metadata)
               }
            }
         }
      }
      .safeAreaInset(edge: .bottom) {
         bottomTextArea
      }
      .onChange(of: threadProvider.errorMessage) { oldValue, newValue in
         threadProviderFailed = oldValue != newValue
      }
      .onChange(of: messagesProvider.errorMessage) { oldValue, newValue in
         messagesProviderFailed = oldValue != newValue
      }
      .alert(threadProvider.errorMessage ?? "", isPresented: $threadProviderFailed) {
      }
      .alert(messagesProvider.errorMessage ?? "", isPresented: $messagesProviderFailed) {
      }
      .navigationBarItems(trailing: Button(action: {
         showDeleteThreadAlert = true
      }) {
         Image(systemName: "trash")
            .tint(ThemeColor.tintColor)
      }
         .disabled(threadProvider.threadObject == nil)
      )
      .alert("Are you sure you want to delete this thread?", isPresented: $showDeleteThreadAlert) {
         Button("Yes", role: .destructive) {
            Task {
               try await threadProvider.deleteThread(id: threadProvider.threadObject!.id)
            }
         }
         Button("Nope", role: .cancel) {}
      }
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
   }
   
   var bottomTextArea: some View {
      ThreadTextArea { prompt in
         Task {
            try await threadProvider.deleteThreads()

         }
      } addMessageAction: { prompt in
         Task {
            switch item {
            case .assistant(let assistant):
               // If the item is assistant, no thread has been created:
               // - Create a new thread
               try await startThreadFor(assistant)
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
}

// MARK: Mock+Preview

//#Preview {
//   ThreadScreen(service: OpenAIServiceFactory.service(apiKey: ""), item: )
//}
