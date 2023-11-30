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
      service: OpenAIService,
      navigationProvider: NavigationProvider)
   {
      self.service = service
      self._navigationProvider = State(initialValue: navigationProvider)
      _provider = State(initialValue: SideMenuConfigurationProvider(service: service))
   }
   
   @State private var navigationProvider: NavigationProvider
   
   var body: some View {
      List(SideMenuConfigurationProvider.Section.allCases) { section in
         Section(header: Text(section.rawValue)) {
            ForEach(provider.mapItems[section] ?? [], id: \.id) { item in
               Group {
                  switch item {
                  case .assistant(let assistant):
                     ImageRow(
                        url: assistant.metadata[AssistantsProvider.avatarMetadataKey],
                        title: assistant.name ?? "NO NAME",
                        subtitle: assistant.description)
                  case .thread(let thread):
                     Text(thread.displayTitle ?? thread.id)
                  case .none:
                     EmptyView()
                  }
               }
               .listRowSeparator(.hidden)
               .listRowBackground(
                  ThemeColor.backgroundColor
               )
               .onTapGesture {
                  navigationProvider.selectedItem = item
                  withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                     navigationProvider.isOpen = false
                  }
               }
            }
         }
      }
      .foregroundColor(.white)
      .listStyle(.plain)
      .onFirstAppear {
         Task {
            try await provider.updateSideMenuContent()
         }
      }
      .onChange(of: provider.errorMessage) { oldValue, newValue in
         providerDidFail = oldValue != newValue
      }
      .alert(provider.errorMessage ?? "", isPresented: $providerDidFail) {
      }
      .sheet(isPresented: $showAssistantConfigurationModal) {
         AssistantConfigurationScreen(service: service, assistantID: nil)
            .onDisappear {
               Task {
                  try await provider.updateSideMenuContent()
               }
            }
      }
   }
   
   // MARK: private
   
   private let service: OpenAIService
   @State private var provider: SideMenuConfigurationProvider
   @Environment(\.presentationMode) private var presentationMode
   @State private var showAssistantConfigurationModal = false
   @State private var providerDidFail = false

}

// MARK: Mock+Preview

#Preview {
   SideMenuScreen(service: OpenAIServiceFactory.service(apiKey: ""), navigationProvider: .init())
}
