//
//  ThreadObject+Extension.swift
//  GPTExplorer
//
//  Created by James Rochabrun on 12/20/23.
//

import Foundation
import SwiftOpenAI

extension ThreadObject: Equatable {
   
   public static func == (lhs: ThreadObject, rhs: ThreadObject) -> Bool {
      lhs.id == rhs.id
   }

   var assistantID: String? {
      metadata[ThreadMetadataKeys.assistantMetadataID]
   }
   
   var assistantName: String? {
      metadata[ThreadMetadataKeys.assistantMetadataName]
   }
   
   var displayTitle: String? {
      metadata[ThreadMetadataKeys.assistantMessageSnippet]
   }
   
   var assistantDescription: String? {
      metadata[ThreadMetadataKeys.assistantMetadataDescription]
   }
}
