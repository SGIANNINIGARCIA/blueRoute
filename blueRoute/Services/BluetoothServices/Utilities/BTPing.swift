//
//  BTPing.swift
//  blueRoute
//
//  Created by Sandro Giannini on 2/9/23.
//

import Foundation

enum PingType: String, Codable {
    case initialPing
    case responsePing
}
struct BTPing: Codable {
    
    var pingType: PingType;
    var pingSender: String;
    var pingReceiver: String;
    var adjList: [ExchangeVertex]
    
    enum CodingKeys: String, CodingKey {
        case pingType
        case pingSender
        case pingReceiver
        case adjList
    }
}

// Encode/Decode methods
extension BTPing {
    
    public static func BTPingDecoder(message: String) -> BTPing? {
        
        //2 - Convert the string to data
        let messageData = Data(message.utf8)

        //3 - Create a JSONDecoder instance
        let jsonDecoder = JSONDecoder()
        
        //4 - set the keyDecodingStrategy to convertFromSnakeCase on the jsonDecoder instance
        jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
        
        //5 - Use the jsonDecoder instance to decode the json into a Person object
        do {
            let decodedMessage = try jsonDecoder.decode(BTPing.self, from: messageData)
            print("Sender -- \(decodedMessage.pingSender) sent ping")
            return decodedMessage;
        } catch {
            print(String(describing: error))
            return nil;
        }
        
    }
    
    public static func BTPingEncoder(message: BTPing) -> Data? {
                
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
