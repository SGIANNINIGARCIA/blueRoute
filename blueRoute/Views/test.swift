//
//  test.swift
//  blueRoute
//
//  Created by Sandro Giannini on 2/11/23.
//

import SwiftUI

struct test: View {
    
    @ObservedObject var AdjMatrix = AdjacencyList()
    var tempo = "false";
    
    init() {
        
        // initiate app with self
        let selfVertex = self.AdjMatrix.setSelf(username: "Self")
        
        // handshake with natalia, natalia passes her list as well
        // add natalia and her list
        var natalia = (self.AdjMatrix.updateList(with: "Natalia", userList: ["Tamara", "Jose", "Clara"]))
        var bryan = (self.AdjMatrix.updateList(with: "Bryan", userList: ["Jose", "Vincent", "May", "Natalia", "Attican"]))
        var attican = (self.AdjMatrix.updateList(with: "Attican", userList: ["May"]))
        var gianfranco = (self.AdjMatrix.updateList(with: "Gianfranco", userList: ["Mimma", "Arturo"]))
        
        var arturo = self.AdjMatrix.findVertex("Arturo")!
        var carlos = self.AdjMatrix.createVertex(username: "Carlos")
        var roberto = self.AdjMatrix.createVertex(username: "Roberto")
        var rebecca = self.AdjMatrix.createVertex(username: "Rebecca")
        
        self.AdjMatrix.addEdge(between: arturo, and: carlos)
        self.AdjMatrix.addEdge(between: carlos, and: roberto)
        self.AdjMatrix.addEdge(between: carlos, and: rebecca)
        
       tempo = self.AdjMatrix.removeConnection("Attican")
       /*
        for ver in self.AdjMatrix.bfs(from: self.AdjMatrix.selfVertex!, to: self.AdjMatrix.findVertex("Attican")!)! {
            tempo = tempo + ver.source.username
        }
        */
        
        
        
        
    
        
    }
    
    
    var body: some View {
        List {
            ForEach(Array(self.AdjMatrix.adjacencies.keys), id: \.self) {key  in
                HStack{
                    Text("\(key.username) ->")
                    ForEach(Array(self.AdjMatrix.adjacencies[key]!), id: \.self) { vertex in
                        Text(vertex.destination.username)
                    }
                }
            }
            Text("\(tempo)")
        }
    }
}

struct test_Previews: PreviewProvider {
    static var previews: some View {
        test()
    }
}
