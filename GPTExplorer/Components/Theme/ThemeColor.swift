//
//  ThemeColor.swift
//  GPTExplorer
//
//  Created by James Rochabrun on 11/20/23.
//

import SwiftUI

enum ThemeColor {}

extension ThemeColor {

   static let brandColor = Color(red: 55.0 / 255.0, green: 163.0 / 255.0, blue: 127.0 / 255.0)
   static let brandSecondaryColor = colorFromRGBString("rgb(49,13,180)")//Color(red: 27 / 255.0, green: 36 / 255.0, blue: 64 / 255.0)
      
   static let actionBackground = colorFromRGBString("rgb(236,236,241)")
   static let actionBackgroundDisabled = colorFromRGBString("rgb(247,247,248)")
   
   static let actionForeground = colorFromRGBString("rgb(53,55,64)")
   static let actionForegroundDisabled = colorFromRGBString("rgb(172,172,190)")

   static func colorFromRGBString(_ rgbString: String) -> Color {
       // Remove the "rgb(" and ")" parts and split by comma
       let components = rgbString
           .replacingOccurrences(of: "rgb(", with: "")
           .replacingOccurrences(of: ")", with: "")
           .split(separator: ",")
           .compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
       
       guard components.count == 3 else {
           print("Invalid format")
           return Color.clear // Return a default color in case of invalid format
       }
       
       // Convert to Color
       return Color(red: Double(components[0]) / 255.0,
                    green: Double(components[1]) / 255.0,
                    blue: Double(components[2]) / 255.0)
   }
}

