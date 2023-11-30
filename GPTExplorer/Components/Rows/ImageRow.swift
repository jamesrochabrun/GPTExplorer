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
            Image(systemName: "circle.bottomrighthalf.checkered")
               .tint(.primary)
         }
         VStack(alignment: .leading) {
            Text(title)
               .font(.body)
               .frame(maxWidth: .infinity, alignment: .leading)
            if let subtitle, !subtitle.isEmpty {
               Text(subtitle)
                  .font(.caption)
                  .lineLimit(2)
            }
         }
      }
   }
   
   init(
      url: String?,
      title: String,
      subtitle: String? = nil)
   {
      self.url = url
      self.title = title
      self.subtitle = subtitle
   }
}

// MARK: Mock+Preview

#Preview {

   ZStack {
      ThemeColor.backgroundColor
      VStack {
         ImageRow(url: urlImageViewMockURL.absoluteString, title: "Some Assistant", subtitle: "The math description long line")
            .border(.black)
         ImageRow(url: urlImageViewMockURL.absoluteString, title: "Some Assistant", subtitle: nil)
            .border(.black)
         
         ImageRow(url: "", title: "Olivia")
            .border(.black)
         ImageRow(url: "", title: "Sasha")
            .border(.black)
      }
      .urlImageViewStyle(.assistantRow)
   }
   .foregroundColor(.white)
}
