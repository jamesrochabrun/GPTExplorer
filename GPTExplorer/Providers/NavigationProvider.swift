//
//  NavigationProvider.swift
//  GPTExplorer
//
//  Created by James Rochabrun on 11/28/23.
//

import SwiftUI

@Observable class NavigationProvider {
   
   var selectedItem: SideMenuItem = .none
   var isOpen: Bool = false
}
