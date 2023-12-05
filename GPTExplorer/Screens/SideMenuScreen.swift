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
   
   func selectedBackground(item: SideMenuItem) -> some View {
      Rectangle()
         .fill(.blue)
         .frame(maxWidth: navigationProvider.changeToSelectedItem.selectedItem.id == item.id ? .infinity : 0)
         .frame(maxWidth: .infinity, alignment: .leading)
   }
   
   var body: some View {
      List(SideMenuConfigurationProvider.Section.allCases) { section in
         Section(header: Text(section.rawValue)) {
            ForEach(provider.mapItems[section] ?? [], id: \.id) { item in
               Group {
                  switch item {
                  case .assistant(let assistant):
                     ImageRow(
                        url: assistant.metadata[AssistantMetadataKeys.avatarMetadataKey],
                        title: assistant.name ?? "NO NAME",
                        subtitle: assistant.description)
                  case .thread(let thread):
                     if let displayTitle = thread.displayTitle {
                        Text(displayTitle)
                           .frame(maxWidth: .infinity, alignment: .leading)
                     } else {
                        LoadingDotsView(prefix: "New chat")
                           .frame(maxWidth: .infinity, alignment: .leading)
                     }
                  case .action(let action):
                     switch action {
                     case .createAssistant:
                        Text("Create Asssitant")
                     }
                  case .none:
                     EmptyView()
                  }
               }
               .listRowSeparator(.hidden)
               .listRowBackground(
                  ThemeColor.backgroundColor
               )
               .padding(.vertical, Sizes.spacingExtraSmall / 2)
               .padding(.horizontal, Sizes.spacingExtraSmall)
               .background(
                  selectedBackground(item: item)
               )
               .background(
                  Color.clear // This helps with the tap area
               )
               .onTapGesture {
                  navigationProvider.changeToSelectedItem = (selectedItem: item, animated: false)
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
      .sheet(isPresented: $showAssistantConfigurationModal) {
         /// TODO: Do we want to present this as a modal instead? currently shown as an action 
         AssistantConfigurationScreen(currentAssistant: .constant(nil), assistantID: nil, provider: provider)
//            .onDisappear {
//               Task {
//                  try await provider.updateSideMenu(sections: [.assistants])
//               }
//            }
      }
   }
   
   // MARK: private
   
   private let service: OpenAIService
   @State private var provider: SideMenuConfigurationProvider
   @Environment(\.presentationMode) private var presentationMode
   @State private var showAssistantConfigurationModal = false
   @State private var currentProviderState: ProviderState?
   
   
   private func updateSideMenu(
      sections: Set<SideMenuConfigurationProvider.Section>)
      async throws
   {
      let updateSideMenuResponse = try await provider.updateSideMenu(sections: sections)
      currentProviderState = updateSideMenuResponse.state
   }

}
