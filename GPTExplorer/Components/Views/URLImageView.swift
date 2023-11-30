//
//  URLImageView.swift
//  GPTExplorer
//
//  Created by James Rochabrun on 11/20/23.
//

import SwiftUI

// MARK: URLImageView

struct URLImageView: View {
   
   let url: URL
   
   var body: some View {
      AsyncImage(
         url: url,
         transaction: Transaction(animation: .easeInOut)
      ) { phase in
         switch phase {
         case .empty:
            ProgressView()
         case .success(let image):
            image
               .resizable()
               .frame(width: style.size, height: style.size)
               .transition(.opacity)
         case .failure:
            Image(systemName: "exclamationmark.circle")
               .symbolEffect(.bounce.down.byLayer, value: true)
         @unknown default:
            EmptyView()
         }
      }
      .frame(width: style.size, height: style.size)
      .background(Color.gray)
      .clipShape(RoundedRectangle(cornerRadius: 10))
   }
   
   @Environment(\.urlImageViewStyle) private var style
}

// MARK: URLImageViewStyle

struct URLImageViewStyle {
   
   var size: CGFloat
   var backgroundColor: Color
   var failureImage: Image
   
   init(
      size: CGFloat = 100,
      backgroundColor: Color = .gray,
      failureImage: Image = .init(systemName: "wifi.slash"))
   {
      self.size = size
      self.backgroundColor = backgroundColor
      self.failureImage = failureImage
   }
}

extension URLImageViewStyle {
   
   static var assistantRow: Self {
      var style = URLImageViewStyle()
      style.size = 24
      return style
   }
}

// MARK: Environment

struct URLImageViewStyleKey: EnvironmentKey {
    static let defaultValue = URLImageViewStyle()
}

extension EnvironmentValues {
    var urlImageViewStyle: URLImageViewStyle {
        get { self[URLImageViewStyleKey.self] }
        set { self[URLImageViewStyleKey.self] = newValue }
    }
}

extension View {
    func urlImageViewStyle(_ style: URLImageViewStyle) -> some View {
        environment(\.urlImageViewStyle, style)
    }
}

// MARK: Mock+Preview

let urlImageViewMockURL = URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/d/dd/Gfp-wisconsin-madison-the-nature-boardwalk.jpg/2560px-Gfp-wisconsin-madison-the-nature-boardwalk.jpg")!

#Preview {
   
   ScrollView {
      VStack(spacing: 40) {
         URLImageView(url: urlImageViewMockURL)
         URLImageView(url: urlImageViewMockURL)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.white, lineWidth: 4))
            .shadow(radius: 10)
         URLImageView(url: urlImageViewMockURL)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.white, lineWidth: 4))
      }
      VStack(spacing: 40) {
         URLImageView(url: urlImageViewMockURL)
         URLImageView(url: urlImageViewMockURL)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.white, lineWidth: 4))
            .shadow(radius: 10)
         URLImageView(url: urlImageViewMockURL)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.white, lineWidth: 4))
      }
      .urlImageViewStyle(.assistantRow)
   }
}
