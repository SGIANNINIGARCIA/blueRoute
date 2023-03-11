//
//  AdjacencyExchangeRequest.swift
//  blueRoute
//
//  Created by Sandro Giannini on 3/11/23.
//

import Foundation


/// Struct used to request a new adjacencyList update from a connected edge
/// the connected edge can use the information to determine if an exchange is warranted
///
/// - Member:
///     - lastUpdateReceived: Date of the last time the receiver of the request sent their AdjacencyList
struct AdjacencyExchangeRequest: Codable {
    
    ///  Member describes the last time we received a AdjacencyList from the user and it is used
    ///  by the receiving user to determine if a new exchange is needed by comparing it with the last time their
    ///  adjacencyList was updated
    var lastUpdateReceived: Date?;
    
    enum CodingKeys: String, CodingKey {
        case lastUpdateReceived
    }
    
    
    
    public static func decoder(message: String) -> AdjacencyExchangeRequest? {
        
        //2 - Convert the string to data
        let messageData = Data(message.utf8)

        //3 - Create a JSONDecoder instance
        let jsonDecoder = JSONDecoder()
        
        //4 - set the keyDecodingStrategy to convertFromSnakeCase on the jsonDecoder instance
        jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
        
        //5 - Use the jsonDecoder instance to decode the json into a Person object
        do {
            let decodedMessage = try jsonDecoder.decode(AdjacencyExchangeRequest.self, from: messageData)
            return decodedMessage;
        } catch {
            print("Error: \(error.localizedDescription)")
            return nil;
        }
        
    }
    
    public static func encoder(message: AdjacencyExchangeRequest) -> Data? {
                
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
}
