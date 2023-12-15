//
//  AuthenticationScreen.swift
//  GPTExplorer
//
//  Created by James Rochabrun on 11/20/23.
//

import SwiftUI
import SwiftOpenAI

// MARK: AuthenticationScreen

struct AuthenticationScreen: View {
   
   @State private var apiKey = ""
   @State private var organizationIdentifier = ""
   @State private var localOrganizationID: String? = nil
   @State private var navigationProvider: NavigationProvider = .init()
   private let startDate = Date()

   @ViewBuilder
   var destination: some View {
      let service = OpenAIServiceFactory.service(
         apiKey: apiKey,
         organizationID:
            localOrganizationID)
      ContentViewScreen(
         service: service,
         sideMenuConfigurationProvider: SideMenuConfigurationProvider(service: service))
   }
   
   var shaderBackground: some View {
      TimelineView(.animation) { context in
         Rectangle()
            .colorEffect(ShaderLibrary.circleLoader(.boundingRect, .float(startDate.timeIntervalSinceNow)), isEnabled: true)
            .ignoresSafeArea()
      }
   }
   
   var mainContent: some View {
      VStack {
         Text("GPT-Explorer")
            .shadow(color: ThemeColor.shadowColor, radius: 7)
            .foregroundColor(.white)
            .font(.largeTitle)
            .fontWidth(.expanded)
            .fontWeight(.black)
            .padding(.bottom)
         VStack(spacing: 24) {
            CustomTextField(text: $apiKey, placeholder: "Enter API Key")
               .customTextFieldStyle(.horizontal)
            CustomTextField(text: $organizationIdentifier, placeholder: "Enter Organization ID (Optional)")
               .onChange(of: organizationIdentifier) { _, newValue in
                  if !newValue.isEmpty {
                     localOrganizationID = newValue
                  }
               }
         }
         .padding()
         NavigationLink(destination: destination)
         {
            Text("Continue")
               .padding()
               .padding(.horizontal, 48)
               .foregroundColor(apiKey.isEmpty ? ThemeColor.actionForegroundDisabled : .white)
               .background(
                  Capsule()
                     .foregroundColor(apiKey.isEmpty ? ThemeColor.actionBackgroundDisabled : ThemeColor.rowSelectionColor))
              // .shadow(color: ThemeColor.shadowColor, radius: 7)
         }
         .disabled(apiKey.isEmpty)
      }
      .padding(.vertical)
   }
   
   var body: some View {
         NavigationStack {
            ZStack {
               shaderBackground
               VStack {
                  Spacer()
                  mainContent
                     .padding()
                     .background(.ultraThinMaterial)
                     .cornerRadius(20)
                  Spacer()
                  Group {
                     Text("If you don't have a valid API KEY yet, you can visit ") + Text("[this link](https://platform.openai.com/account/api-keys)") + Text(" to get started.")
                     
                  }
                  .tint(ThemeColor.rowSelectionColor)
                  .padding()
                  .background(.ultraThinMaterial)
                  .cornerRadius(10)
                  .font(.caption)
               }
               .padding()
            }
   //         .navigationTitle("Enter OpenAI API KEY")
         }
   }
}

// MARK: Mock+Preview

#Preview {
   AuthenticationScreen()
}
