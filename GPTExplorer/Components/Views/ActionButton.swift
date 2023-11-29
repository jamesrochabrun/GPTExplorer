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
   @Binding var isLoading: Bool?

   // Initializer
   init(
      _ title: String,
      actionIcon: Image? = nil,
      isLoading: Binding<Bool?> = .constant(nil),
      action: @escaping () -> Void)
   {
      actionTitle = title
      self.actionIcon = actionIcon
      _isLoading = isLoading
      self.action = action
   }
   
   var body: some View {
      Button(action: action) {
         HStack {
            switch style.horizontalIconAlignment {
            case .leading:
               icon
               Text(actionTitle)
            case .trailing:
               Text(actionTitle)
               icon
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
   
   @ViewBuilder
   var icon: some View {
      if isLoading == true {
         ProgressView()
            .frame(width: 5, height: 5)
            .padding(.horizontal, Sizes.spacingExtraSmall)
         
      } else if let actionIcon {
         actionIcon
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(height: style.iconHeight)
      }
   }
   
   @Environment(\.actionButtonStyle) private var style: ActionButtonStyle
   @Environment(\.isEnabled) var isEnabled: Bool
}

// MARK: ActionButtonStyle

struct ActionButtonStyle {
   
   var horizontalPadding: CGFloat = 30
   var verticalPading: CGFloat = 10
   var backgroundColor = ThemeColor.brandColor
   var backgroundColorDisabled = ThemeColor.colorDisabled
   var cornerRadius: CGFloat = 40.0
   var horizontalIconAlignment: HorizontalIconAlignment = .leading
   var foregroundColor: Color = .white
   var fontWeight: Font.Weight = .bold
   var iconHeight: CGFloat = 14.0
   
   enum HorizontalIconAlignment {
      case leading
      case trailing
   }
   
   static var plain: Self {
      var style = ActionButtonStyle()
      style.horizontalPadding = 18
      style.verticalPading = Sizes.spacingMedium
      style.cornerRadius = 10
      style.fontWeight = .medium
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
      style.iconHeight = 10.0
      return style
   }
   
   static var secondary: Self {
      var style = Self.plain
      style.backgroundColor = ThemeColor.brandColorSecondary
      style.foregroundColor = .primary
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
         ActionButton("Save", isLoading: .constant(true)) {}
         ActionButton("Add an run", actionIcon: Image(systemName: "play")) {}
      }
      HStack {
         ActionButton("Add an run", actionIcon: Image(systemName: "play")) {}
         ActionButton("Add") {}
            .actionButtonStyle(.secondary)
         IconButton(iconName: "paperclip", action: {})
            .iconButtonStyle(.secondary)
      }
      .actionButtonStyle(.plain)
      
      VStack {
         ActionButton("Save") {}
         ActionButton("Add an run", actionIcon: Image(systemName: "chevron.right")) {}
      }
      .actionButtonStyle(.plainTrailing)
   }
}
