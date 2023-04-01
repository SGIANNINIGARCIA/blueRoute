//
//  MessageView.swift
//  blueRoute
//
//  Created by Sandro Giannini on 11/17/22.
//

import SwiftUI

struct MessageView: View {
    
    var message: Message
    
    var body: some View {
        HStack(alignment: .center, spacing: 24.0){
            if(!(message.senderIsSelf)) {
                Avatar(username: message.chat?.displayName ?? "")
                ContentMessageView(contentMessage: message.content ?? "", isCurrentUser: message.senderIsSelf)
                Spacer()
            } else {
                Spacer()
                ContentMessageView(contentMessage: message.content ?? "", isCurrentUser: message.senderIsSelf)
            }
        }
        .padding(.leading)
    }
}

struct MessageView_Previews: PreviewProvider {
    static var previews: some View {
        MessageView(message: Message())
    }
}
