//
//  DeviceGraph.swift
//  blueRoute
//
//  Created by Sandro Giannini on 11/25/22.
//

import Foundation

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
    
    @Published public var adjacencies: [Vertex: [Edge]] = [:]
    var selfVertex: Vertex?
    
    init() {}
    
    func setSelf(name: String) -> Vertex {
        self.selfVertex = createVertex(name: name)
        
        return self.selfVertex!;
    }
    
    func createVertex(name: String) -> Vertex {
        
        let newVertex = Vertex(name: name)
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
    
}


extension AdjacencyList {
    
    public func updateList(with user: String, userList: [String]) -> Vertex{
        
        if let userVertex = findVertex(user) {
            // Since this is a 2 degree list, if the device receive a new-
            // user/userlist, it came froma new connection we made,
            // so it is assumed we have a direct connection to this new
            // user, hence we need to add it to our edge list
            
            // if we already have an edge to this user, then we just rebuild the list
            if let _ = self.adjacencies[selfVertex!]?.contains(where: {$0.destination.id == userVertex.id}) {
                buildEdgeList(source: userVertex, userList: userList)
                return userVertex;
            }
            
            addEdge(between: self.selfVertex!, and: userVertex)
            buildEdgeList(source: userVertex, userList: userList)
            return userVertex;
            
        } else {
            let newUserVertex = createVertex(name: user)
            // Since this is a 2 degree list, if the device receive a new-
            // user/userlist, it came froma new connection we made,
            // so it is assumed we have a direct connection to this new
            // user, hence we need to add it to our edge list
            addEdge(between: self.selfVertex!, and: newUserVertex)
            buildEdgeList(source: newUserVertex, userList: userList)
            
            return newUserVertex;
        }
    }
    
    public func buildEdgeList(source: Vertex, userList: [String]) {
        
        // 1. retrieve the existing edges
        guard let existingEdges: [Edge] = self.adjacencies[source] else {
            // Vertex does not have an edge list in our adj list
            return;
        }
        
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
                if (existingEdges.contains(where: {$0.destination.fullName == name})) {
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
        let vertexIndex = adjacencies.firstIndex(where: { $0.key.fullName == name })
        
        // return the vertex at that index, if vertexIndex is not nil
        if let index = vertexIndex {
            return adjacencies[index].key
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
        removeEdge(remove: vertexToRemove, from: self.selfVertex!)
        
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
            let connectedEdges = self.adjacencies[vertexToRemove]
            
            // 3. remove the vertex
            if let index = self.adjacencies.firstIndex(where: {$0.key.fullName == vertexToRemove.fullName}) {
                self.adjacencies.remove(at: index)
            }
            // 4. repeat the process with all the destination vertices
            for element in connectedEdges ?? [] { removeVertex(element.destination)
            }
        }
        
    }
    
    public func removeEdge(remove edgeToRemove: Vertex, from source: Vertex) {
        self.adjacencies[source]?.removeAll(where: {$0.destination.fullName == edgeToRemove.fullName})
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

extension DeviceGraph {
    
    public static func processForExchange(_ adjecency: [Vertex: [Edge]]) -> [String: [String]] {
        
        var processedList = [String: [String]]();
        
        for (key, values) in adjecency {
            var edges = [String]()
            
            for edge in values {
                edges.append(edge.destination.displayName)
            }
            
            processedList[key.displayName] = edges;
        }
        
        return processedList;
    }
}
