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
      }
      .tint(style.tintColor)
      .buttonStyle(.bordered)
   }
   
   @Environment(\.iconButtonStyle) private var style: IconButtonStyle
}

// MARK: IconButtonStyle

struct IconButtonStyle {
   let tintColor: Color = ThemeColor.tintColor
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
   IconButton(iconName: "paperplane", action: {})
}
