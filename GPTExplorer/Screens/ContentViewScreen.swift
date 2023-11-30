//
//  ContentViewScreen.swift
//  GPTExplorer
//
//  Created by James Rochabrun on 11/26/23.
//

import SwiftUI
import SwiftOpenAI

struct ContentViewScreen<LeadingContent: View>: View {
   
   let leadingContent: LeadingContent
   let service: OpenAIService
   @State private var navigationProvider: NavigationProvider
   
   init(
      service: OpenAIService,
      navigationProvider: NavigationProvider,
      @ViewBuilder leadingContent: () -> LeadingContent)
   {
      self.service = service
      self.leadingContent = leadingContent()
      self._navigationProvider = State(initialValue: navigationProvider)
   }
   
   var body: some View {
      ZStack(alignment: .topLeading) {
         
         ThemeColor.backgroundColor
            .ignoresSafeArea()
         leadingContent
            .foregroundColor(.primary)
            .background(Color.clear)
            .frame(maxWidth: 288, maxHeight: .infinity)
//            .mask(RoundedRectangle(cornerRadius: 30, style: .continuous))
            .frame(maxWidth: .infinity, alignment: .leading)
            .opacity(navigationProvider.isOpen ? 1 : 0)
            .offset(x: navigationProvider.isOpen ? 0 : -300)
            .rotation3DEffect(.degrees(navigationProvider.isOpen ? 0 : 30), axis: (x: 0.0, y: 1.0, z: 0.0))
//         TabView(selection: $navigationProvider.selectedItem) {
//            ThreadScreen(service: service, item: $navigationProvider.selectedItem)
//               .id(navigationProvider.selectedItem.id)
//         }
         
         mainContent
            .foregroundColor(.primary)
            .background(.white)
//            .shadow(color: .gray, radius: 10, x: 5, y: 5)
            .mask(RoundedRectangle(cornerRadius: navigationProvider.isOpen ? 30 : 0, style: .continuous))
            .rotation3DEffect(.degrees(navigationProvider.isOpen ? 30 : 0), axis: (x: 0.0, y: -1.0, z: 0.0))
            .offset(x: navigationProvider.isOpen ? 265 : 0)
            .scaleEffect(navigationProvider.isOpen ? 0.9 : 1)
            .ignoresSafeArea(.container)
         
         IconButton(iconName: navigationProvider.isOpen ? "xmark" : "list.bullet") {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
               navigationProvider.isOpen.toggle()
            }
         }
         .iconButtonStyle(navigationProvider.isOpen ? .plainReversed : .plain)
         .padding(.horizontal)
         .offset(x: navigationProvider.isOpen ? 228 : 0)
         .offset(y: navigationProvider.isOpen ? 20 : 0)
      }
      .navigationBarBackButtonHidden(true)
      .sensoryFeedback(.success, trigger: navigationProvider.isOpen)

   }
   
   @ViewBuilder
   var mainContent: some View {
      switch navigationProvider.selectedItem {
      case .thread, .assistant:
         ThreadScreen(
            service: service,
            item: $navigationProvider.selectedItem,
            didDeleteThread: { 
            navigationProvider.selectedItem = .none
         })
            .id(navigationProvider.selectedItem.id)// Replace with actual view
      case .none:
         Text("CHAT COMING SOON 🤖")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
      }
   }
}
