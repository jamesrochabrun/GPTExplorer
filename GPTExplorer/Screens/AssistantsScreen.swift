//
//  AssistantsScreen.swift
//  GPTExplorer
//
//  Created by James Rochabrun on 11/20/23.
//

import SwiftUI
import SwiftOpenAI

// MARK: AssistantsScreen

struct AssistantsScreen: View {
   
   // MARK: Init
   
   init(
      service: OpenAIService)
   {
      self.service = service
      _provider = State(initialValue: AssistantConfigurationProvider(service: service))
   }
   
   var body: some View {
      List(provider.assistants, id: \.id) { assistant in
         NavigationLink(destination: AssistantMessagesScreen(assistant: assistant)) {
            let url = assistant.metadata[AssistantConfigurationProvider.avatarMetadataKey]
            ImageRow(url: url, title: assistant.name ?? "NO NAME", subtitle: assistant.description)
         }
      }
      .task {
         Task {
            try await provider.listAssistants()
         }
      }
      .listStyle(.plain)
      .navigationBarBackButtonHidden(true)
      .navigationBarTitle("Assistants", displayMode: .automatic)
      .navigationBarItems(leading: Button(action: {
         self.presentationMode.wrappedValue.dismiss()
      }) {
         HStack {
            Image(systemName: "chevron.left")
               .tint(ThemeColor.tintColor)
         }
      })
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
   
   @State private var provider: AssistantConfigurationProvider
   @Environment(\.presentationMode) private var presentationMode
   @State private var showAssistantConfigurationModal = false
   private let service: OpenAIService

}

// MARK: Mock+Preview

#Preview {
   AssistantsScreen(service: OpenAIServiceFactory.service(apiKey: ""))
}
