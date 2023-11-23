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
               .urlImageViewStyle(.assistantRow)
         } else {
            Circle()
               .stroke(.gray, style: StrokeStyle(lineWidth: 4))
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

#Preview {
   EmptyPlaceholderView(imageURL: urlImageViewMockURL.absoluteString, placeholder: nil, title: "Some Assistant", subtitle: "The math assistant description")
}
