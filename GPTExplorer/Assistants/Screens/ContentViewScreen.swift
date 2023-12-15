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
      _navigationProvider = State(initialValue: sideMenuConfigurationProvider.navigationProvider)
      _sideMenuConfigurationProvider = State(initialValue: sideMenuConfigurationProvider)
   }
   
   var mainBackground: some View {
      navigationProvider.isOpen ? Color(hex: "1f1f1f") : Color(.systemBackground)
   }
   
   var body: some View {
      GeometryReader { proxy in
         let sideMenuWidth = proxy.size.width * 0.7
         ZStack(alignment: .topLeading) {
            mainBackground
               .ignoresSafeArea()
            VStack(alignment: .leading) {
               customBackButton
               SideMenuScreen(service: service, sideMenuConfigurationProvider: sideMenuConfigurationProvider)
                  .foregroundColor(.primary)
                  .background(Color.clear)
                  .frame(maxWidth: sideMenuWidth, maxHeight: .infinity)
                  .frame(maxWidth: .infinity, alignment: .leading)
                  .opacity(navigationProvider.isOpen ? 1 : 0)
                  .offset(x: navigationProvider.isOpen ? 0 : -sideMenuWidth)
                  .rotation3DEffect(.degrees(navigationProvider.isOpen ? 0 : 30), axis: (x: 0.0, y: 1.0, z: 0.0))
            }

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
         .gesture(
            DragGesture()
               .onEnded {
                  if $0.translation.width < -100 {
                     // Swipe left: close menu
                     withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        navigationProvider.isOpen = false
                     }
                  }
                  if $0.translation.width > 100 {
                     // Swipe right: open menu
                     withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        navigationProvider.isOpen = true
                     }
                  }
               }
         )
      }
   }
   
   var customBackButton: some View {
      Button(action: {
         self.presentationMode.wrappedValue.dismiss()
      }) {
         Image(systemName: "arrow.left")
            .foregroundColor(.white)
            .padding(.leading, Sizes.spacingExtraLarge)
      }
   }
   
   @Environment(\.presentationMode) private var presentationMode

   
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
         let chatScreen = ChatScreen(service: service)
            .id(navigationProvider.changeToSelectedItem.selectedItem.id)
         if navigationProvider.changeToSelectedItem.animated {
            chatScreen
              .transition(.opacity) // Example transition, this wont work unless the zstack that contains this views.
         } else {
            chatScreen
         }
      default:
         EmptyView()
      }
   }
}
