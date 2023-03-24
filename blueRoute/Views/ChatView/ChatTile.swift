//
//  ChatCard.swift
//  blueRoute
//
//  Created by Sandro Giannini on 11/16/22.
//

import SwiftUI
import CoreData

struct ChatTile: View {
    
    var username:String;
    var lastMessage:String;
    var id:UUID;
    
    @ObservedObject var adjacencyList : AdjacencyList;
    @FetchRequest var last: FetchedResults<Message>;

    init(username: String, lastMessage:String, id: UUID, adjacencyList: AdjacencyList) {
        self.username = username;
        self.lastMessage = lastMessage;
        self.id = id;
        self.adjacencyList = adjacencyList;
        
    
         let request: NSFetchRequest<Message> = Message.fetchRequest()
         request.predicate = NSPredicate(format: "chat.identifier == %@", id as CVarArg)

         request.sortDescriptors = [
             NSSortDescriptor(keyPath: \Message.timestamp, ascending: true)
         ]

         request.fetchLimit = 1
         _last = FetchRequest(fetchRequest: request)
        /*
        self._last = FetchRequest<Message>(entity: Message.entity(),
                                           sortDescriptors: [NSSortDescriptor(keyPath: \Message.timestamp, ascending: true)],
                                               predicate: NSPredicate(format: "chat.identifier == %@", id as CVarArg),
                                               animation: .default)
         */
        
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 28.0) {
            Avatar(username: username)
            VStack(alignment: .leading, spacing: 4.0) {
                HStack{
                    Text(username)
                    .fontWeight(.bold)
                    AvailabilityTagView(isReachable: $adjacencyList.adjacencies.contains(where: {$0.id == id}))
                }
                Text(last[0].content ?? "Message")
                    .fontWeight(.light)
                    .lineLimit(1)
            }
            Spacer()
        }
        .padding(.all, 10.0)
        
    }
}

struct ChatTile_Previews: PreviewProvider {
    
    static var previews: some View {
        ChatTile(username: "May Phan", lastMessage: "Hello", id: UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!, adjacencyList: AdjacencyList())
    }
}
