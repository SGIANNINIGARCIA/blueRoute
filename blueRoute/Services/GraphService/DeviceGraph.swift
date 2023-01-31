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

struct Edge {
    let source: Vertex;
    let destination: Vertex;
}

protocol DeviceGraph {
    func createVertex(username: String) -> Vertex
    func addEdge(between source: Vertex, and destination: Vertex)
    func edges(from source: Vertex) -> [Edge]
}

class AdjacencyList: DeviceGraph {
    
    private var adjacencies: [Vertex: [Edge]] = [:]
    
    init() {}
    
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




