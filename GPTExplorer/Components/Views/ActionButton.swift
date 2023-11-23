//
//  ActionButton.swift
//  GPTExplorer
//
//  Created by James Rochabrun on 11/20/23.
//

import SwiftUI

// MARK: ActionButton

struct ActionButton: View {
   
   let actionTitle: String
   let actionIcon: Image?
   let action: () -> Void
   
   // Initializer
   init(
      _ title: String,
      actionIcon: Image? = nil,
      action: @escaping () -> Void)
   {
      actionTitle = title
      self.actionIcon = actionIcon
      self.action = action
   }
   
   var body: some View {
      Button(action: action) {
         HStack {
            if let actionIcon {
               actionIcon
            }
            Text(actionTitle)
         }
         .padding(.horizontal, style.horizontalPadding)
         .fontWeight(.bold)
         .foregroundColor(.white)
         .padding(.vertical, style.verticalPading)
         .background(style.backgroundColor)
         .cornerRadius(style.cornerRadius)
      }
   }
   
   @Environment(\.actionButtonStyle) private var style: ActionButtonStyle
}

// MARK: ActionButtonStyle

struct ActionButtonStyle {
   
   var horizontalPadding: CGFloat = 30
   var verticalPading: CGFloat = 10

   var backgroundColor = ThemeColor.tintColor
   var cornerRadius: CGFloat = 40.0
   
   static var plain: Self {
      var style = ActionButtonStyle()
      style.horizontalPadding = 10
      style.verticalPading = 8
      style.cornerRadius = 10
      return style
   }
}

// MARK: EnvironmentKey

struct ActionButtonStyleKey: EnvironmentKey {
    static let defaultValue = ActionButtonStyle()
}

extension EnvironmentValues {
    var actionButtonStyle: ActionButtonStyle {
        get { self[ActionButtonStyleKey.self] }
        set { self[ActionButtonStyleKey.self] = newValue }
    }
}


extension View {
   
   func actionButtonStyle(_ style: ActionButtonStyle) -> some View {
      environment(\.actionButtonStyle, style)
   }
}


// MARK: Mock+Preview

#Preview {
   VStack {
      VStack {
         ActionButton("Save") {}
         ActionButton("Add an run", actionIcon: Image(systemName: "play")) {}
      }
      VStack {
         ActionButton("Save") {}
         ActionButton("Add an run", actionIcon: Image(systemName: "play")) {}
      }
      .actionButtonStyle(.plain)
   }

   
}
