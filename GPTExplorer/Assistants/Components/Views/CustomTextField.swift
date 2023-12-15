//
//  RoundedTextField.swift
//  GPTExplorer
//
//  Created by James Rochabrun on 12/8/23.
//

import SwiftUI

struct CustomTextField: View {
   
    @Binding var text: String
    var placeholder: String

    var body: some View {
       TextField(placeholder, text: $text, axis: style.axis)
          .padding(.vertical, style.verticalPadding)
          .padding(.horizontal, style.horizontalPadding)
          .background(style.background)
                  .clipShape(RoundedRectangle(cornerRadius: 25))
                  .overlay(
                      RoundedRectangle(cornerRadius: 25)
                         .stroke(Color.gray, lineWidth: 0.5)
                          
                  )
    }
   
   @Environment(\.customTextFieldStyle) private var style: CustomTextFieldStyle
}

// MARK: CustomTextFieldStyle

struct CustomTextFieldStyle {
   
   var axis: Axis = .vertical
   var verticalPadding = Sizes.spacingMedium
   var horizontalPadding = Sizes.spacingLarge
   var background = ThemeColor.systemBackgroundColor
}

extension CustomTextFieldStyle {
   
   static var horizontal: Self {
      var style = CustomTextFieldStyle()
      style.axis = .horizontal
      return style
   }
}

// MARK: Environment

struct CustomTextFieldStyleKey: EnvironmentKey {
   static let defaultValue = CustomTextFieldStyle()
}

extension EnvironmentValues {
   var customTextFieldStyle: CustomTextFieldStyle {
      get { self[CustomTextFieldStyleKey.self] }
      set { self[CustomTextFieldStyleKey.self] = newValue }
   }
}

extension View {
   func customTextFieldStyle(_ style: CustomTextFieldStyle) -> some View {
      environment(\.customTextFieldStyle, style)
   }
}


#Preview {
   CustomTextField(text: .constant("Some content"), placeholder: "")
}
