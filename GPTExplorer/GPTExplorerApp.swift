//
//  GPTExplorerApp.swift
//  GPTExplorer
//
//  Created by James Rochabrun on 11/20/23.
//

import SwiftUI
import SwiftData
import SwiftOpenAI

@main
struct GPTExplorerApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

   @State private var apiKey = "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"
   @State private var organizationIdentifier = ""
   @State private var localOrganizationID: String? = nil

    var body: some Scene {
        WindowGroup {
           AuthenticationScreen()
        }
    }
}
