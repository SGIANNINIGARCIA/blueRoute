//
//  ChatList.swift
//  blueRoute
//
//  Created by Sandro Giannini on 11/19/22.
//

import SwiftUI

struct ConversationsView: View {
    
 //   @Environment(\.managedObjectContext) var managedObjContext;
    
    @EnvironmentObject var dataController: DataController;
    @EnvironmentObject var bluetoothController: BluetoothController;
    
    @FetchRequest(sortDescriptors: []) private var chats: FetchedResults<User>
    
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
                    ForEach(chats) { chat in
                        NavigationLink {
                            ChatView(displayName: chat.displayName!, id: chat.identifier!)
                        } label: {
                            ChatTile(username: chat.displayName!, lastMessage: chat.latestMessage ?? "Message", id: chat.identifier!, adjacencyList: bluetoothController.adjList )
                        }
                
                    }
                    .onDelete(perform: removeConversation)
                }
                .emptyState(chats.isEmpty) {
                    VStack {
                        Text("No active conversations   :(")
                          .font(.title3)
                          .foregroundColor(Color.secondary)
                    }
                    }
                .navigationTitle("Conversations")
                .toolbar(Visibility.hidden)
            }
        }
    }

    func removeConversation(at offsets: IndexSet) {
        for index in offsets {
            let toBeDeleted = chats[index]
         //   managedObjContext.delete(toBeDeleted)
        }
     //   dataController.save(context: managedObjContext)
    }
}

struct ConversationsView_Previews: PreviewProvider {
    static var previews: some View {
        ConversationsView()
    }
}
