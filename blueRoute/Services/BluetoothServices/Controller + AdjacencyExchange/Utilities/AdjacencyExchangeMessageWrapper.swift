//
//  BTAdjExchange.swift
//  blueRoute
//
//  Created by Sandro Giannini on 3/7/23.
//

import Foundation

enum ExchangeMessageType: String, Codable {
    case exchangeRequest
    case exchangePackage
    case packageAcknowledgement
}

/// Wrapper message to communicate through the adjExchangeCharacteristicID characteristic
///
/// - Members:
///     - type: the type contained in the messagePayload
///     - sender: Vertex who sent the message
///     - messagePayload: data speicifc to a service
struct AdjacencyExchangeMessageWrapper: Codable {
    var type: ExchangeMessageType;
    var sender: String;
    var messagePayload: Data;
 
    enum CodingKeys: String, CodingKey {
        case type
        case sender
        case messagePayload
    }
    
    public static func decoder(message: String) -> AdjacencyExchangeMessageWrapper? {
        
        print("this is the wrapped message \(message)")
        
        //2 - Convert the string to data
        let messageData = Data(message.utf8)

        //3 - Create a JSONDecoder instance
        let jsonDecoder = JSONDecoder()
        
        //4 - set the keyDecodingStrategy to convertFromSnakeCase on the jsonDecoder instance
        jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
        
        //5 - Use the jsonDecoder instance to decode the json into a Person object
        do {
            let decodedMessage = try jsonDecoder.decode(AdjacencyExchangeMessageWrapper.self, from: messageData)
            print("Sender -- \(decodedMessage.sender) of type: \(decodedMessage.type)")
            return decodedMessage;
        } catch {
            print("\(String(describing: error)) error at AdjacencyExchangeMessageWrapper decoder")
            return nil;
        }
        
    }
    
    public static func encoder(message: AdjacencyExchangeMessageWrapper) -> Data? {
                
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = .prettyPrinted
        
        do {
            let encodeMessage = try jsonEncoder.encode(message)
            return encodeMessage;
        } catch {
            print("\(String(describing: error)) error at AdjacencyExchangeMessageWrapper encoder")
            return nil;
        }
    }
}
