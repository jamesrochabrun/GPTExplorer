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
   
   @State private var isOpen = false
   
   var body: some View {
      ZStack(alignment: .topLeading) {
         
         ThemeColor.backggroundColor
            .ignoresSafeArea()
         leadingContent
            .foregroundColor(.primary)
            .background(Color.clear)
            .frame(maxWidth: 288, maxHeight: .infinity)
//            .mask(RoundedRectangle(cornerRadius: 30, style: .continuous))
            .frame(maxWidth: .infinity, alignment: .leading)
            .opacity(isOpen ? 1 : 0)
            .offset(x: isOpen ? 0 : -300)
            .rotation3DEffect(.degrees(isOpen ? 0 : 30), axis: (x: 0.0, y: 1.0, z: 0.0))
//         TabView(selection: $navigationProvider.selectedItem) {
//            ThreadScreen(service: service, item: $navigationProvider.selectedItem)
//               .id(navigationProvider.selectedItem.id)
//         }
         mainContent
            .foregroundColor(.primary)
            .background(.white)
            .border(.white)
//            .shadow(color: .gray, radius: 10, x: 5, y: 5)
            .mask(RoundedRectangle(cornerRadius: 30, style: .continuous))
            .rotation3DEffect(.degrees(isOpen ? 30 : 0), axis: (x: 0.0, y: -1.0, z: 0.0))
            .offset(x: isOpen ? 265 : 0)
            .scaleEffect(isOpen ? 0.9 : 1)
            .ignoresSafeArea()
         
         IconButton(iconName: isOpen ? "xmark.circle" : "list.bullet") {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
               isOpen.toggle()
            }
         }
         .iconButtonStyle(.plain)
         .padding(.horizontal)
         .offset(x: isOpen ? 250 : 0)
      }
      .navigationBarBackButtonHidden(true)
   }
   
   @ViewBuilder
   var mainContent: some View {
      switch navigationProvider.selectedItem {
      case .thread, .assistant:
         ThreadScreen(service: service, item: $navigationProvider.selectedItem)
            .id(navigationProvider.selectedItem.id)// Replace with actual view
      case .none:
         EmptyView()
      }
   }
}


struct FOO: View {
   
   let item: SideMenuItem
   
   var body: some View {
      Text("id \(item.id)")
         .frame(maxWidth: .infinity, maxHeight: .infinity)

   }
}
