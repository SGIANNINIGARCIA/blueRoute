//
//  ChatView.swift
//  blueRoute
//
//  Created by Sandro Giannini on 11/17/22.
//

import SwiftUI

struct ChatView: View {
    
    // Username of the user this chat is with
    var id: UUID;
    var displayName: String;
    
    // variable to hold stored messages belonging to this chat
    @FetchRequest var messages: FetchedResults<Message>;
    
    init(displayName: String, id: UUID) {
        self.id = id;
        self.displayName = displayName;
        self._messages = FetchRequest<Message>(entity: Message.entity(),
                                               sortDescriptors: [NSSortDescriptor(keyPath: \Message.timestamp, ascending: true)],
                                               predicate: NSPredicate(format: "chat.identifier == %@", id as CVarArg),
                                               animation: .default)
    }
    
    var body: some View {
        VStack {
            List {
                ForEach(messages) { message in
                    
                    MessageView(currentMessage: message.content!, displayName: (message.chat?.displayName)!, isSelf: message.senderIsSelf)
                        .listRowSeparator(.hidden)
                    
                }
            }.listStyle(PlainListStyle())
            
            TextInputView(displayName: displayName, id: id)
            
            
        }
        .navigationBarTitle(Text(self.displayName), displayMode: .inline)
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView(displayName: "Testing Subject", id: UUID())
    }
}
