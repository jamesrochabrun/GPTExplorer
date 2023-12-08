//
//  RoundedTextField.swift
//  GPTExplorer
//
//  Created by James Rochabrun on 12/8/23.
//

import SwiftUI

struct RoundedTextField: View {
   
    @Binding var text: String
    var placeholder: String

    var body: some View {
       TextField(placeholder, text: $text)
          .padding(.vertical, 8)
          .padding(.horizontal, 12)
          .background(Color(.systemBackground))
                  .clipShape(RoundedRectangle(cornerRadius: 25))
                  .overlay(
                      RoundedRectangle(cornerRadius: 25)
                         .stroke(Color.gray, lineWidth: 0.5)
                          
                  )
    }
}

#Preview {
   RoundedTextField(text: .constant("Some content"), placeholder: "")
}
