//
//  ChatCard.swift
//  blueRoute
//
//  Created by Sandro Giannini on 11/16/22.
//

import SwiftUI
import CoreData

struct ChatTile: View {
    
    var displayName:String;
    var id:UUID;
    
    @ObservedObject var adjacencyList : AdjacencyList;
    @FetchRequest var messages: FetchedResults<Message>;

    init(_ chatData: User, adjacencyList: AdjacencyList) {
        self.displayName = chatData.displayName ?? "";
        self.id = chatData.identifier ?? UUID();
        self.adjacencyList = adjacencyList;
        self._messages = FetchRequest<Message>(entity: Message.entity(),
                                               sortDescriptors: [NSSortDescriptor(keyPath: \Message.timestamp, ascending: false)],
                                               predicate: NSPredicate(format: "chat.identifier == %@", id as CVarArg),
                                               animation: .default)

    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 28.0) {
            Avatar(username: displayName)
            VStack(alignment: .leading, spacing: 4.0) {
                HStack{
                    Text(displayName)
                    .fontWeight(.bold)
                    AvailabilityTagView(isReachable: $adjacencyList.adjacencies.contains(where: {$0.id == id}))
                }
                if messages.first != nil {
                    Text(messages.first?.content ?? "")
                        .fontWeight(.light)
                        .lineLimit(1)
                }
            }
            Spacer()
            if messages.first != nil && messages.first?.seen == false {
            Text("\(messages.count(where: {$0.seen == false}))")
                .font(.callout)
                    .fontWeight(.thin)
                    .foregroundColor(Color.gray)
            }
        }
        .padding(.all, 10.0)
        
    }
}

struct ChatTile_Previews: PreviewProvider {
    
    static var previews: some View {
        ChatTile(User(), adjacencyList: AdjacencyList())
    }
}

extension Collection {
    func count(where test: (Element) throws -> Bool) rethrows -> Int {
        return try self.filter(test).count
    }
}
