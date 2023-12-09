//
//  PushedScreen.swift
//  GPTExplorer
//
//  Created by James Rochabrun on 11/22/23.
//

import SwiftUI


struct PushedScreen<Content: View>: View {
   let content: Content
   
   init(@ViewBuilder content: () -> Content) {
      self.content = content()
   }
   
   var body: some View {
      content
         .navigationBarBackButtonHidden(true)
         .navigationBarItems(leading: Button(action: {
            self.presentationMode.wrappedValue.dismiss()
         }) {
            HStack {
               Image(systemName: "chevron.left")
                  .tint(ThemeColor.brandColor)
            }
         })
   }
   
   @Environment(\.presentationMode) private var presentationMode
   
}

