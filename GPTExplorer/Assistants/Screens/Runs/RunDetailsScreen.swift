//
//  RunDetailsScreen.swift
//  GPTExplorer
//
//  Created by James Rochabrun on 12/11/23.
//

import SwiftUI
import SwiftOpenAI

struct RunDetailsScreen: View {
   
   init(
      runsProvider: RunsProvider,
      runMetadata: ChatMessageDisplayModel.RunMetadata)
   {
      self.runsProvider = runsProvider
      self.runMetadata = runMetadata
   }
   
   var metadata: some View {
      VStack(alignment: .leading) {
         VStack(alignment: .leading) {
            Text("Thread:")
               .bold()
               .font(.body)
            Text("\(runMetadata.threadID)")
               .fontWeight(.semibold)
               .foregroundColor(.secondary)
         }
         VStack(alignment: .leading) {
            Text("Run:")
               .bold()
               .font(.body)
            Text("\(runMetadata.runID)")
               .fontWeight(.semibold)
               .foregroundColor(.secondary)
         }
         Divider()
      }
      .padding(Padding.rowHorizontal)
   }
   
   var body: some View {
      VStack {
         metadata
         List(runsProvider.runSteps) { runStep in
            Group {
               if let runStepAsJson = runStep.toJSONString() {
                  Text(runStepAsJson)
                     .padding()
                     .fontWeight(.semibold)
                     .font(.caption)
                     .background(RoundedRectangle(cornerRadius: 10)
                        .fill(ThemeColor.systemBackgroundColor)
                                     .shadow(radius: 4))
               } else {
                  Text("Unable to convert Run step in to Json")
               }
            }
            .listRowSeparator(.hidden)
         }
         .padding()
         .listStyle(.plain)
      }
      .padding(.top, 24)
      .onFirstAppear {
         Task {
            try await runsProvider.getRunSteps(threadID: runMetadata.threadID, runID: runMetadata.runID)
         }
      }
   }
   
   @State private var runsProvider: RunsProvider
   let runMetadata: ChatMessageDisplayModel.RunMetadata
}

#Preview {
   RunDetailsScreen(runsProvider: .init(service: OpenAIServiceFactory.service(apiKey: "")), runMetadata: .init(runID: "run_LMl49bJhE5OiDH1cemxj9P7M", threadID: "thread_yCSZ7aTNLfuQj7z04jtmd0qf"))
}

private struct Mock {

   static func steps(from json: String = mock) -> [RunStepObject] {
      let data = json.data(using: .utf8)!
      let decoder = JSONDecoder()
      return try! decoder.decode([RunStepObject].self, from: data)
   }
}

private let mock = """
[
    {
        "assistant_id": "asst_DY7KY2XxRbL2LOyBZWlWRbHI",
        "cancelled_at": null,
        "completed_at": 1702409578,
        "created_at": 1702409578,
        "expires_at": null,
        "failed_at": null,
        "id": "step_n2aiWQIZtA3nZbfDnKeiQata",
        "last_error": null,
        "object": "thread.run.step",
        "run_id": "run_VlaHPg6OOx1lefChOxycnD6O",
        "status": "completed",
        "step_details": {
            "message_creation": {
                "message_id": "msg_m52k6qgeNQnCsdKokik262BN"
            },
            "type": "message_creation"
        },
        "thread_id": "thread_kFplwU4zWFXTqiybIUA5qLHk",
        "type": "message_creation"
    },
    {
        "assistant_id": "asst_DY7KY2XxRbL2LOyBZWlWRbHI",
        "cancelled_at": null,
        "completed_at": 1702409578,
        "created_at": 1702409574,
        "expires_at": null,
        "failed_at": null,
        "id": "step_BVYxuwLIJJybGZWBIqGQCo3p",
        "last_error": null,
        "object": "thread.run.step",
        "run_id": "run_VlaHPg6OOx1lefChOxycnD6O",
        "status": "completed",
        "step_details": {
            "tool_calls": [
                {
                    "code_interpreter": {
                        "input": "# The code execution state has been reset which requires re-importing the math module.\nimport math\n\n# Calculate the square root of 1456\nsqrt_1456 = math.sqrt(1456)\nsqrt_1456",
                        "outputs": [
                            {
                                "logs": "38.157568056677825",
                                "type": "logs"
                            }
                        ]
                    },
                    "id": "call_XYMUKoVeGmXDcpJUj9G2TaFk",
                    "type": "code_interpreter"
                }
            ],
            "type": "tool_calls"
        },
        "thread_id": "thread_kFplwU4zWFXTqiybIUA5qLHk",
        "type": "tool_calls"
    },
    {
        "assistant_id": "asst_DY7KY2XxRbL2LOyBZWlWRbHI",
        "cancelled_at": null,
        "completed_at": 1702409574,
        "created_at": 1702409570,
        "expires_at": null,
        "failed_at": null,
        "id": "step_8OdJcxwXJJ5UVNv3KUtYMPTD",
        "last_error": null,
        "object": "thread.run.step",
        "run_id": "run_VlaHPg6OOx1lefChOxycnD6O",
        "status": "completed",
        "step_details": {
            "tool_calls": [
                {
                    "code_interpreter": {
                        "input": "# Calculate the square root of 1456 math.sqrt(1456)",
                        "outputs": []
                    },
                    "id": "call_DgbAnbS6HGhTEwhPbFNwurZO",
                    "type": "code_interpreter"
                }
            ],
            "type": "tool_calls"
        },
        "thread_id": "thread_kFplwU4zWFXTqiybIUA5qLHk",
        "type": "tool_calls"
    }
]
"""
