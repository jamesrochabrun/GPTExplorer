//
//  BouncingCircleView.swift
//  GPTExplorer
//
//  Created by James Rochabrun on 12/11/23.
//

import SwiftUI

struct BouncingCircleView: View {
   @State private var moveRight = false
   private let animationDuration: Double = 0.75 // Duration for faster animation
   private let circleSize: CGFloat = 90
   private let stretchFactor: CGFloat = 1.2 // Maximum stretch factor
   
   var body: some View {
      GeometryReader { geometry in
         Circle()
            .frame(width: circleSize, height: circleSize)
            .modifier(StretchAtEdgesModifier(currentX: moveRight ? geometry.size.width - circleSize / 2 : circleSize / 2, maxWidth: geometry.size.width, circleRadius: circleSize / 2, maxStretch: stretchFactor))
            .position(x: moveRight ? geometry.size.width - circleSize / 2 : circleSize / 2, y: geometry.size.height / 2)
            .onAppear {
               withAnimation(Animation.easeInOut(duration: animationDuration).repeatForever(autoreverses: true)) {
                  moveRight.toggle()
               }
            }
      }
   }
}

#Preview {
   BouncingCircleView()
}
