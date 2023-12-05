//
//  AttachmentView.swift
//  GPTExplorer
//
//  Created by James Rochabrun on 12/4/23.
//

import SwiftUI

struct AttachmentView: View {
   
   let fileName: String
   @Binding var actionTrigger: Bool

   var body: some View {
      HStack(spacing: Sizes.spacingExtraSmall) {
         HStack {
            Image(systemName: "doc")
               .resizable()
               .aspectRatio(contentMode: .fit)
               .frame(width: 10)
               .foregroundColor(.secondary)
            Text(fileName)
               .font(.caption2)
         }
         IconButton(iconName: "xmark.circle.fill") {
             actionTrigger = true
         }
         .iconButtonStyle(.plain)
      }
      .padding(.leading, Sizes.spacingMedium)
      .background(
         RoundedRectangle(cornerRadius: 8)
            .stroke(.gray.opacity(0.5), lineWidth: 0.5)
      )
   }
}

#Preview {
   AttachmentView(fileName: "Mydocument.pdf", actionTrigger: .constant(true))
}
