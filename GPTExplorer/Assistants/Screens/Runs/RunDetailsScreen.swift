//
//  RunDetailsScreen.swift
//  GPTExplorer
//
//  Created by James Rochabrun on 12/11/23.
//

import SwiftUI
import SwiftOpenAI
//import Markdown

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
      .border(.red)
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
                        .fill(Color(.systemBackground))
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


private let mock = """
```json
{
    "assistant_id" = "asst_DY7KY2XxRbL2LOyBZWlWRbHI";
    "cancelled_at" = "<null>";
    "completed_at" = 1702370669;
    "created_at" = 1702370668;
    "expires_at" = "<null>";
    "failed_at" = "<null>";
    id = "step_FFGZgmVsFmXGNsLucOlHZvEe";
    "last_error" = "<null>";
    object = "thread.run.step";
    "run_id" = "run_biuKzN1nY7iyosf0WGGrEQkr";
    status = completed;
    "step_details" =     {
        "message_creation" =         {
            "message_id" = "msg_oSbgkqQDwiJOKRZbP7XQL1os";
        };
        type = "message_creation";
    };
    "thread_id" = "thread_kFplwU4zWFXTqiybIUA5qLHk";
    type = "message_creation";
},
{
    "assistant_id" = "asst_DY7KY2XxRbL2LOyBZWlWRbHI";
    "cancelled_at" = "<null>";
    "completed_at" = 1702370668;
    "created_at" = 1702370663;
    "expires_at" = "<null>";
    "failed_at" = "<null>";
    id = "step_X02DdgvKUHZUj3vAwWPfD6Kb";
    "last_error" = "<null>";
    object = "thread.run.step";
    "run_id" = "run_biuKzN1nY7iyosf0WGGrEQkr";
    status = completed;
    "step_details" =     {
        "tool_calls" =         (
                        {
                "code_interpreter" =                 {
                    input = "# Re-import the math module and calculate the square root again\nimport math\n\n# Calculate the square root of 555555\nmath.sqrt(555555)";
                    outputs =                     (
                                                {
                            logs = "745.3556198218405";
                            type = logs;
                        }
                    );
                };
                id = "call_1p97Bty8eVA8VMusLiysrlD3";
                type = "code_interpreter";
            }
        );
        type = "tool_calls";
    };
    "thread_id" = "thread_kFplwU4zWFXTqiybIUA5qLHk";
    type = "tool_calls";
},
{
    "assistant_id" = "asst_DY7KY2XxRbL2LOyBZWlWRbHI";
    "cancelled_at" = "<null>";
    "completed_at" = 1702370663;
    "created_at" = 1702370659;
    "expires_at" = "<null>";
    "failed_at" = "<null>";
    id = "step_SlnQM3HcUVS2JbWgOgjeiEoI";
    "last_error" = "<null>";
    object = "thread.run.step";
    "run_id" = "run_biuKzN1nY7iyosf0WGGrEQkr";
    status = completed;
    "step_details" =     {
        "tool_calls" =         (
                        {
                "code_interpreter" =                 {
                    input = "# Calculate the square root of 555555\nmath.sqrt(555555)";
                    outputs =                     (
                    );
                };
                id = "call_tjT4gS7vkEPkrmkCqOvbisRs";
                type = "code_interpreter";
            }
        );
        type = "tool_calls";
    };
    "thread_id" = "thread_kFplwU4zWFXTqiybIUA5qLHk";
    type = "tool_calls";
}
```
"""
