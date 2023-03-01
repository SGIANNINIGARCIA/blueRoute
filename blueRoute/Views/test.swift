//
//  test.swift
//  blueRoute
//
//  Created by Sandro Giannini on 2/11/23.
//

import SwiftUI

struct test: View {
    
    @ObservedObject var AdjMatrix = AdjacencyList(name: "Self#?id?1D89FDC1-8198-40E2-A724-F107CBFC7835")
    
    init() {
        
        // handshake with natalia, natalia passes her list as well
        // add natalia and her list
        var natalia = self.AdjMatrix.processExchangedList(from: "Natalia#?id?7E66E6E1-F3A5-4612-9B70-A9600BFD94F3", adjList: [
            ExchangeVertex(name: "Natalia#?id?7E66E6E1-F3A5-4612-9B70-A9600BFD94F3", lastUpdated: Date(), edges: ["Tamara#?id?4951E515-24B1-41DC-8DEE-EC8CB3192AB2", "Jose#?id?0984965D-AF9E-4D61-91F1-D5AC3D0D5531", "Clara#?id?58DBB803-CCFD-4B5A-8803-FB69FEB46065"])])
        
        var bryan = self.AdjMatrix.processExchangedList(from: "Bryan#?id?0497459A-1236-4AAB-A278-2BF07CA6AF3E", adjList: [
            ExchangeVertex(name: "Bryan#?id?0497459A-1236-4AAB-A278-2BF07CA6AF3E", lastUpdated: Date(), edges: ["Jose#?id?0984965D-AF9E-4D61-91F1-D5AC3D0D5531", "Vincent#?id?C1DBFC41-D0D8-4A95-A1BC-0B5147A03FCE","Natalia#?id?7E66E6E1-F3A5-4612-9B70-A9600BFD94F3", "May#?id?7DEE114C-A547-422B-840A-46FB1E3D48A0", "Self#?id?1D89FDC1-8198-40E2-A724-F107CBFC7835"]),
            ExchangeVertex(name: "May#?id?7DEE114C-A547-422B-840A-46FB1E3D48A0", lastUpdated: Date(), edges: ["Attican#?id?FD630F84-F139-4E60-A92B-88F74C6B7568"])])
        
       /* var bryan = self.AdjMatrix.processExchangedList(from: "Bryan#?id?0497459A-1236-4AAB-A278-2BF07CA6AF3E", adjList: [
            "Bryan#?id?0497459A-1236-4AAB-A278-2BF07CA6AF3E": ["Jose#?id?0984965D-AF9E-4D61-91F1-D5AC3D0D5531", "Vincent#?id?C1DBFC41-D0D8-4A95-A1BC-0B5147A03FCE","Natalia#?id?7E66E6E1-F3A5-4612-9B70-A9600BFD94F3", "May#?id?7DEE114C-A547-422B-840A-46FB1E3D48A0"],
            "Jose#?id?0984965D-AF9E-4D61-91F1-D5AC3D0D5531": [],
                        "Vincent#?id?C1DBFC41-D0D8-4A95-A1BC-0B5147A03FCE": [],
            "Natalia#?id?7E66E6E1-F3A5-4612-9B70-A9600BFD94F3": ["Tamara#?id?4951E515-24B1-41DC-8DEE-EC8CB3192AB2", "Jose#?id?0984965D-AF9E-4D61-91F1-D5AC3D0D5531", "Clara#?id?58DBB803-CCFD-4B5A-8803-FB69FEB46065"],
            "May#?id?7DEE114C-A547-422B-840A-46FB1E3D48A0": []
        ])
        */
                       
        /*
        var bryan = (self.AdjMatrix.updateList(with: "Bryan#?id?0497459A-1236-4AAB-A278-2BF07CA6AF3E", userList: ["Jose#?id?0984965D-AF9E-4D61-91F1-D5AC3D0D5531", "Vincent#?id?C1DBFC41-D0D8-4A95-A1BC-0B5147A03FCE","Natalia#?id?7E66E6E1-F3A5-4612-9B70-A9600BFD94F3", "May#?id?7DEE114C-A547-422B-840A-46FB1E3D48A0"]))
        var attican = (self.AdjMatrix.updateList(with: "Attican#?id?FD630F84-F139-4E60-A92B-88F74C6B7568", userList: ["May#?id?7DEE114C-A547-422B-840A-46FB1E3D48A0"]))
        var gianfranco = (self.AdjMatrix.updateList(with: "Gianfranco#?id?5AB45AFD-7CBC-4E29-9DCA-4D0525F565E6", userList: ["Mimma#?id?624D4E63-944E-4138-B3EE-2E03E6FE6735", "Arturo#?id?0D2F1485-0C54-4A51-B598-9CC5685107C2"]))
        
        var arturo = self.AdjMatrix.findVertex("Arturo#?id?0D2F1485-0C54-4A51-B598-9CC5685107C2")!
        var carlos = self.AdjMatrix.createVertex(name: "Carlos#?id?71786EE2-9C01-462E-8824-82A09888FA5E")
        var roberto = self.AdjMatrix.createVertex(name: "Roberto#?id?5BE51CDF-C569-4B6E-BFD2-F44143876F37")
        var rebecca = self.AdjMatrix.createVertex(name: "Rebecca#?id?6EC1B6A4-7B1B-41B0-9035-F244F79A805E")
        
        self.AdjMatrix.addEdge(between: arturo, and: carlos)
        self.AdjMatrix.addEdge(between: carlos, and: roberto)
        self.AdjMatrix.addEdge(between: carlos, and: rebecca)
         */
        
        var te = self.AdjMatrix.bfs(from: self.AdjMatrix.findVertex("Self#?id?1D89FDC1-8198-40E2-A724-F107CBFC7835")!, to: self.AdjMatrix.findVertex("Attican#?id?FD630F84-F139-4E60-A92B-88F74C6B7568")!)
        
        for edge in te! {
            print("\(edge.source.displayName) -> \(edge.destination.displayName)")
        }
        
        for edge in self.AdjMatrix.selfVertex.edges {
            print("\(edge.destination.displayName)")
        }
        
        
    }
    
    
    var body: some View {
        List {
            ForEach(Array(self.AdjMatrix.adjacencies), id: \.self) {key  in
                HStack{
                    Text("\(key.displayName) ->")
                    ForEach(Array(key.edges), id: \.self) { vertex in
                        Text(vertex.destination.displayName)
                    }
                }
            }
        }
    }
}

struct test_Previews: PreviewProvider {
    static var previews: some View {
        test()
    }
}
