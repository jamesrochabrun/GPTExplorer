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
            switch style.horizontalIconAlignment {
            case .leading:
               if let actionIcon {
                  actionIcon
               }
               Text(actionTitle)
            case .trailing:
               Text(actionTitle)
               if let actionIcon {
                  actionIcon
               }
            }
         }
         .padding(.horizontal, style.horizontalPadding)
         .fontWeight(style.fontWeight)
         .foregroundColor(style.foregroundColor)
         .padding(.vertical, style.verticalPading)
         .background(isEnabled ? style.backgroundColor : style.backgroundColorDisabled)
         .cornerRadius(style.cornerRadius)
      }
   }
   
   @Environment(\.actionButtonStyle) private var style: ActionButtonStyle
   @Environment(\.isEnabled) var isEnabled: Bool
}

// MARK: ActionButtonStyle

struct ActionButtonStyle {
   
   var horizontalPadding: CGFloat = 30
   var verticalPading: CGFloat = 10

   var backgroundColor = ThemeColor.tintColor
   var backgroundColorDisabled = ThemeColor.tintColorDisabled

   var cornerRadius: CGFloat = 40.0
   var horizontalIconAlignment: HorizontalIconAlignment = .leading
   var foregroundColor: Color = .white
   var fontWeight: Font.Weight = .bold
   
   enum HorizontalIconAlignment {
      case leading
      case trailing
   }
   
   static var plain: Self {
      var style = ActionButtonStyle()
      style.horizontalPadding = 10
      style.verticalPading = 8
      style.cornerRadius = 10
      return style
   }
   
   static var plainTrailing: Self {
      var style = ActionButtonStyle()
      style.horizontalPadding = 10
      style.verticalPading = 8
      style.cornerRadius = 10
      style.horizontalIconAlignment = .trailing
      style.backgroundColor = .clear
      style.foregroundColor = .primary
      style.fontWeight = .semibold
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
      
      VStack {
         ActionButton("Save") {}
         ActionButton("Add an run", actionIcon: Image(systemName: "play")) {}
      }
      .actionButtonStyle(.plainTrailing)

   }
}
