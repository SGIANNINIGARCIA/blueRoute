//
//  MessageView.swift
//  blueRoute
//
//  Created by Sandro Giannini on 11/17/22.
//

import SwiftUI

struct MessageView: View {
    
    var currentMessage: String;
    var displayName: String;
    var isSelf: Bool;
    
    var body: some View {
        HStack(alignment: .center, spacing: 24.0){
            if(!(isSelf)) {
                Avatar(username: displayName)
            } else {
                Spacer()
            }
            ContentMessageView(contentMessage: currentMessage, isCurrentUser: isSelf)
        }
        .padding(.leading)
    }
}

struct MessageView_Previews: PreviewProvider {
    
   // let user = UserModel(username: "Sandro Giannini", isSelf: true)
    
    
    
    static var previews: some View {
        MessageView(currentMessage: "this is a message", displayName:"Sandro Giannini", isSelf: false)
    }
}
