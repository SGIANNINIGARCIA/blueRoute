//
//  DeviceGraph.swift
//  blueRoute
//
//  Created by Sandro Giannini on 11/25/22.
//

import Foundation
import CoreBluetooth

struct Edge: Hashable {
    let source: Vertex;
    let destination: Vertex;
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(source.id)
    }
}

protocol DeviceGraph {
    func createVertex(name: String) -> Vertex
    func addEdge(between source: Vertex, and destination: Vertex)
    func edges(from source: Vertex) -> [Edge]
}

class AdjacencyList: DeviceGraph, ObservableObject  {
    
    @Published public var adjacencies: [Vertex] = []
    var selfVertex: Vertex;
    
    init(name: String) {
        self.selfVertex = Vertex(name: name)
        self.adjacencies.append(self.selfVertex)
        
        
    }
    
    func setSelf(name: String) -> Vertex {
        self.selfVertex = createVertex(name: name)
        
        return self.selfVertex;
    }
    
    func createVertex(name: String) -> Vertex {
        
        let newVertex = Vertex(name: name)
        adjacencies.append(newVertex)
        return newVertex;
            
    }
    
    func createVertex(name: String, peripheral: CBPeripheral) -> Vertex {
        
        let newVertex = Vertex(name: name, peripheral: peripheral)
        adjacencies.append(newVertex)
        return newVertex;
            
    }
    
    func createVertex(name: String, central: CBCentral) -> Vertex {
        
        let newVertex = Vertex(name: name, central: central)
        adjacencies.append(newVertex)
        return newVertex;
            
    }
    
    func addEdge(between source: Vertex, and destination: Vertex) {
        
        let newEdge = Edge(source: source, destination: destination)
        source.edges.append(newEdge)
        print("adding new edge between \(source.displayName) and \(destination.displayName)")
        
    }
    
    func edges(from source: Vertex) -> [Edge] {
        return source.edges;
    }
    
    func getNeighbors() -> [Vertex] {
        
        var neighbors: [Vertex] = [];
        
        for edge in self.selfVertex.edges {
            neighbors.append(edge.destination)
        }
        
        return neighbors;
    }
    
    /// Check if an user is our neighbor
    ///
    /// - Parameters:
    ///     - name:  the target user's full name (display name + ID)
    ///
    /// - returns: A boolean, true if the user is a neighbor, false if not
    ///
    func isNeighbor(_ name: String) -> Bool {
        
        let neighbors = getNeighbors()
        
        return neighbors.contains(where: {$0.fullName == name})
    }
    
    func printVertices() -> [String] {
      var toBeRe = [String]()
        for (vertex) in adjacencies {
            toBeRe.append(vertex.displayName)
        }
        
        return toBeRe;
        
    }
}

enum Visit {
  case source
  case edge(Edge)
}



extension AdjacencyList {
    
    // Breadth First Search
    public func bfs(from source: Vertex, to destination: Vertex)  -> [Edge]? {
        
        var queue = Queue<Vertex>();
        queue.enqueue(source)
        
        var visits : [Vertex: Visit] = [source: .source]
        
        while let visitedVertex = queue.dequeue() {
          if visitedVertex == destination {
            var vertex = destination // 1
            var route : [Edge] = [] // 2
              
              while let visit = visits[vertex],
                case .edge(let edge) = visit { // 3

                route = [edge] + route
                vertex = edge.source // 4

              }
              return route // 5
            }
            let neighbourEdges = edges(from: visitedVertex)
            for edge in neighbourEdges {
              if visits[edge.destination] == nil { // 2
                queue.enqueue(edge.destination)
                visits[edge.destination] = .edge(edge) // 3
              }
            }
          }
          return nil
        }
    
    /// Returns the next hop a message needs to be routed to
    ///
    /// - parameters:
    ///     -targetVertex: the final receiver of the message
    ///
    /// - returns: The vertex who the next hop
    func nextHop(_ targetVertex: Vertex) -> Vertex? {
        
        guard let path = bfs(from: selfVertex, to: targetVertex) else {
            return nil;
        }
        
        return path[0].destination
    }
    
}


extension AdjacencyList {
    
