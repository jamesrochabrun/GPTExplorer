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
         .frame(maxWidth: navigationProvider.selectedItem.id == item.id ? .infinity : 0)
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
                        url: assistant.metadata[AssistantsProvider.avatarMetadataKey],
                        title: assistant.name ?? "NO NAME",
                        subtitle: assistant.description)
                  case .thread(let thread):
                     Text(thread.displayTitle ?? "New chat...")
                        .frame(maxWidth: .infinity, alignment: .leading)
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
                  navigationProvider.selectedItem = item
                  withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                     navigationProvider.isOpen = false
                  }
               }
               .onChange(of: navigationProvider.deletedThreadID) { oldValue, newValue in
                  if let newValue, oldValue != newValue {
                     provider.deleteThreadFromMapStorageWith(threadID: newValue)
                     navigationProvider.deletedThreadID = nil
                  }
               }
//               .onChange(of: navigationProvider.createdThread) { oldValue, newValue in
//                  if let newValue, oldValue != newValue {
//                     provider.addThreadToMapStorage(newValue)
//                     navigationProvider.createdThread = nil
//                  }
//               }
            }
         }
      }
      .foregroundColor(.white)
      .listStyle(.plain)
      .onFirstAppear {
         Task {
            try await provider.updateSideMenu(sections: Set(SideMenuConfigurationProvider.Section.allCases))
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
                  try await provider.updateSideMenu(sections: [.assistants])
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
