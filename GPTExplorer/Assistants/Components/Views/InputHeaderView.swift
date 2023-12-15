//
//  InputHeaderView.swift
//  GPTExplorer
//
//  Created by James Rochabrun on 11/20/23.
//

import SwiftUI

// MARK: InputHeaderView

struct InputHeaderView<Content: View, ExpandableContent: View>: View {
   
   private let content: Content
   private let expandableContent: ExpandableContent
   private let title: String
   private let subtitle: String?
   @Binding private var isExpanded: Bool
   private let isExpandableContent: Bool
   
   
   init(
      title: String,
      subtitle: String? = nil,
      isExpanded: Binding<Bool>,
      @ViewBuilder content: () -> Content,
      @ViewBuilder expandableContent: () -> ExpandableContent)
   {
      self.title = title
      self.subtitle = subtitle
      _isExpanded = isExpanded
      self.content = content()
      self.expandableContent = expandableContent()
      isExpandableContent = true
   }
   
   init(
      title: String,
      @ViewBuilder content: () -> Content,
      @ViewBuilder expandableContent: () -> ExpandableContent = EmptyView.init)
      where ExpandableContent == EmptyView
   {
      self.title = title
      self.content = content()
      self.expandableContent = expandableContent()
      _isExpanded = .constant(false)
      subtitle = nil
      isExpandableContent = false
   }
   
   var body: some View {
      let mainContent = VStack(alignment: .leading, spacing: style.verticalPadding) {
         HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading) {
               Text(title)
                  .font(.headline)
               if let subtitle {
                  Text(subtitle)
                     .font(.subheadline)
               }
            }
            Spacer()
            if isExpandableContent {
               IconButton(iconName: isExpanded ? "chevron.up" : "chevron.down") {
                  isExpanded.toggle()
               }
               .iconButtonStyle(.plain)
            }
         }
         if isExpanded {
            expandableContent
         }
         content
      }
      .animation(.easeInOut, value: isExpanded)
      if style.isCard {
         mainContent
            .padding()
            .background(RoundedRectangle(cornerRadius: 10)
               .fill(ThemeColor.systemBackgroundColor)
               .shadow(radius: 4))
      } else {
         mainContent
      }
   }
   
   @Environment(\.inputViewStyle) private var style: InputHeaderViewStyle
}

// MARK: InputHeaderViewStyle

struct InputHeaderViewStyle {
   
   var verticalPadding: CGFloat = 10.0
   var isCard: Bool = false
}

extension InputHeaderViewStyle {
   
   static var card: Self {
      var style = InputHeaderViewStyle()
      style.isCard = true
      return style
   }
}

// MARK: Environment

struct InputViewStyleKey: EnvironmentKey {
   static let defaultValue = InputHeaderViewStyle()
}

extension EnvironmentValues {
   var inputViewStyle: InputHeaderViewStyle {
      get { self[InputViewStyleKey.self] }
      set { self[InputViewStyleKey.self] = newValue }
   }
}

extension View {
   func inputViewStyle(_ style: InputHeaderViewStyle) -> some View {
      environment(\.inputViewStyle, style)
   }
}

// MARK: Mock+Preview

#Preview {
   InputHeaderView(title: "Some Title") {
      Text("This is secondary")
   }
}

#Preview("Expandable") {
   
   @State var isExpanded: Bool = false
   return InputHeaderView(
      title: "Tap to Expand",
      isExpanded: $isExpanded,
      content: {
         Text("Primary content")
     }, expandableContent: {
         Text("Expandable content")
     })
}
