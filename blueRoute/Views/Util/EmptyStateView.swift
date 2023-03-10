//
//  EmptyStateView.swift
//  blueRoute
//
//  Created by Sandro Giannini on 11/19/22.
//

import SwiftUI

extension View {
  func debug() -> Self {
    print(Mirror(reflecting: self).subjectType)
    return self
  }
}

struct EmptyStateViewModifier<EmptyContent>: ViewModifier where EmptyContent: View {
  var isEmpty: Bool
  let emptyContent: () -> EmptyContent
  
  func body(content: Content) -> some View {
    if isEmpty {
      emptyContent()
    }
    else {
      content
    }
  }
}

extension View {
  func emptyState<EmptyContent>(_ isEmpty: Bool,
                                emptyContent: @escaping () -> EmptyContent) -> some View where EmptyContent: View {
    modifier(EmptyStateViewModifier(isEmpty: isEmpty, emptyContent: emptyContent))
  }
}

struct EmptyStateView_Previews: PreviewProvider {
  static var previews: some View {
    Label("Content", systemImage: "heart")
      .emptyState(true) {
        Text("We don't have any content, sorry 😔")
      }
  }
}
