//
//  InputHeaderView.swift
//  GPTExplorer
//
//  Created by James Rochabrun on 11/20/23.
//

import SwiftUI

// MARK: InputHeaderView

struct InputHeaderView<Content: View>: View {
   
   let content: Content
   let title: String
   
   init(title: String, @ViewBuilder content: () -> Content) {
      self.title = title
      self.content = content()
   }
   
   var body: some View {
      let mainContent = VStack(alignment: .leading, spacing: style.verticalPadding) {
         Text(title)
            .font(.headline)
         content
      }
      if style.isCard {
         mainContent
            .padding()
            .background(RoundedRectangle(cornerRadius: 10)
               .fill(Color(.systemBackground))
                            .shadow(radius: 4))
      } else {
         mainContent
      }
   }
   
   @Environment(\.inputViewStyle) private var style: InputHeaderViewStyle
   
}

// MARK: InputHeaderViewStyle

struct InputHeaderViewStyle {
   
   var verticalPadding: CGFloat = 10.0
   var isCard: Bool = false

}

extension InputHeaderViewStyle {
   
   static var card: Self {
      var style = InputHeaderViewStyle()
      style.isCard = true
      return style
   }
}

// MARK: Environment

struct InputViewStyleKey: EnvironmentKey {
   static let defaultValue = InputHeaderViewStyle()
}

extension EnvironmentValues {
   var inputViewStyle: InputHeaderViewStyle {
      get { self[InputViewStyleKey.self] }
      set { self[InputViewStyleKey.self] = newValue }
   }
}

extension View {
   func inputViewStyle(_ style: InputHeaderViewStyle) -> some View {
      environment(\.inputViewStyle, style)
   }
}

// MARK: Mock+Preview

#Preview {
   InputHeaderView(title: "Some Title") {
      Text("This is secondary")
   }
}
