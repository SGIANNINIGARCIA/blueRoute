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
    var selfVertex: Vertex!;
    
    /// members used to check whether we need to send
    /// a requesting user our adjacencyList
    var timeOfLastUpdate: Date?
    var lastUpdateTriggeredBy: UUID?;
    
    init() {
    }
    
    func setSelf(name: String){
        self.selfVertex = Vertex(name: name)
        self.adjacencies.append(self.selfVertex)
    }
    
    /// Creates a vertex with the given name, adds it to adjacencies and returns the new vertex
    func createVertex(name: String) -> Vertex {
        let newVertex = Vertex(name: name)
        adjacencies.append(newVertex)
        return newVertex;
        
    }
    
    /// Creates a vertex with the given name and the reference to the peripheral, adds it to adjacencies and returns the new vertex
    func createVertex(name: String, peripheral: CBPeripheral) -> Vertex {
        let newVertex = Vertex(name: name, peripheral: peripheral)
        adjacencies.append(newVertex)
        return newVertex;
        
    }
  
    /// Creates a vertex with the given name and the reference to the central, adds it to adjacencies and returns the new vertex
    func createVertex(name: String, central: CBCentral) -> Vertex {
        let newVertex = Vertex(name: name, central: central)
        
        adjacencies.append(newVertex)
        return newVertex;
        
    }
    
    /// adds an new edge to the source and sets the destination to be the passed vertex
    func addEdge(between source: Vertex, and destination: Vertex) {
        let newEdge = Edge(source: source, destination: destination)
        source.edges.append(newEdge)
    }
    
    /// returns all the edges belonging to the given source vertex
    func edges(from source: Vertex) -> [Edge] {
        return source.edges;
    }
    
    /// returns all the Vertices who are edges to self
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
        
        return self.selfVertex.edges.contains(where: {$0.destination.id == BluetoothController.retrieveID(name: name)})
    }
    
    /// Check if an user is our neighbor
    ///
    /// - Parameters:
    ///     - id:  the target user's ID
    ///
    /// - returns: A boolean, true if the user is a neighbor, false if not
    ///
    func isNeighbor(_ id: UUID) -> Bool {
        return self.selfVertex.edges.contains(where: {$0.destination.id == id})
    }
    
    /// Check if an user is our neighbor
    ///
    /// - Parameters:
    ///     - id:  the target user's ID
    ///
    /// - returns: A boolean, true if the user is a neighbor, false if not
    ///
    func notANeighbor(_ id: UUID) -> Bool {
        if(id == selfVertex.id) {return false}
        return self.selfVertex.edges.contains(where: {$0.destination.id != id})
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
    
    // Used to update our adjecency list with one passed by another device
    public func buildEdgeList(source: Vertex, userList: [String]) {
        
        // 1. retrieve the existing edges
        let existingEdges: [Edge] = source.edges;
        
        // 2. Remove outdated edges
        // If the list has an edge not on the new list passed by the device, then
        // we must remove the existing edge and pass it to removeVertex to check if
        // the resulting change creates a subset and remove it
        for existingEdge in existingEdges {
            if (!userList.contains(where: {BluetoothController.retrieveID(name: $0) == existingEdge.destination.id})) {
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
        
       // print("issue is now ehre \(name)")
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
    
    
    /// method to remove a vertex who is also our edge - so we lost a direct connection to that device
    public func removeConnection(_ vertexToRemove: Vertex){
        print("found \(vertexToRemove.displayName) - remove edge from self")
        
        // Remove the edge where source is self and dest is the user to be removed
        removeEdge(remove: vertexToRemove, from: self.selfVertex)
        self.selfVertex.edgesLastUpdated = Date()
        self.lastUpdateTriggeredBy = vertexToRemove.id;
        self.timeOfLastUpdate = Date();
        
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
    
    /// Method to process an incoming handshake from a central, check if it exist, and create/update the vertex
    ///
    /// - Parameters:
    ///     - user: The fullName of the user who we connected to
    ///     - central: a reference to the central who sent the handshake
    public func processHandshake(from user: String, central: CBCentral) -> Vertex {
        
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
                self.selfVertex.edgesLastUpdated = Date();
            }
            
            return userVertex;
            
        } else {
            // This is a new edge so we must create the vertex and add an edge to ourselves
            let newUserVertex = createVertex(name: user, central: central)
            addEdge(between: self.selfVertex, and: newUserVertex)
            self.selfVertex.edgesLastUpdated = Date();
            return newUserVertex;
        }
    }
    
    /// Method to process an incoming handshake from a peripheral, check if it exist, and create/update the vertex
    ///
    /// - Parameters:
    ///     - user: The fullName of the user who we connected to
    ///     - peripheral: a reference to the peripheral who sent the handshake
    public func processHandshake(from user: String, peripheral: CBPeripheral) -> Vertex {
        
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
                self.selfVertex.edgesLastUpdated = Date();
            }
            
            return userVertex;
            
        } else {
            // This is a new edge so we must create the vertex and add an edge to ourselves
            let newUserVertex = createVertex(name: user, peripheral: peripheral)
            addEdge(between: self.selfVertex, and: newUserVertex)
            self.selfVertex.edgesLastUpdated = Date();
            return newUserVertex;
            
        }
        
    }
    
}


