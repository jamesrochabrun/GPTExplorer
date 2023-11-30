//
//  EmptyPlaceholderView.swift
//  GPTExplorer
//
//  Created by James Rochabrun on 11/21/23.
//

import Foundation
import SwiftUI

// MARK: EmptyPlaceholderView

struct EmptyPlaceholderView: View {
   
   let imageURL: String?
   let placeholder: Image?
   let title: String
   let subtitle: String?
   
   var body: some View {
      VStack(spacing: Sizes.spacingExtraLarge) {
         if let imageURL, let urlDisplay = URL(string: imageURL) {
            URLImageView(url: urlDisplay)
               .clipShape(Circle())
               .overlay(Circle().stroke(Color.white, lineWidth: 1))
               .shadow(radius: 10)
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
   }
}

// MARK: Mock+Preview

#Preview("All") {
   VStack {
      EmptyPlaceholderView(imageURL: urlImageViewMockURL.absoluteString + "ll", placeholder: nil, title: "Some Assistant", subtitle: "The math assistant description")
      EmptyPlaceholderView(imageURL: nil, placeholder: Image(systemName: "oval.bottomhalf.filled"), title: "Some Assistant", subtitle: "The math assistant description")
      EmptyPlaceholderView(imageURL: urlImageViewMockURL.absoluteString, placeholder: Image(systemName: "oval.bottomhalf.filled"), title: "Some Assistant", subtitle: "The math assistant description")
   }
}

#Preview("Error") {
   VStack {
      EmptyPlaceholderView(imageURL: urlImageViewMockURL.absoluteString + "ll", placeholder: nil, title: "Some Assistant", subtitle: "The math assistant description")
   }
}

#Preview("Empty url")  {
   EmptyPlaceholderView(imageURL: nil, placeholder: Image(systemName: "oval.bottomhalf.filled"), title: "Some Assistant", subtitle: "The math assistant description")
}

#Preview("Valid url")  {
   EmptyPlaceholderView(imageURL: urlImageViewMockURL.absoluteString, placeholder: Image(systemName: "oval.bottomhalf.filled"), title: "Some Assistant", subtitle: "The math assistant description")
}
