//
//  AuthenticationScreen.swift
//  GPTExplorer
//
//  Created by James Rochabrun on 11/20/23.
//

import SwiftUI
import SwiftOpenAI

extension Color {
   static func random() -> Color {
      return Color(
         red: Double.random(in: 0...1),
         green: Double.random(in: 0...1),
         blue: Double.random(in: 0...1),
         opacity: 1.0
      )
   }
}

// MARK: AuthenticationScreen

struct AuthenticationScreen: View {
   
   @State private var apiKey = ""
   @State private var organizationIdentifier = ""
   @State private var localOrganizationID: String? = nil
   @State private var navigationProvider: NavigationProvider = .init()

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
   
   var body: some View {
      NavigationStack {
         VStack {
            Spacer()
            VStack(spacing: 24) {
               TextField("Enter API Key", text: $apiKey)
               TextField("Enter Organization ID (Optional)", text: $organizationIdentifier)
                  .onChange(of: organizationIdentifier) { _, newValue in
                     if !newValue.isEmpty {
                        localOrganizationID = newValue
                     }
                  }
            }
            .padding()
            .textFieldStyle(.roundedBorder)
            NavigationLink(destination: destination)
            {
               Text("Continue")
                  .padding()
                  .padding(.horizontal, 48)
                  .foregroundColor(.white)
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
         .navigationTitle("Enter OpenAI API KEY")
      }
   }
}

// MARK: Mock+Preview

#Preview {
   AuthenticationScreen()
}

