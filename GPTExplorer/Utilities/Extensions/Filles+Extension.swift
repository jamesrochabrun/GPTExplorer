//
//  Filles+Extension.swift
//  GPTExplorer
//
//  Created by James Rochabrun on 12/20/23.
//

import Foundation
import SwiftOpenAI

extension FileObject.DeletionStatus: Equatable {
   public static func == (lhs: FileObject.DeletionStatus, rhs: FileObject.DeletionStatus) -> Bool {
      lhs.id == rhs.id
   }
}

extension FileObject: Equatable {
   public static func == (lhs: FileObject, rhs: FileObject) -> Bool {
      lhs.id == rhs.id
   }
}

extension FileParameters: Equatable, Identifiable {
   public static func == (lhs: FileParameters, rhs: FileParameters) -> Bool {
      lhs.file == rhs.file &&
      lhs.fileName == rhs.fileName &&
      lhs.purpose == rhs.purpose
   }
   
   public var id: String {
      fileName
   }
}
