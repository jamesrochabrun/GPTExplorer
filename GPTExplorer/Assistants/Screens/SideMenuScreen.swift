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
      sideMenuConfigurationProvider: SideMenuConfigurationProvider)
   {
      self.service = service
      self._navigationProvider = State(initialValue: sideMenuConfigurationProvider.navigationProvider)
      self._provider = State(initialValue: sideMenuConfigurationProvider)
   }
   
   @State private var navigationProvider: NavigationProvider

   private func selectedBackground(
      item: SideMenuItem)
      -> some View
   {
      Rectangle()
         .fill(navigationProvider.changeToSelectedItem.selectedItem.id == item.id ? ThemeColor.rowSelectionColor : .clear)
   }
   
   var body: some View {
      List(SideMenuConfigurationProvider.Section.allCases) { section in
         Section(header: Text(section.rawValue)) {
            ForEach(provider.mapItems[section] ?? [], id: \.id) { item in
               Group {
                  switch item {
                  case .assistant(let assistant):
                     ImageRow(
                        url: assistant.avatarURL,
                        title: assistant.name ?? "NO NAME",
                        subtitle: assistant.description)
                  case .thread(let thread):
                     if let displayTitle = thread.displayTitle {
                        Text(displayTitle)
                     } else {
                        LoadingDotsView(prefix: "New chat")
                     }
                  case .action(let action):
                     switch action {
                     case .createAssistant:
                        Text("Create Asssitant")
                     }
                  case .chat:
                     Text("ChatGPT")
                  }
               }
               .padding(.vertical, 4)
               .padding(.horizontal, 4)
               .frame(maxWidth: .infinity, alignment: .leading)
               .listRowSeparator(.hidden)
               .listRowBackground(
                  Color.clear
               )
               .padding(.vertical, Sizes.spacingExtraSmall / 2)
               .padding(.horizontal, Sizes.spacingExtraSmall)
               .background(
                  selectedBackground(item: item)
               )
               .clipShape(RoundedRectangle(cornerRadius: 10))
               .contentShape(Rectangle()) // This helps with the tap area of each item
               .onTapGesture {
                  if item == .action(.createAssistant) {
                     showAssistantConfigurationModal = true
                     return
                  }
                  navigateToSelected(item: item)
               }
            }
         }
      }
      .foregroundColor(.white)
      .listStyle(.plain)
      .onFirstAppear {
         Task {
             try await updateSideMenu(sections: Set(SideMenuConfigurationProvider.Section.allCases))
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
         case .udpateSideMenuError(let sections, _):
            Button("Retry", role: .cancel) {
               Task {
                  try await updateSideMenu(sections: sections)
               }
            }
         default:
            EmptyView()
         }
      }
      .onChange(of: currentAssistant) { oldValue, newValue in
         if oldValue != newValue, let newValue  {
            navigateToSelected(item: .assistant(newValue))
         }
      }
      .sheet(isPresented: $showAssistantConfigurationModal) {
         AssistantConfigurationScreen(currentAssistant: $currentAssistant, assistantID: nil, provider: provider, service: service)
      }
   }
   private func navigateToSelected(item: SideMenuItem) {
      navigationProvider.changeToSelectedItem = (selectedItem: item, animated: false)
      withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
         navigationProvider.isOpen = false
      }
   }
   
   // MARK: private
   
   private let service: OpenAIService
   @State private var provider: SideMenuConfigurationProvider
   @Environment(\.presentationMode) private var presentationMode
   @State private var showAssistantConfigurationModal = false
   @State private var currentProviderState: ProviderState?
   @State private var currentAssistant: AssistantObject?
   
   
   private func updateSideMenu(
      sections: Set<SideMenuConfigurationProvider.Section>)
      async throws
   {
      let updateSideMenuResponse = try await provider.updateSideMenu(sections: sections)
      currentProviderState = updateSideMenuResponse.state
   }

}

#Preview("Screen") {
   SideMenuScreen(service: OpenAIServiceFactory.service(apiKey: ""), sideMenuConfigurationProvider: .init(service: OpenAIServiceFactory.service(apiKey: "")))
}
