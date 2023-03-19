//
//  ChatCard.swift
//  blueRoute
//
//  Created by Sandro Giannini on 11/16/22.
//

import SwiftUI

struct ChatTile: View {
    
    @State var username:String;
    @State var lastMessage:String;
    @State var id:UUID;
    
    @ObservedObject var adjacencyList : AdjacencyList;

    
    var body: some View {
        HStack(alignment: .center, spacing: 28.0) {
            Avatar(username: username)
            VStack(alignment: .leading, spacing: 4.0) {
                HStack{
                    Text(username)
                    .fontWeight(.bold)
                    AvailabilityTagView(isReachable: $adjacencyList.adjacencies.contains(where: {$0.id == id}))
                }
                Text(lastMessage)
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
