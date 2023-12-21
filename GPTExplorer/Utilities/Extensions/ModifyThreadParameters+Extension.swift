//
//  ModifyThreadParameters+Extension.swift
//  GPTExplorer
//
//  Created by James Rochabrun on 12/20/23.
//

import Foundation
import SwiftOpenAI

extension ModifyThreadParameters: Equatable {
   public static func == (lhs: ModifyThreadParameters, rhs: ModifyThreadParameters) -> Bool {
      lhs.metadata == rhs.metadata
   }
}