    public func processExchangedList(from user: String, adjList: [ExchangeVertex]) {
        
        // check if the user who shared the list exists in our adjecency list
        if let userVertex = findVertex(user) {
            // Since the user shared the list, we can assume we have a direct connection to
            // this user, so we add this user as one of our edges
            
            // First, we check if the edge exists and if it doesn't then create the edge
            let edgeExists = self.selfVertex.edges.contains(where: {$0.destination == userVertex})
            
            
            if(!edgeExists) {
                addEdge(between: self.selfVertex, and: userVertex)
            }
            
            updateList(with: adjList)
            
        } else {
            // This is a new edge so we must create the vertex and add an edge to ourselves
            let newUserVertex = createVertex(name: user)
            addEdge(between: self.selfVertex, and: newUserVertex)
            updateList(with: adjList)
            
        }
    }
    
    
    // Used to update our adjecency list with one passed by another vertex
    public func updateList(with exchangedList: [ExchangeVertex]) {
        
        
        for (vertex) in exchangedList{
            
            // 1. check if we already have the vertex in our adjecency list
            // and use the existing vertex to re-build/update it's edge list
            if let existingVertex = findVertex(vertex.name) {
                
                // 2. check if the edge list we received is more recent than
                // the one we currently have. If it is, then we proceed with updating it
                if(vertex.lastUpdated >= existingVertex.edgesLastUpdated ?? vertex.lastUpdated) {
                    buildEdgeList(source: existingVertex, userList: vertex.edges)
                    
                    // since we updated the edge list, then we also update the
                    // edges last updated member
                    existingVertex.edgesLastUpdated = vertex.lastUpdated
                }
                
            } else {
                // if not, then we create append a new vertex to our list and
                // build its edge list with the data shared by our edge
                let newVertex = createVertex(name: vertex.name)
                buildEdgeList(source: newVertex, userList: vertex.edges)
            }
        }
    }
    
    // Used to update our adjecency list with one passed by another device
    public func buildEdgeList(source: Vertex, userList: [String]) {
        
        // 1. retrieve the existing edges
        let existingEdges: [Edge] = source.edges;
        
        // 2. Remove outdated edges
        // If the list has an edge not on the new list passed by the device, then
        // we must remove the existing edge and pass it to removeVertex to check if
        // the resulting change creates a subset and remove it
        for existingEdge in existingEdges {
            if (!userList.contains(where: {$0 == existingEdge.destination.fullName})) {
                removeEdge(remove: existingEdge.destination, from: source)
                removeVertex(existingEdge.destination)
            }
        }
        
        // 3. itireate through the updated/new list
        for name in userList {

            // 4. check if the vertex already exist and use the reference
            if let userVertex = findVertex(name) {
                
                // 5. check if the edge already exists and skip if it does / no change
                if (existingEdges.contains(where: {$0.destination.id == BluetoothController.retrieveID(name: name)})) {
                    continue;
                }
                
                // 5. The edge is not on the list, so we add it
                addEdge(between: source, and: userVertex)
            } else {
                // 6. New Vertex, so we must create it
                let newUserVertex = createVertex(name: name)
                // 7. Append the edge
                addEdge(between: source, and: newUserVertex)
            }
        }
    }
    
    
    
    public func findVertex(_ name: String) -> Vertex? {
        // Get the index, if there is one
        
        print("issue is now ehre \(name)")
        if let vertexIndex = adjacencies.firstIndex(where: { $0.id == BluetoothController.retrieveID(name: name) }) {
            return adjacencies[vertexIndex]
        } else {
            return nil;
        }
    }
    
    public func removeConnection(_ name: String){
        
        // 1. find the vertex we want to remove
        guard let vertexToRemove = findVertex(name) else {
            print("unable to find vertex to remove")
            return;
        }
        
        print("found \(vertexToRemove.displayName) - remove edge from self")
        
        // Remove the edge where source is self and dest is the user to be removed
        removeEdge(remove: vertexToRemove, from: self.selfVertex)
        
        // Remove the vertex if there is no path to it
        // after we removed our edge to it
        if !isReachable(vertexToRemove) {
            removeVertex(vertexToRemove)
        }
    }
    
    public func removeConnection(_ vertexToRemove: Vertex){
        print("found \(vertexToRemove.displayName) - remove edge from self")
        
        // Remove the edge where source is self and dest is the user to be removed
        removeEdge(remove: vertexToRemove, from: self.selfVertex)
        self.selfVertex.edgesLastUpdated = Date()
        
        // Remove the vertex if there is no path to it
        // after we removed our edge to it
        if !isReachable(vertexToRemove) {
            removeVertex(vertexToRemove)
        }
    }
    
    
    public func removeVertex(_ vertexToRemove: Vertex) {
                
        // 1. check if there is a path to it without our edge
        if !isReachable(vertexToRemove) {
            // 2. save all the vertices it is connected to for later
            let connectedEdges = vertexToRemove.edges
            
            // 3. remove the vertex
            if let index = self.adjacencies.firstIndex(where: {$0 == vertexToRemove}) {
                self.adjacencies.remove(at: index)
            }
            // 4. repeat the process with all the destination vertices
            for element in connectedEdges { removeVertex(element.destination)
            }
        }
        
    }
    
