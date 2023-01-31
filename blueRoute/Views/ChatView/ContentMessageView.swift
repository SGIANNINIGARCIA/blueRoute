//
//  ContentMessageView.swift
//  blueRoute
//
//  Created by Sandro Giannini on 11/17/22.
//

import SwiftUI

struct ContentMessageView: View {
    var contentMessage: String
    var isCurrentUser: Bool
    
    var body: some View {
        Text(contentMessage)
                   .foregroundColor(isCurrentUser ? Color.white : Color.black)
                   .padding(10.0)
                   .background(isCurrentUser ? Color.blue : Color(UIColor(red: 240/255, green: 240/255, blue: 240/255, alpha: 1.0)))
                   .cornerRadius(10)
    }
}

struct ContentMessageView_Previews: PreviewProvider {
    static var previews: some View {
        ContentMessageView(contentMessage: "hello", isCurrentUser: true)
    }
}
