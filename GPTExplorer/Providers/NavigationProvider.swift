//
//  NavigationProvider.swift
//  GPTExplorer
//
//  Created by James Rochabrun on 11/28/23.
//

import SwiftUI
import SwiftOpenAI

@Observable class NavigationProvider {
   
   var selectedItem: SideMenuItem = .none
   var isOpen: Bool = false
   var deletedThreadID: String?
   var createdThread: ThreadObject?
}
