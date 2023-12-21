//
//  EmptyAssistantPlaceholderView.swift
//  GPTExplorer
//
//  Created by James Rochabrun on 11/21/23.
//

import Foundation
import SwiftUI

// MARK: EmptyAssistantPlaceholderView

struct EmptyAssistantPlaceholderView<PlaceHolder: View>: View {
   
   let imageURL: String?
   let placeholder: PlaceHolder
   let title: String
   let subtitle: String?
   
   init(
      imageURL: String?,
      title: String,
      subtitle: String?,
      @ViewBuilder placeholder: () -> PlaceHolder)
   {
      self.imageURL = imageURL
      self.title = title
      self.subtitle = subtitle
      self.placeholder = placeholder()
   }
   
   var body: some View {
      VStack(spacing: Sizes.spacingExtraLarge) {
         if let imageURL, let urlDisplay = URL(string: imageURL) {
            URLImageView(url: urlDisplay)
               .urlImageViewStyle(.assistantEmptyView)
         } else {
            Circle()
               .stroke(.primary, style: StrokeStyle(lineWidth: 2))
               .frame(width: 60, height: 60)
               .overlay(
                  placeholder
               )
         }
         Text(title)
            .font(.title2)
            .bold()
         if let subtitle {
            Text(subtitle)
         }
      }
      .padding(.horizontal, Sizes.spacingExtraLarge)
   }
}

// MARK: Mock+Preview

#Preview("All") {
   VStack {
      EmptyAssistantPlaceholderView(
         imageURL: urlImageViewMockURL.absoluteString + "ll",
         title: "Some Assistant",
         subtitle: "The math assistant description") {
            Image(systemName: "oval.bottomhalf.filled")
         }
      EmptyAssistantPlaceholderView(
         imageURL: nil,
         title: "Some Assistant",
         subtitle: "The math assistant description") {
            Image(systemName: "oval.bottomhalf.filled")
         }
      EmptyAssistantPlaceholderView(
         imageURL: urlImageViewMockURL.absoluteString, 
         title: "Some Assistant",
         subtitle: "The math assistant description") {
            Image(systemName: "oval.bottomhalf.filled")
         }
   }
}

#Preview("Error") {
   @State var toggle: Bool = false
   return VStack {
      EmptyAssistantPlaceholderView(
         imageURL: urlImageViewMockURL.absoluteString + "ll",
         title: toggle ? "fuc" : "Some Assistant",
         subtitle: "The math assistant description") {
            Image(systemName: "exclamationmark.triangle.fill")
         }
   }
}

#Preview("Empty url")  {
   EmptyAssistantPlaceholderView(
      imageURL: nil,
      title: "Some Assistant",
      subtitle: "The math assistant description") {
         Image(systemName: "oval.bottomhalf.filled")
      }
}

#Preview("Valid url")  {
   EmptyAssistantPlaceholderView(
      imageURL: urlImageViewMockURL.absoluteString
      , title: "Some Assistant",
      subtitle: "The math assistant description") {
        Image(systemName: "oval.bottomhalf.filled")
            .symbolEffect(.pulse, options: .repeating, value: true)
      }
}
