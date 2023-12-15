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
   @Binding var isLoading: Bool?
   
   init(
      iconName: String,
      isLoading: Binding<Bool?> = .constant(nil),
      action: @escaping () -> Void) {
      self.iconName = iconName
      self.action = action
      _isLoading = isLoading
   }

   var body: some View {
      Button(action: action) {
         Group {
            switch style.display {
            case .intrinsic:
               intrinsicIcon
            case .resizable(let size):
               resizableIcon(size: size)
            }
         }
         .foregroundColor(isEnabled ? style.foregroundColor : style.foregroundColorDisabled)
         .padding(.horizontal, style.horizontalPadding)
         .padding(.vertical, style.verticalPadding)
         .background(isEnabled ? style.backgroundColor : style.backgroundColorDisabled)
         .cornerRadius(style.cornerRadius)
      }
   }
   
   @ViewBuilder
   private var intrinsicIcon: some View {
      if isLoading == true {
         ProgressView()
            .frame(width: 12, height: 16)
            .padding(.horizontal, Sizes.spacingExtraSmall)
      } else {
         Image(systemName: iconName)
      }
   }
   
   @ViewBuilder
   private func resizableIcon(size: CGSize) -> some View {
      if isLoading == true {
         ProgressView()
            .frame(width: 12, height: 16)
            .padding(.horizontal, Sizes.spacingExtraSmall)
      } else {
         Image(systemName: iconName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .padding(.horizontal, size.width / 20) // approx
            .padding(.vertical, size.width / 20) // approx
            .frame(width: size.width, height: size.height) 
      }
   }
   
   @Environment(\.iconButtonStyle) private var style: IconButtonStyle
   @Environment(\.isEnabled) var isEnabled: Bool
}

// MARK: IconButtonStyle

struct IconButtonStyle {
   
   enum Display {
      case intrinsic
      case resizable(CGSize)
   }
   
   var backgroundColor: Color = ThemeColor.brandColor
   var backgroundColorDisabled = ThemeColor.actionBackgroundDisabled
   var foregroundColorDisabled = ThemeColor.actionForegroundDisabled
   var foregroundColor = Color.white
   var horizontalPadding: CGFloat = 10
   var verticalPadding: CGFloat = 10
   var cornerRadius: CGFloat = 10
   var display = Display.intrinsic
   
   
   static var secondary: Self {
      var style = IconButtonStyle()
      style.backgroundColor = ThemeColor.brandSecondaryColor
      return style
   }
   
   static var tertiary: Self {
      var style = IconButtonStyle()
      style.foregroundColor = ThemeColor.actionForeground
      style.backgroundColor = ThemeColor.actionBackground
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
   
   static var circle: Self {
      var style = IconButtonStyle()
      style.cornerRadius = 50
      return style
   }
   
   static var circleMedium: Self {
      var style = IconButtonStyle()
      style.cornerRadius = 40
      style.display = .resizable(.init(width: 40, height: 40))
      return style
   }
   
   static var circleMediumSecondary: Self {
      var style = secondary
      style.cornerRadius = 40
      style.display = .resizable(.init(width: 40, height: 40))
      return style
   }
   
   static var circleSecondary: Self {
      var style = secondary
      style.cornerRadius = 50
      return style
   }
   
   static var circleTertiary: Self {
      var style = tertiary
      style.cornerRadius = 50
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
         .iconButtonStyle(.tertiary)
      IconButton(iconName: "paperplane", action: {})
         .iconButtonStyle(.plain)
      IconButton(iconName: "paperplane", action: {})
         .iconButtonStyle(.plainReversed)
         .border(.brown) // just to be able to see it as it is white.
      IconButton(iconName: "mic", action: {})
         .iconButtonStyle(.circleMedium)
      IconButton(iconName: "paperplane", action: {})
         .iconButtonStyle(.circleTertiary)
      
      IconButton(iconName: "stop.circle", action: {})
         .iconButtonStyle(.circleMediumSecondary)
      IconButton(iconName: "xmark.circle", action: {})
         .iconButtonStyle(.circleMediumSecondary)
      IconButton(iconName: "mic.circle", action: {})
         .iconButtonStyle(.circleMediumSecondary)
   }
}

#Preview {
   VStack {
      IconButton(iconName: "paperplane", action: {})
      IconButton(iconName: "paperplane", action: {})
         .iconButtonStyle(.tertiary)
      IconButton(iconName: "paperplane", action: {})
         .iconButtonStyle(.plain)
      IconButton(iconName: "paperplane", action: {})
         .iconButtonStyle(.plainReversed)
      IconButton(iconName: "paperplane", action: {})
         .iconButtonStyle(.circle)
      IconButton(iconName: "paperplane", action: {})
         .iconButtonStyle(.circleTertiary)
      IconButton(iconName: "stop.circle", action: {})
         .iconButtonStyle(.circleMediumSecondary)
      IconButton(iconName: "xmark.circle", action: {})
         .iconButtonStyle(.circleMediumSecondary)
      IconButton(iconName: "mic", action: {})
         .iconButtonStyle(.circleMediumSecondary)
   }
   .disabled(true)
}

