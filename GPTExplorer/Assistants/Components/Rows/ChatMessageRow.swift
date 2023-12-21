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

   let message: ChatMessageDisplayModel
   @Binding private var runMetadata: ChatMessageDisplayModel.RunMetadata?
   
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
            case .codeInterpreter(let codeInterpreter):
               codeInterpreterToolCall(codeInterpreter)
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
         textMessage(type.text)
      }
      .transition(.opacity)
   }
   
   func codeInterpreterToolCall(
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
                  textMessage(output.logs)
               }
            case .images:
               EmptyView()
            }
         }
      }
      .transition(.opacity)
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
            case .codeInterpreter:
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
         .font(.callout)
         .background(
            RoundedRectangle(cornerRadius: 20)
               .foregroundColor(.red.opacity(0.7))
         )
         .transition(.opacity)
   }

   @ViewBuilder
   func textMessage(
      _ text: String?)
      -> some View
   {
      if let text = text {
         if text.isEmpty {
            //LoadingDotsView(prefix: nil)
            CircleBouncingView(animationDuration: 0.5)
               .frame(width: 10, height: 10)
         } else {
            Text(text)
               .font(.body)
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
         ChatMessageRow(message: .init(content: .content(.init(text: "What is the capital of Peru? and what is the population")), origin: .sent))
         Divider()
         ChatMessageRow(message: .init(content: .content(.init(text: "Lima, an its 28 million habitants.")), origin: .received(.gpt), runMetadata: .init(runID: "dddddd", threadID: "dddddd")))
         Divider()
         ChatMessageRow(
            message: .init(
               content: .content(.init(text: "The image you requested is ready 🐱",
                                       urls: [URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/d/dd/Gfp-wisconsin-madison-the-nature-boardwalk.jpg/2560px-Gfp-wisconsin-madison-the-nature-boardwalk.jpg")!])),
               origin: .received(.dalle),
               runMetadata: nil))
         Divider()
         ChatMessageRow(message: .init(content: .content(.init(text: "")), origin: .received(.gpt)))
         Divider()
         ChatMessageRow(message: .init(content: .loading(.dalle), origin: .received(.gpt)))

      }
   }
   .padding()
}