    public func removeEdge(remove edgeToRemove: Vertex, from source: Vertex) {
        source.edges.removeAll(where: {$0.destination == edgeToRemove})
    }
    
    public func isReachable(_ destination: Vertex) -> Bool {
        if destination == selfVertex {return true;}
        if let temp = bfs(from: selfVertex, to: destination) {
            if(temp.count > 0) {
                return true;
            } else {
                return false;
            }
        }
        return false;
        
    }
}

extension AdjacencyList {
    
    // Convert Adjecency List into an dictionary where
    // key is the vertex's fullname (displayName+separator+ID) and the value is an array containing
    // the fullname (displayName+separator+ID) of all the edges
    public func processForExchange() -> [ExchangeVertex] {
        
        var processedList = [ExchangeVertex]();
        
        for (vertex) in self.adjacencies {
            
            var edges = [String]()
            
            for edge in vertex.edges {
                edges.append(edge.destination.fullName)
            }
            
            let vertexToSend = ExchangeVertex(name: vertex.fullName, lastUpdated: vertex.edgesLastUpdated ?? Date(), edges: edges)
            
            processedList.append(vertexToSend)
        }
        
        return processedList;
    }
    
    public func processForCompressedExchange() -> [ExchangeVertex] {
        
        var processedList = [ExchangeVertex]();
        
        for (vertex) in self.adjacencies {
            
            var edges = [String]()
            
            for edge in vertex.edges {
                edges.append(String(self.adjacencies.firstIndex(where: {$0.id == edge.destination.id})!))
            }
            
            let vertexToSend = ExchangeVertex(name: vertex.fullName, lastUpdated: vertex.edgesLastUpdated ?? Date(), edges: edges)
            
            processedList.append(vertexToSend)
        }
        
        return processedList;
    }
}




/*
 *
 * PROBABLY WILL UPDATE THE ORIGINAL TO ACCEPT CBPEER INSTEAD OF SPECIFIC CENTRAL/PERIPHERAL REF
 * BUT KEEPING IT HERE FOR NOW FOR TESTING
 *
 */

extension AdjacencyList {
    
    public func processExchangedList(from user: String, adjList: [ExchangeVertex], central: CBCentral) {
        
        // check if the user who shared the list exists in our adjecency list
        if let userVertex = findVertex(user) {
            // Since the user shared the list, we can assume we have a direct connection to
            // this user, so we add this user as one of our edges
            
            // Update the most recent CBPEER reference of the vertex if needed
            if(userVertex.sendTo != .central || userVertex.central != central) {
                userVertex.changeCentralReference(central)
            }
            
            // First, we check if the edge exists and if it doesn't then create the edge
            let edgeExists = self.selfVertex.edges.contains(where: {$0.destination == userVertex})
            
            
            if(!edgeExists) {
                addEdge(between: self.selfVertex, and: userVertex)
            }
            
            updateList(with: adjList)
            
        } else {
            // This is a new edge so we must create the vertex and add an edge to ourselves
            let newUserVertex = createVertex(name: user, central: central)
            addEdge(between: self.selfVertex, and: newUserVertex)
            updateList(with: adjList)
            
        }
    }
    
    public func processExchangedList(from user: String, adjList: [ExchangeVertex], peripheral: CBPeripheral) {
        
        // check if the user who shared the list exists in our adjecency list
        if let userVertex = findVertex(user) {
            // Since the user shared the list, we can assume we have a direct connection to
            // this user, so we add this user as one of our edges
            
            // Update the most recent CBPEER reference of the vertex if needed
            if(userVertex.sendTo != .peripheral || userVertex.peripheral != peripheral) {
                userVertex.changePeripheralReference(peripheral)
            }
            
            // First, we check if the edge exists and if it doesn't then create the edge
            let edgeExists = self.selfVertex.edges.contains(where: {$0.destination == userVertex})
            
            
            if(!edgeExists) {
                addEdge(between: self.selfVertex, and: userVertex)
            }
            
            updateList(with: adjList)
            
        } else {
            // This is a new edge so we must create the vertex and add an edge to ourselves
            let newUserVertex = createVertex(name: user, peripheral: peripheral)
            addEdge(between: self.selfVertex, and: newUserVertex)
            updateList(with: adjList)
            
        }
    }
    
}
