//
//  ExchangeVertex.swift
//  blueRoute
//
//  Created by Sandro Giannini on 2/28/23.
//

import Foundation

/// Struct for sharing adjacency lists in between connected devices/nodes
/// Struct for sharing adjacency lists in between connected devices/nodes
/// CompressedAdjacencyList contains the complete adjacency list of the sender
struct CompressedAdjacencyList: Codable, Hashable {
    var sender: String
    var adjacencyList: [ExchangeVertex]
    
    enum CodingKeys: String, CodingKey {
        case sender
        case adjacencyList
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(sender)
    }
    
    public static func decoder(message: String) -> CompressedAdjacencyList? {
        
        //2 - Convert the string to data
        let messageData = Data(message.utf8)

        //3 - Create a JSONDecoder instance
        let jsonDecoder = JSONDecoder()
        
        //4 - set the keyDecodingStrategy to convertFromSnakeCase on the jsonDecoder instance
        jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
        
        //5 - Use the jsonDecoder instance to decode the json into a Person object
        do {
            let decodedMessage = try jsonDecoder.decode(CompressedAdjacencyList.self, from: messageData)
            print("AdjacencyList sent by -- \(decodedMessage.sender)")
            return decodedMessage;
        } catch {
            print("Error: \(error.localizedDescription)")
            return nil;
        }
        
    }
    
    public static func encoder(message: CompressedAdjacencyList) -> Data? {
                
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = .prettyPrinted
        
        do {
            let encodeMessage = try jsonEncoder.encode(message)
            return encodeMessage;
        } catch {
            print(error.localizedDescription)
            return nil;
        }
    }
    
    public func decompressList() -> [ExchangeVertex] {
        
        var decompressedList: [ExchangeVertex] = []
        
        for (_, vertex) in adjacencyList.enumerated() {
            var newList: [String] = []
            
            for edge in vertex.edges {
                newList.append(adjacencyList[Int(edge)!].name)
            }
            
            decompressedList.append(ExchangeVertex(name: vertex.name, lastUpdated: vertex.lastUpdated, edges: newList))
        }
        
        return decompressedList;
    }
}

/// Exchange Vertex contains the info a single vertex,  it's connected edges and the last time
/// the connected edges list was updated
struct ExchangeVertex: Codable, Hashable {
    var name: String;
    var lastUpdated: Date?;
    var edges: [String]
    
    enum CodingKeys: String, CodingKey {
        case name
        case lastUpdated
        case edges
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}

