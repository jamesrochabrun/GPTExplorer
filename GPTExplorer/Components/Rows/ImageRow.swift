//
//  ImageRow.swift
//  GPTExplorer
//
//  Created by James Rochabrun on 11/20/23.
//

import SwiftUI

// MARK: ImageRow

struct ImageRow: View {
   
   let url: String?
   let title: String
   let subtitle: String?
   
   var body: some View {
      HStack(spacing: Sizes.spacingExtraLarge) {
         if let url, let urlDisplay = URL(string: url) {
            URLImageView(url: urlDisplay)
               .clipShape(Circle())
               .overlay(Circle().stroke(Color.white, lineWidth: 1))
               .shadow(radius: 10)
               .urlImageViewStyle(.assistantRow)
         } else {
            Circle()
               .stroke(.gray, style: StrokeStyle(lineWidth: 4))
               .frame(width: 40, height: 40)
               .overlay(
                  Image(systemName: "lightbulb.led")
               )
         }
         VStack(alignment: .leading) {
            Text(title)
               .font(.title2)
            if let subtitle {
               Text(subtitle)
            }
         }
      }
   }
}

// MARK: Mock+Preview

#Preview {
   ImageRow(url: urlImageViewMockURL.absoluteString, title: "Some Assistant", subtitle: "The math descrip")
      .border(.black)
}
