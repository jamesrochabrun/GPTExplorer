//
//  CheckboxRow.swift
//  GPTExplorer
//
//  Created by James Rochabrun on 11/20/23.
//

import SwiftUI

// MARK: CheckboxRow

struct CheckboxRow: View {
   
   let title: String
   @Binding var isChecked: Bool

   var body: some View {
      HStack {
         CheckboxView(isChecked: $isChecked)
         Text(title)
         Spacer()
      }
   }
}

// MARK: Mock+Preview

#Preview {
   VStack {
      CheckboxRow(title: "Code generation", isChecked: .constant(true))
      CheckboxRow(title: "Dall-e", isChecked: .constant(true))
   }
}


