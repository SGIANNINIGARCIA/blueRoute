//
//  DeviceGraph.swift
//  blueRoute
//
//  Created by Sandro Giannini on 11/25/22.
//

import Foundation

struct Vertex: Hashable, Equatable {
    let username: String;
    
    // Defining Equatable function in case we add other variables in the future (CBPeripheral?)
    static func ==(lhs: Vertex, rhs: Vertex) -> Bool {
        return lhs.username == rhs.username
    }
    
    // Defining Hashable function in case we add other variables in the future (CBPeripheral?)
    func hash(into hasher: inout Hasher) {
        hasher.combine(username)
    }
}

struct Edge: Hashable {
    let source: Vertex;
    let destination: Vertex;
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(source.username)
    }
}

protocol DeviceGraph {
    func createVertex(username: String) -> Vertex
    func addEdge(between source: Vertex, and destination: Vertex)
    func edges(from source: Vertex) -> [Edge]
}

class AdjacencyList: DeviceGraph, ObservableObject  {
    
    @Published public var adjacencies: [Vertex: [Edge]] = [:]
    var selfVertex: Vertex?
    
    init() {}
    
    func setSelf(username: String) -> Vertex {
        self.selfVertex = createVertex(username: username)
        
        return self.selfVertex!;
    }
    
    func createVertex(username: String) -> Vertex {
        
        let newVertex = Vertex(username: username)
        adjacencies[newVertex] = []
        return newVertex;
            
    }
    
    func addEdge(between source: Vertex, and destination: Vertex) {
        
        let newEdge = Edge(source: source, destination: destination)
        adjacencies[source]?.append(newEdge)
        
    }
    
    func edges(from source: Vertex) -> [Edge] {
        
        return adjacencies[source] ?? []
        
    }
    
    func printVertices() -> [String] {
      var toBeRe = [String]()
        for (vertex, _) in adjacencies {
            toBeRe.append(vertex.username)
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
    
}


extension AdjacencyList {
    
    public func updateList(with user: String, userList: [String]) -> Vertex{
        
        if let userVertex = findVertex(user) {
            // Since this is a 2 degree list, if the device receive a new-
            // user/userlist, it came froma new connection we made,
            // so it is assumed we have a direct connection to this new
            // user, hence we need to add it to our edge list
            print("found the user \(userVertex.username)")
            addEdge(between: self.selfVertex!, and: userVertex)
            let newEdges = buildEdgeList(source: userVertex, userList: userList)
            
            adjacencies[userVertex] = newEdges;
            
            return userVertex;
        } else {
            let newUserVertex = createVertex(username: user)
            // Since this is a 2 degree list, if the device receive a new-
            // user/userlist, it came froma new connection we made,
            // so it is assumed we have a direct connection to this new
            // user, hence we need to add it to our edge list
            print("new user \(newUserVertex.username)")
            addEdge(between: self.selfVertex!, and: newUserVertex)
            let newEdges = buildEdgeList(source: newUserVertex, userList: userList)
            adjacencies[newUserVertex] = newEdges
            
            return newUserVertex;
        }
    }
    
    public func buildEdgeList(source: Vertex, userList: [String]) -> [Edge] {
        var edgeList = [Edge]();
        
        for name in userList {
            if let userVertex = findVertex(name) {
                print("user exists \(userVertex.username) - appending to \(source.username)")
                edgeList.append(Edge(source: source, destination: userVertex))
            } else {
                let newUserVertex = createVertex(username: name)
                print("user does NOT exist \(newUserVertex.username) - appending to \(source.username)")
                edgeList.append(Edge(source: source, destination: newUserVertex))
            }
        }
        
        return edgeList;
    }
    
    
    
    public func findVertex(_ name: String) -> Vertex? {
        // Get the index, if there is one
        let vertexIndex = adjacencies.firstIndex(where: { $0.key.username == name })
        
        // return the vertex at that index, if vertexIndex is not nil
        if let index = vertexIndex {
            return adjacencies[index].key
        } else {
            return nil;
        }
    }
    
    public func removeConnection(_ name: String){
        
        var test = ""
        
        // 1. find the vertex we want to remove
        guard let vertexToRemove = findVertex(name) else {
            print("unable to find vertex to remove")
            return;
        }
        
        print("found \(vertexToRemove.username) - remove edge from self")
        
        removeEdge(remove: vertexToRemove, from: self.selfVertex!)
        
        removeVertex(name)
        
        
    }
    
    
    public func removeVertex(_ name: String) {
        
        
        // 1. find the vertex we want to remove
        guard let vertexToRemove = findVertex(name) else {
            print("unable to find vertex to remove")
            return;
        }
        
        // 3. check if there is a path to it without our edge
        if !isReachable(vertexToRemove) {
            // 4. save all the vertices it is connected to for later
            let connectedEdges = self.adjacencies[vertexToRemove]
            
            // 5. remove the vertex
            if let index = self.adjacencies.firstIndex(where: {$0.key.username == vertexToRemove.username}) {
                self.adjacencies.remove(at: index)
            }
            
            for element in connectedEdges ?? [] { removeVertex(element.destination.username)
            }
        }
        
    }
    
    public func removeEdge(remove edgeToRemove: Vertex, from source: Vertex) {
        self.adjacencies[source]?.removeAll(where: {$0.destination.username == edgeToRemove.username})
    }
    
    public func isReachable(_ destination: Vertex) -> Bool {
        if let temp = bfs(from: selfVertex!, to: destination) {
            if(temp.count > 0) {
                return true;
            } else {
                return false;
            }
        }
        return false;
        
    }
}
