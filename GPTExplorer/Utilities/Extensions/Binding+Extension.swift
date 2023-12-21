//
//  Binding+Extension.swift
//  GPTExplorer
//
//  Created by James Rochabrun on 12/6/23.
//

import SwiftUI

extension Binding where Value == String? {
   var orEmpty: Binding<String> {
      .init(
         get: { self.wrappedValue ?? "" },
         set: { self.wrappedValue = $0 }
      )
   }
}

extension Binding where Value == Bool? {
   var orFalse: Binding<Bool> {
      .init(
         get: { self.wrappedValue ?? false },
         set: { self.wrappedValue = $0 }
      )
   }
}

extension Binding where Value == Double? {
   var orZero: Binding<Double> {
      .init(
         get: { self.wrappedValue ?? 0 },
         set: { self.wrappedValue = $0 }
      )
   }
}

extension Binding where Value == [Int: Double]? {
   var orEmpty: Binding<[Int: Double]> {
      .init(
         get: { self.wrappedValue ?? [:] },
         set: { self.wrappedValue = $0 }
      )
   }
}

extension Binding where Value == [String]? {
   var orEmpty: Binding<[String]> {
      .init(
         get: { self.wrappedValue ?? [] },
         set: { self.wrappedValue = $0 }
      )
   }
}

extension Binding where Value == Double? {
   var orDefaultOne: Binding<Double> {
      .init(
         get: { self.wrappedValue ?? 1 },
         set: { self.wrappedValue = $0 }
      )
   }
}


