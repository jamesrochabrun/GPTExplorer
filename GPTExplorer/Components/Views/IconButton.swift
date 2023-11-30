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
            .foregroundColor(isEnabled ? style.foregroundColor : style.foregroundColorDisabled)
            .padding(.horizontal, style.horizontalPadding)
            .padding(.vertical, style.verticalPadding)
            .background(isEnabled ? style.backgroundColor : style.backgroundColorDisabled)
            .cornerRadius(style.cornerRadius)
      }
   }
   
   @Environment(\.iconButtonStyle) private var style: IconButtonStyle
   @Environment(\.isEnabled) var isEnabled: Bool
}

// MARK: IconButtonStyle

struct IconButtonStyle {
   
   var backgroundColor: Color = ThemeColor.brandColor
   var backgroundColorDisabled = ThemeColor.colorDisabled
   var foregroundColorDisabled = ThemeColor.colorDisabled
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
   
   static var plain: Self {
      var style = IconButtonStyle()
      style.backgroundColor = .clear
      style.backgroundColorDisabled = .clear
      style.foregroundColor = ThemeColor.brandColor
      return style
   }
   
   static var plainReversed: Self {
      var style = plain
      style.foregroundColor = .white
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
