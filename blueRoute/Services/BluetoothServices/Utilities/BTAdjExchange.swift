//
//  BTAdjExchange.swift
//  blueRoute
//
//  Created by Sandro Giannini on 3/7/23.
//

import Foundation

enum ExchangeMessageType: String, Codable {
    case handshakeAdjExchange
    case exchangeRequest
    case exchangePackage
    case packageAcknowledgement
}

/// Wrapper message to communicate through the adjExchangeCharacteristicID characteristic
/// where the type determines the payload to expect
struct BTAdjacencyExchangeMessage: Codable {
    var type: ExchangeMessageType;
    var sender: String;
    var messagePayload: Data;
 
    enum CodingKeys: String, CodingKey {
        case type
        case sender
        case messagePayload
    }
    
    public static func BTAdjacencyExchangeMessageDecoder(message: String) -> BTAdjacencyExchangeMessage? {
        
        //2 - Convert the string to data
        let messageData = Data(message.utf8)

        //3 - Create a JSONDecoder instance
        let jsonDecoder = JSONDecoder()
        
        //4 - set the keyDecodingStrategy to convertFromSnakeCase on the jsonDecoder instance
        jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
        
        //5 - Use the jsonDecoder instance to decode the json into a Person object
        do {
            let decodedMessage = try jsonDecoder.decode(BTAdjacencyExchangeMessage.self, from: messageData)
            print("Sender -- \(decodedMessage.sender) of type: \(decodedMessage.type)")
            return decodedMessage;
        } catch {
            print("Error: \(error.localizedDescription)")
            return nil;
        }
        
    }
    
    public static func BTAdjacencyExchangeMessageEncoder(message: BTAdjacencyExchangeMessage) -> Data? {
                
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


/// used to request a new adjacencyList update from a connected edge
/// the connected edge can use the information to determine if an exchange is warranted
struct AdjacencyExchangeRequest: Codable {
    
    ///  Member describes the last time we received a AdjacencyList from the user and it is used
    ///  by the receiving user to determine if a new exchange is needed by comparing it with the last time their
    ///  adjacencyList was updated
    var lastUpdateReceived: Date;
    
    enum CodingKeys: String, CodingKey {
        case lastUpdateReceived
    }
    
    
    
    public static func AdjacencyExchangeRequestDecoder(message: String) -> AdjacencyExchangeRequest? {
        
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
    
    public static func AdjacencyExchangeRequestEncoder(message: AdjacencyExchangeRequest) -> Data? {
                
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

/// struct used to send data containing a segment/chunk of BTAdjacencyList
struct AdjacencyExchangePackage: Codable {
    /// the total amount of segments/chunks to be sent
    var packageTotalCount: Int;
    /// the current number of packages sent
    var currentPackageNumber: Int;
    /// data segment of a BTAdjacencyList
    var payload: Data;
    
    enum CodingKeys: String, CodingKey {
        case packageTotalCount
        case currentPackageNumber
        case payload
    }
    
    public static func AdjacencyExchangePackageDecoder(message: String) -> AdjacencyExchangePackage? {
        
        //2 - Convert the string to data
        let messageData = Data(message.utf8)

        //3 - Create a JSONDecoder instance
        let jsonDecoder = JSONDecoder()
        
        //4 - set the keyDecodingStrategy to convertFromSnakeCase on the jsonDecoder instance
        jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
        
        //5 - Use the jsonDecoder instance to decode the json into a Person object
        do {
            let decodedMessage = try jsonDecoder.decode(AdjacencyExchangePackage.self, from: messageData)
            return decodedMessage;
        } catch {
            print("Error: \(error.localizedDescription)")
            return nil;
        }
        
    }
    
    public static func AdjacencyExchangePackageEncoder(message: AdjacencyExchangePackage) -> Data? {
                
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

/// used to request a acknowledge when a Adjacency data chunk has been received
/// and begin the delivery of the next chunk, if any
struct AdjacencyPackageAcknowledgement: Codable {
    
    ///  Member describes the quantity of packages we have received so far
    var receivedPackageNumber: Int;
    
    enum CodingKeys: String, CodingKey {
        case receivedPackageNumber
    }
    
    public static func AdjacencyPackageAcknowledgementDecoder(message: String) -> AdjacencyPackageAcknowledgement? {
        
        //2 - Convert the string to data
        let messageData = Data(message.utf8)

        //3 - Create a JSONDecoder instance
        let jsonDecoder = JSONDecoder()
        
        //4 - set the keyDecodingStrategy to convertFromSnakeCase on the jsonDecoder instance
        jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
        
        //5 - Use the jsonDecoder instance to decode the json into a Person object
        do {
            let decodedMessage = try jsonDecoder.decode(AdjacencyPackageAcknowledgement.self, from: messageData)
            return decodedMessage;
        } catch {
            print("Error: \(error.localizedDescription)")
            return nil;
        }
        
    }
    
    public static func AdjacencyPackageAcknowledgementEncoder(message: AdjacencyPackageAcknowledgement) -> Data? {
                
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
