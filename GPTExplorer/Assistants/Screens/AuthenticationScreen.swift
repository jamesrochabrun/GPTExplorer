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
   
   var body: some View {
         NavigationStack {
            ZStack {
               shaderBackground
               VStack {
                  Spacer()
                  Text("GPT-Explorer")
                     .foregroundColor(.white)
                     .font(.largeTitle)
                     .bold()
                     .fontWidth(.expanded)
                     .padding(.bottom)
                  VStack(spacing: 24) {
                     CustomTextField(text: $apiKey, placeholder: "Enter API Key")
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
                              .foregroundColor(apiKey.isEmpty ? ThemeColor.actionBackgroundDisabled : ThemeColor.brandColor))
                  }
                  .disabled(apiKey.isEmpty)
                  Spacer()
                  Group {
                     Text("If you don't have a valid API KEY yet, you can visit ") + Text("[this link](https://platform.openai.com/account/api-keys)") + Text(" to get started.")
                  }
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



/// TODO: Make possible to pass also URL tools and files ids to the configure
/// also be able to use text to speech for this
/// Lastly be able to add the text to speech messages in to the chat list.
/// Consider making an initial user message with the parameters but dont; show that message in the UI.
