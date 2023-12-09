//
//  LoadingDotsView.swift
//  GPTExplorer
//
//  Created by James Rochabrun on 12/2/23.
//

import SwiftUI

struct LoadingDotsView: View {
   
   let prefix: String?
   
   @State private var dotsCount = 0
   
   let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
   
   var body: some View {
      HStack {
         Text("\(prefix ?? "")\(getDots())")
            .font(.body)
            .onReceive(timer) { _ in
               withAnimation {
                  self.dotsCount = (self.dotsCount + 1) % 4
               }
            }
      }
      .frame(minHeight: 30)
   }
   
   func getDots() -> String {
      return String(repeating: ".", count: dotsCount)
   }
}
