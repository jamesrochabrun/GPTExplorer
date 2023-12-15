//
//  CustomNumericTextField.swift
//  GPTExplorer
//
//  Created by James Rochabrun on 12/14/23.
//

import SwiftUI

struct CustomNumericTextField: View {
   
    @Binding var value: Int
    var placeholder: String

    var body: some View {
       TextField(placeholder, value: $value, formatter: NumberFormatter())
          .padding(.vertical, style.verticalPadding)
          .padding(.horizontal, style.horizontalPadding)
          .background(style.background)
                  .clipShape(RoundedRectangle(cornerRadius: 25))
                  .overlay(
                      RoundedRectangle(cornerRadius: 25)
                         .stroke(Color.gray, lineWidth: 0.5)
                          
                  )
    }
   
   @Environment(\.customTextFieldStyle) private var style
}

// MARK: CustomTextFieldStyle

struct CustomNumericTextFieldStyle {
   
   var verticalPadding = Sizes.spacingMedium
   var horizontalPadding = Sizes.spacingLarge
   var background = ThemeColor.systemBackgroundColor
}

// MARK: Environment

struct CustomNumericTextFieldStyleKey: EnvironmentKey {
   static let defaultValue = CustomNumericTextFieldStyle()
}

extension EnvironmentValues {
   var customNumericTextFieldStyle: CustomNumericTextFieldStyle {
      get { self[CustomNumericTextFieldStyleKey.self] }
      set { self[CustomNumericTextFieldStyleKey.self] = newValue }
   }
}

extension View {
   func customNumericTextFieldStyle(_ style: CustomNumericTextFieldStyle) -> some View {
      environment(\.customNumericTextFieldStyle, style)
   }
}


#Preview {
   CustomNumericTextField(value: .constant(1), placeholder: "Dollars")
}
