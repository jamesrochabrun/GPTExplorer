//
//  IconButton.swift
//  GPTExplorer
//
//  Created by James Rochabrun on 11/21/23.
//

import SwiftUI

// MARK: IconButton

struct IconButton: View {
   
   let iconName: String
   let action: () -> Void
   
   var body: some View {
      Button(action: action) {
         Image(systemName: iconName)
            .foregroundColor(style.foregroundColor)
            .padding(.horizontal, style.horizontalPadding)
            .padding(.vertical, style.verticalPadding)
            .background(style.backgroundColor)
            .cornerRadius(style.cornerRadius)
      }
   }
   
   @Environment(\.iconButtonStyle) private var style: IconButtonStyle
}

// MARK: IconButtonStyle

struct IconButtonStyle {
   
   var backgroundColor: Color = ThemeColor.brandColor
   var foregroundColor = Color.white
   var horizontalPadding: CGFloat = 10
   var verticalPadding: CGFloat = 10
   var cornerRadius: CGFloat = 10
   
   static var secondary: Self {
      var style = IconButtonStyle()
      style.foregroundColor = .primary
      style.backgroundColor = ThemeColor.brandColorSecondary
      return style
   }
}

struct IconButtonStyleKey: EnvironmentKey {
   static let defaultValue: IconButtonStyle = IconButtonStyle()
}

extension EnvironmentValues {
   var iconButtonStyle: IconButtonStyle {
      get { self[IconButtonStyleKey.self] }
      set { self[IconButtonStyleKey.self] = newValue }
   }
}

extension View {
   func iconButtonStyle(_ style: IconButtonStyle) -> some View {
      environment(\.iconButtonStyle, style)
   }
}

// MARK: Mock+Preview

#Preview {
   VStack {
      IconButton(iconName: "paperplane", action: {})
      IconButton(iconName: "paperplane", action: {})
         .iconButtonStyle(.secondary)
      
   }
}
