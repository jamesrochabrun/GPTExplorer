//
//  NavigationProvider.swift
//  GPTExplorer
//
//  Created by James Rochabrun on 11/28/23.
//

import SwiftUI
import SwiftOpenAI

@Observable class NavigationProvider {
   
   var changeToSelectedItem: (selectedItem: SideMenuItem, animated: Bool) = (selectedItem: .chat, animated: false)
   var isOpen: Bool = false
}
