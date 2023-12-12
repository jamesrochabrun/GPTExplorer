//
//  CircleBouncingView.swift
//  GPTExplorer
//
//  Created by James Rochabrun on 12/11/23.
//

import SwiftUI

struct CircleBouncingView: View {
   
   var animationDuration: Double
   @State private var isScaledUp = false
   
   var body: some View {
      Circle()
         .scaleEffect(isScaledUp ? 1.5 : 1) // 1.5 is 150% size, 1 is 100% size
         .onAppear {
            withAnimation(Animation.easeInOut(duration: animationDuration).repeatForever(autoreverses: true)) {
               isScaledUp.toggle()
            }
         }
   }
}

#Preview {
   CircleBouncingView(animationDuration: 0.3)
}
