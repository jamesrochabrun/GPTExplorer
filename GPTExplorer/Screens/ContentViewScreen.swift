//
//  ContentViewScreen.swift
//  GPTExplorer
//
//  Created by James Rochabrun on 11/26/23.
//

import SwiftUI
import SwiftOpenAI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

struct ContentViewScreen: View {
   
   let service: OpenAIService
   @State private var sideMenuConfigurationProvider: SideMenuConfigurationProvider
   @State private var navigationProvider: NavigationProvider

   init(
      service: OpenAIService,
      sideMenuConfigurationProvider: SideMenuConfigurationProvider)
   {
      self.service = service
      self._navigationProvider = State(initialValue: sideMenuConfigurationProvider.navigationProvider)
      self._sideMenuConfigurationProvider = State(initialValue: sideMenuConfigurationProvider)
   }
   
   var mainBackground: some View {
      ThemeColor.brandSecondaryColor
     // navigationProvider.isOpen ? ThemeColor.brandSecondaryColor : Color(.systemBackground)
   }
   
   var body: some View {
      GeometryReader { proxy in
         let sideMenuWidth = proxy.size.width * 0.7
         ZStack(alignment: .topLeading) {
            
            mainBackground
               .ignoresSafeArea()
            
            SideMenuScreen(service: service, sideMenuConfigurationProvider: sideMenuConfigurationProvider)
               .foregroundColor(.primary)
               .background(Color.clear)
               .frame(maxWidth: sideMenuWidth, maxHeight: .infinity)
   //            .mask(RoundedRectangle(cornerRadius: 30, style: .continuous))
               .frame(maxWidth: .infinity, alignment: .leading)
               .opacity(navigationProvider.isOpen ? 1 : 0)
               .offset(x: navigationProvider.isOpen ? 0 : -sideMenuWidth)
               .rotation3DEffect(.degrees(navigationProvider.isOpen ? 0 : 30), axis: (x: 0.0, y: 1.0, z: 0.0))
            mainContent
   //            .shadow(color: .gray, radius: 10, x: 5, y: 5)
               .mask(RoundedRectangle(cornerRadius: navigationProvider.isOpen ? 30 : 0, style: .continuous))
               .rotation3DEffect(.degrees(navigationProvider.isOpen ? 30 : 0), axis: (x: 0.0, y: -1.0, z: 0.0))
               .offset(x: navigationProvider.isOpen ? sideMenuWidth : 0)
               .scaleEffect(navigationProvider.isOpen ? 0.9 : 1)
               .ignoresSafeArea(.container)
            
            IconButton(iconName: navigationProvider.isOpen ? "xmark" : "list.bullet") {
               withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                  navigationProvider.isOpen.toggle()
               }
            }
            .iconButtonStyle(navigationProvider.isOpen ? .plainReversed : .plain)
            .padding(.horizontal)
            .offset(x: navigationProvider.isOpen ? sideMenuWidth - 30.0 : 0)
            .offset(y: navigationProvider.isOpen ? 20 : 0)
         }
         .navigationBarBackButtonHidden(true)
         .sensoryFeedback(.impact(weight: .medium, intensity: navigationProvider.isOpen ? 1.0 : 0.7), trigger: navigationProvider.isOpen)
      }

   }
   
   var chatBackgroundColor: Color {
       #if os(iOS)
       return Color(UIColor.systemBackground)
       #else
       return Color(NSColor.windowBackgroundColor)
       #endif
   }
   
   @ViewBuilder
   var mainContent: some View {
      switch navigationProvider.changeToSelectedItem.selectedItem {
      case .thread, .assistant:
         let threadScreen = ThreadScreen(
            service: service,
            provider: sideMenuConfigurationProvider,
            item: $navigationProvider.changeToSelectedItem.selectedItem )
         .id(navigationProvider.changeToSelectedItem.selectedItem.id)
         if navigationProvider.changeToSelectedItem.animated {
            threadScreen.transition(.opacity) // Example transition
         } else {
            threadScreen
         }
      case .chat:
         let chatScreen = Text("CHAT COMING SOON 🤖")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(chatBackgroundColor)
            .transition(.opacity) // Example transition
            .id(navigationProvider.changeToSelectedItem.selectedItem.id)
         if navigationProvider.changeToSelectedItem.animated {
            chatScreen.transition(.opacity) // Example transition
         } else {
            chatScreen
         }
      default:
         EmptyView()
      }
   }
}
