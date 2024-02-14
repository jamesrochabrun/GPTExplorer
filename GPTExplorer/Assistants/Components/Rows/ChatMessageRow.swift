//
//  ChatMessageRow.swift
//  GPTExplorer
//
//  Created by James Rochabrun on 11/21/23.
//

import Foundation
import SwiftUI
import SwiftOpenAI

struct ChatMessageRow: View {
   
   @State var isAnimating = false
   @Binding private var runMetadata: ChatMessageDisplayModel.RunMetadata?
   let generator = UISelectionFeedbackGenerator()
   let message: ChatMessageDisplayModel
   
   init(
      message: ChatMessageDisplayModel,
      runMetadata: Binding<ChatMessageDisplayModel.RunMetadata?>? = nil)
   {
      self.message = message
      _runMetadata = runMetadata ?? .constant(.init(runID: "", threadID: ""))
   }

   var body: some View {
      VStack(alignment: .leading, spacing: 8) {
         header
         Group {
            switch message.content {
            case .content(let mediaType):
               contentDisplay(type: mediaType)
            case .toolCall(let runStepToolCall):
               switch runStepToolCall {
               case .codeInterpreterToolCall(let codeInterpreter):
                  codeInterpreterToolCallView(codeInterpreter)
               case .retrieveToolCall:
                  Text("Retrieval")
               case .functionToolCall(let functionToolCall):
                  functionToolCallView(functionToolCall)
               }
            case .loading(let source):
               loadingView(source: source)
            case .error(let error):
               errorView(message: error)
            }
         }
         .padding(.leading, 23)
      }
   }
   
   @ViewBuilder
   func contentDisplay(
      type: ChatMessageDisplayModel.DisplayContent.DisplayMessageType)
      -> some View
   {
      VStack(alignment: .leading, spacing: Sizes.spacingMedium) {
         imagesFrom(urls: type.urls ?? [])
         textMessage(type.text, isFinished: type.isFinished)
      }
      .transition(.opacity)
   }
   
   func codeInterpreterToolCallView(
      _ codeInterpreter: CodeInterpreterToolCall)
      -> some View
   {
      VStack(alignment: .leading) {
         Text("code_interpreter").bold().font(.body) + Text("(\(codeInterpreter.input))").font(.callout)
         ForEach(codeInterpreter.outputs.indices, id: \.self) { index in
            let output = codeInterpreter.outputs[index]
            switch output {
            case .logs(let output):
               HStack {
                  Image(systemName: "arrow.turn.down.right")
                     .foregroundColor(.primary)
                  textMessage(output.logs, isFinished: true) // TODO: When Assistant API supports Stream
               }
            case .images:
               EmptyView()
            }
         }
      }
      .transition(.opacity)
   }
   
   func functionToolCallView(
      _ function: FunctionToolCall)
      -> some View
   {
      Text(function.name).bold().font(.body) + Text("(\(function.arguments))").font(.callout)
   }
   
   @ViewBuilder
   var header: some View {
      switch message.origin {
      case .received(let source):
         switch source {
         case .gpt:
            headerWith("wand.and.stars", title: "ChatGPT")
         case .dalle:
            EmptyView()
         case .asssistant(let assistant):
            switch assistant {
            case .user:
               headerWith("person.circle", title: "You")
            case .assistant(let assistantName):
               headerWith("wand.and.stars", title: assistantName)
            case .toolCall:
               EmptyView()
            }
         }
      case .sent:
         headerWith("person.circle", title: "USER")
      }
   }
   
   @ViewBuilder
   func loadingView(
      source: ChatMessageDisplayModel.DisplayContent.LoadingSource)
      -> some View
   {
      switch source {
      case .dalle:
         HStack {
            Image(systemName: "paintpalette.fill")
               .symbolEffect(.variableColor.dimInactiveLayers, options: .repeating, value: isAnimating)
               .symbolRenderingMode(.multicolor)
            Text("Creating image")
         }
         .onAppear {
            isAnimating = true
         }
      }
   }
   
   func errorView(
      message: String)
      -> some View
   {
      Text(message)
         .padding()
         .font(.custom("Roboto-Regular", size: 16)) // Use the Roboto font
         .background(
            RoundedRectangle(cornerRadius: 20)
               .foregroundColor(.red.opacity(0.7))
         )
         .transition(.opacity)
   }
   
   @ViewBuilder
   func textMessage(
      _ text: String?,
      isFinished: Bool)
      -> some View
   {
      if let text = text {
         if text.isEmpty {
            //LoadingDotsView(prefix: nil)
            CircleBouncingView(animationDuration: 0.5)
               .frame(width: 10, height: 10)
         } else {
            if isFinished {
               Text(text)
                  .font(.body)
            } else {
               let _ = generator.selectionChanged()
               Text(text)
                  .font(.body) + Text(Image(systemName: "circle.fill"))
            }
         }
      } else {
         EmptyView()
      }
   }
   
   func headerWith(
      _ systemImageName: String,
      title: String)
   -> some View
   {
      HStack {
         Image(systemName: systemImageName)
            .resizable()
            .frame(width: 16, height: 16)
         Text(title)
            .font(.caption2)
         Spacer()
         if 
            let runMetadata = message.runMetadata,
               !runMetadata.isEmpty
         {
            IconButton(iconName: "ellipsis") {
               self.runMetadata = runMetadata
            }
            .iconButtonStyle(.tertiary)
         }
      }
      .foregroundColor(.gray.opacity(0.9))
   }

   func imagesFrom(
      urls: [URL])
      -> some View
   {
      ScrollView(.horizontal, showsIndicators: false) {
         HStack(spacing: 8) {
            ForEach(urls, id: \.self) { url in
               URLImageView(url: url)
                  .urlImageViewStyle(.assistantRowRoundedRectangle)
            }
         }
      }
   }
}

#Preview {
   
   return ScrollView {
      VStack(spacing: 20) {
         ChatMessageRow(message: .init(content: .content(.init(text: "What is the capital of Peru? and what is the population", isFinished: true)), origin: .sent))
         Divider()
         ChatMessageRow(message: .init(content: .content(.init(text: "Lima, an its 28 million habitants.", isFinished: true)), origin: .received(.gpt), runMetadata: .init(runID: "dddddd", threadID: "dddddd")))
         Divider()
         ChatMessageRow(
            message: .init(
               content: .content(
                  .init(
                     text: "The image you requested is ready 🐱",
                     urls: [URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/d/dd/Gfp-wisconsin-madison-the-nature-boardwalk.jpg/2560px-Gfp-wisconsin-madison-the-nature-boardwalk.jpg")!], isFinished: true)),
               origin: .received(.dalle),
               runMetadata: nil))
         Divider()
         ChatMessageRow(message: .init(content: .content(.init(text: "", isFinished: true)), origin: .received(.gpt)))
         Divider()
         ChatMessageRow(message: .init(content: .loading(.dalle), origin: .received(.gpt)))
         
      }
   }
   .padding()
}
