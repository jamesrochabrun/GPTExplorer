//
//  MainActionButton.swift
//  GPTExplorer
//
//  Created by James Rochabrun on 11/20/23.
//

import SwiftUI

// MARK: MainActionButton

struct MainActionButton: View {
   
   let actionTitle: String
   let action: () -> Void
   
   // Initializer
   init(_ title: String, action: @escaping () -> Void) {
      actionTitle = title
      self.action = action
   }
   
   var body: some View {
      Button(action: action) {
         Text(actionTitle)
            .padding(.horizontal, 30)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding()
            .background(ThemeColor.tintColor)
            .cornerRadius(40)
      }
      .clipShape(Capsule())
   }
}

// MARK: Mock+Preview

#Preview {
   MainActionButton("Save") {}
}
