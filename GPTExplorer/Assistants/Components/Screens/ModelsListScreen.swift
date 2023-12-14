//
//  ModelsPicker.swift
//  GPTExplorer
//
//  Created by James Rochabrun on 12/12/23.
//

import SwiftUI
import SwiftOpenAI

extension ModelObject: Identifiable {}

struct GroupedModels {
   let groupName: String
   let models: [ModelObject]
}

struct ModelsListScreen: View {
   
   let service: OpenAIService
   @Binding var selectedModel: String
   
   @State private var groupedModels: [GroupedModels] = []
   @State private var isLoading = true
   @State private var errorMessage: String?
   
   var body: some View {
      Group {
         if isLoading {
            Text("Loading...")
         } else if let errorMessage = errorMessage {
            Text("Error: \(errorMessage)")
         } else {
            List {
               ForEach(groupedModels, id: \.groupName) { group in
                  Section(header: Text(group.groupName)) {
                     ForEach(group.models) { model in
                        Text(model.id)
                           .onTapGesture {
                              self.selectedModel = model.id
                           }
                     }
                  }
               }
            }
         }
      }
      .onFirstAppear {
         loadModels()
      }
   }
   
   private func loadModels() {
      Task {
         do {
            let list = try await service.listModels()
            groupedModels = organizeModels(list.data)
            isLoading = false
         } catch {
            errorMessage = error.localizedDescription
            isLoading = false
         }
      }
   }
   
   private func organizeModels(
      _ models: [ModelObject])
      -> [GroupedModels]
   {
       var groupedModels: [GroupedModels] = []

       let fineTuning = models.filter { $0.id.hasPrefix("ft:") }
       let assistantsRetrieval = models.filter { $0.id == "gpt-3.5-turbo-1106" || $0.id == "gpt-4-1106-preview" }
       let gpt4 = models.filter { $0.id.hasPrefix("gpt-4") && !$0.id.contains("gpt-4-1106-preview") }
       let gpt3 = models.filter { $0.id.hasPrefix("gpt-3") && !$0.id.contains("gpt-3.5-turbo-1106") }
       let dalle = models.filter { $0.id.hasPrefix("dall") }
       let vision = models.filter { $0.id == "gpt-4-vision-preview" }
       let whisper = models.filter { $0.id.hasPrefix("whisper") }
       let tts = models.filter { $0.id.hasPrefix("tts") }

       let usedIds = Set(fineTuning.map { $0.id } +
                         assistantsRetrieval.map { $0.id } +
                         gpt4.map { $0.id } +
                         gpt3.map { $0.id } +
                         dalle.map { $0.id } +
                         vision.map { $0.id } +
                         whisper.map { $0.id } +
                         tts.map { $0.id })

       let otherModels = models.filter { !usedIds.contains($0.id) }

       groupedModels.append(GroupedModels(groupName: "Fine Tuning", models: fineTuning))
       groupedModels.append(GroupedModels(groupName: "Assistants Retrieval", models: assistantsRetrieval))
       groupedModels.append(GroupedModels(groupName: "GPT 4", models: gpt4))
       groupedModels.append(GroupedModels(groupName: "GPT 3", models: gpt3))
       groupedModels.append(GroupedModels(groupName: "Dall-e", models: dalle))
       groupedModels.append(GroupedModels(groupName: "Vision", models: vision))
       groupedModels.append(GroupedModels(groupName: "Whisper", models: whisper))
       groupedModels.append(GroupedModels(groupName: "TTS", models: tts))
       groupedModels.append(GroupedModels(groupName: "Other", models: otherModels))

       return groupedModels
   }
}
