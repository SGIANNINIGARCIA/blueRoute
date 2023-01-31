//
//  ChatList.swift
//  blueRoute
//
//  Created by Sandro Giannini on 11/19/22.
//

import SwiftUI

struct ConversationsView: View {
    
    @Environment(\.managedObjectContext) var managedObjContext;
    @EnvironmentObject var dataController: DataController;
    @EnvironmentObject var bluetoothController: BluetoothController;
    @EnvironmentObject var chatsStorage: ChatsStorage;
    
    var body: some View {
        NavigationView {
            VStack{
                HStack {
                    Text("Conversations")
                        .font(Font.custom("LatoBold", size: 52))
                        .padding(.top, 16.0)
                        .padding(.leading, 16.0)
                    Spacer()
                }
                List {
                    ForEach(chatsStorage.chats) { chat in
                        NavigationLink {
                            ChatView(displayName: chat.displayName!, id: chat.identifier!)
                        } label: {
                            ChatTile(username: chat.displayName!, lastMessage: chat.latestMessage ?? "Message", id: chat.identifier!)
                        }
                
                    }
                    .onDelete(perform: removeConversation)
                }
                .emptyState(chatsStorage.chats.isEmpty) {
                      Text("No active conversations   :(")
                        .font(.title3)
                        .foregroundColor(Color.secondary)
                    }
                .navigationTitle("Conversations")
                .toolbar(Visibility.hidden)
            }
        }
    }

    func removeConversation(at offsets: IndexSet) {
        for index in offsets {
            let toBeDeleted = chatsStorage.chats[index]
            managedObjContext.delete(toBeDeleted)
        }
        dataController.save(context: managedObjContext)
        
    }
}

struct ConversationsView_Previews: PreviewProvider {
    static var previews: some View {
        ConversationsView()
    }
}
