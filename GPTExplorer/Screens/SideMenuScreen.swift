//
//  SideMenuScreen.swift
//  GPTExplorer
//
//  Created by James Rochabrun on 11/20/23.
//

import SwiftUI
import SwiftOpenAI

// MARK: SideMenuScreen

struct SideMenuScreen: View {
   
   // MARK: Init
   
   init(
      service: OpenAIService)
   {
      self.service = service
      _provider = State(initialValue: SideMenuConfigurationProvider(service: service))
   }
   
   var body: some View {
      List(0..<provider.items.count, id: \.self) { sectionIndex in
         Section(header: Text("Section \(sectionIndex + 1)")) {
            ForEach(provider.items[sectionIndex], id: \.id) { item in
               NavigationLink(destination: PushedScreen {
                  ThreadScreen(service: service, item: item)
               }) {
                  switch item {
                  case .assistant(let assistant):
                     ImageRow(
                        url: assistant.metadata[AssistantsProvider.avatarMetadataKey],
                        title: assistant.name ?? "NO NAME",
                        subtitle: assistant.description)
                  case .thread(let thread):
                     Text(thread.id)
                  }
               }
            }
         }
      }
      .onFirstAppear {
         Task {
            try await provider.listAssistants()
            try await provider.listThreads()
         }
      }
      .listStyle(.plain)
      .navigationBarTitle("Assistants", displayMode: .automatic)
      .navigationBarItems(trailing: Button(action: {
         self.showAssistantConfigurationModal = true
      }) {
         Image(systemName: "plus")
            .tint(ThemeColor.tintColor)
      })
      .sheet(isPresented: $showAssistantConfigurationModal) {
         AssistantConfigurationScreen(service: service)
            .onDisappear {
               Task {
                  try await provider.listAssistants()
               }
            }
      }
   }
   
   // MARK: private
   
   let service: OpenAIService
   @State private var provider: SideMenuConfigurationProvider
   @Environment(\.presentationMode) private var presentationMode
   @State private var showAssistantConfigurationModal = false

}

// MARK: Mock+Preview

//#Preview {
//   SideMenuScreen(service: OpenAIServiceFactory.service(apiKey: ""))
//}
