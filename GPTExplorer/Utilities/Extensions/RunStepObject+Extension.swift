//
//  RunStepObject+Extension.swift
//  GPTExplorer
//
//  Created by James Rochabrun on 12/11/23.
//

import Foundation
import SwiftOpenAI

extension RunStepObject: Identifiable {}

extension RunStepObject {
    
    /// Converts the instance of `RunStepObject` to a JSON string.
    /// - Returns: A JSON string representation of the instance if the encoding is successful; otherwise, `nil`.
    func toJSONString() -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted // if you want the JSON to be pretty-printed
        do {
            let data = try encoder.encode(self)
            return String(data: data, encoding: .utf8)
        } catch {
            print("Error encoding to JSON: \(error)")
            return nil
        }
    }
}