extension AdjacencyList {
    
    // Convert Adjecency List into an dictionary where
    // key is the vertex's fullname (displayName+separator+ID) and the value is an array containing
    // the fullname (displayName+separator+ID) of all the edges
    public func processListForExchange() -> [ExchangeVertex] {
        
        let adjacencies = self.adjacencies;
        var processedList = [ExchangeVertex]();
        
        for (vertex) in adjacencies {
            
            var edges = [String]()
            
            for edge in vertex.edges {
                edges.append(String(adjacencies.firstIndex(where: {$0.id == edge.destination.id})!))
            }
            
            let vertexToSend = ExchangeVertex(name: vertex.fullName, lastUpdated: vertex.edgesLastUpdated, edges: edges)
            
            processedList.append(vertexToSend)
        }
        
        return processedList;
    }
    
    /// Method to handle a AdjacencyList shared by one of our neighbors
    ///
    /// - Parameters:
    ///     - user: The vertex who sent the adjacency list to process
    ///     - adjList: the compressed AdjacencyList of the sender
    public func processReceivedExchangedList(from userVertex: Vertex, compressedAdjList: CompressedAdjacencyList) {
        
        // Since the user shared the list, we can assume we have a direct connection to
        // this user, so we add this user as one of our edges
        
        // First, we check if the edge exists and if it doesn't then create the edge
        let edgeExists = self.selfVertex.edges.contains(where: {$0.destination == userVertex})
        
        
        if(!edgeExists) {
            addEdge(between: self.selfVertex, and: userVertex)
        }
        
        self.lastUpdateTriggeredBy = userVertex.id
        self.timeOfLastUpdate = Date()
        
        mergeExchangedAdjacencies(compressedAdjList);
        
    }
    
    /// Merges our adjacency list with one shared by one of our neighbors
    ///
    /// - Parameters:
    ///     - adjacencies: The compressed version of our neighbor's adjacency list
    public func mergeExchangedAdjacencies(_ compressedAdjacencies: CompressedAdjacencyList) {
        
        /// decompressed list
        let adjacencies = compressedAdjacencies.decompressList();
        
        for (vertex) in adjacencies {
            
            if(vertex.name == selfVertex.fullName) {continue}
            
            /// determine if the edgesLastUpdated value we have and the one shared are nil so we can compare
            let sharedVertexHasDate = vertex.lastUpdated != nil;
            
            /// check if we already have the vertex in our adjecency list
            /// and use the existing vertex to re-build/update it's edge list
            if let existingVertex = findVertex(vertex.name) {
                
                /// determine if the edgesLastUpdated value we have and the one shared are nil so we can compare
                let existingVertexHasDate = existingVertex.edgesLastUpdated != nil;
                
                /// if they are not nil, then compare the dates
                /// else only rebuild the edge list if our value for the date is nil
                if(existingVertexHasDate && sharedVertexHasDate) {
                    
                    /// if the list shared by the neighbor is more updated than ours, then rebuild this vertex's edge list
                    if(existingVertex.edgesLastUpdated! < vertex.lastUpdated!) {
                        buildEdgeList(source: existingVertex, userList: vertex.edges)
                        existingVertex.setEdgesLastUpdated(vertex.lastUpdated!)
                    }
                } else if(existingVertexHasDate == false) {
                    buildEdgeList(source: existingVertex, userList: vertex.edges)
                    if(sharedVertexHasDate) {existingVertex.setEdgesLastUpdated(vertex.lastUpdated!)}
                }
            } else {
                let newVertex = createVertex(name: vertex.name);
                buildEdgeList(source: newVertex, userList: vertex.edges)
                if(sharedVertexHasDate) {newVertex.setEdgesLastUpdated(vertex.lastUpdated!)}
            }
        }
        
    }
}

extension AdjacencyList {
    
    func getReachables() -> [Vertex] {
        
        var reachableList: [Vertex] = []
        var neighbors = getNeighbors();
        
        for vertex in adjacencies {
            var vertexIsNeighbor = neighbors.contains(where: {$0.id == vertex.id})
            
            if(vertexIsNeighbor == false && vertex.id != self.selfVertex.id) {
                reachableList.append(vertex)
            }
        }
        
        return reachableList;
        
    }
}
