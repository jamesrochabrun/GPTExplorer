//
//  CheckboxView.swift
//  GPTExplorer
//
//  Created by James Rochabrun on 11/20/23.
//

import SwiftUI

// MARK: CheckboxView

struct CheckboxView: View {
   
   @Binding var isChecked: Bool
   
   var body: some View {
      Button(action: {
         withAnimation {
            isChecked.toggle()
         }
      }) {
         Image(systemName: isChecked ? "checkmark.square" : "square")
      }
      .buttonStyle(PlainButtonStyle())
   }
}

// MARK: Mock+Previw

#Preview {
   VStack {
      CheckboxView(isChecked: .constant(true))
      CheckboxView(isChecked: .constant(false))
   }
}
