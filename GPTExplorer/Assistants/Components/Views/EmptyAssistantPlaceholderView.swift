//
//  EmptyAssistantPlaceholderView.swift
//  GPTExplorer
//
//  Created by James Rochabrun on 11/21/23.
//

import Foundation
import SwiftUI

// MARK: EmptyAssistantPlaceholderView

struct EmptyAssistantPlaceholderView: View {
   
   let imageURL: String?
   let placeholder: Image?
   let title: String
   let subtitle: String?
   
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
      EmptyAssistantPlaceholderView(imageURL: urlImageViewMockURL.absoluteString + "ll", placeholder: nil, title: "Some Assistant", subtitle: "The math assistant description")
      EmptyAssistantPlaceholderView(imageURL: nil, placeholder: Image(systemName: "oval.bottomhalf.filled"), title: "Some Assistant", subtitle: "The math assistant description")
      EmptyAssistantPlaceholderView(imageURL: urlImageViewMockURL.absoluteString, placeholder: Image(systemName: "oval.bottomhalf.filled"), title: "Some Assistant", subtitle: "The math assistant description")
   }
}

#Preview("Error") {
   VStack {
      EmptyAssistantPlaceholderView(imageURL: urlImageViewMockURL.absoluteString + "ll", placeholder: nil, title: "Some Assistant", subtitle: "The math assistant description")
   }
}

#Preview("Empty url")  {
   EmptyAssistantPlaceholderView(imageURL: nil, placeholder: Image(systemName: "oval.bottomhalf.filled"), title: "Some Assistant", subtitle: "The math assistant description")
}

#Preview("Valid url")  {
   EmptyAssistantPlaceholderView(imageURL: urlImageViewMockURL.absoluteString, placeholder: Image(systemName: "oval.bottomhalf.filled"), title: "Some Assistant", subtitle: "The math assistant description")
}
