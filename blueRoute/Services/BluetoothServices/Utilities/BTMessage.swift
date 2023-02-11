//
//  BTMessage.swift
//  blueRoute
//
//  Created by Sandro Giannini on 11/24/22.
//

import Foundation

enum BTMessageType: String, Codable {
    case routing
    case chat
}

struct BTMessage: Codable {
    
    var sender: String;
    var message: String;
    var receiver: String;
    var type: BTMessageType;
    
    
    enum CodingKeys: String, CodingKey {
        case sender
        case message
        case receiver
        case type
    }
}

// Decode/Encode methods
extension BTMessage {
    
    public static func BTMessageDecoder(message: String) -> BTMessage? {
        
        //2 - Convert the string to data
        let messageData = Data(message.utf8)

        //3 - Create a JSONDecoder instance
        let jsonDecoder = JSONDecoder()
        
        //4 - set the keyDecodingStrategy to convertFromSnakeCase on the jsonDecoder instance
        jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
        
        //5 - Use the jsonDecoder instance to decode the json into a Person object
        do {
            let decodedMessage = try jsonDecoder.decode(BTMessage.self, from: messageData)
            print("Sender -- \(decodedMessage.sender) said: \(decodedMessage.message)")
            return decodedMessage;
        } catch {
            print("Error: \(error.localizedDescription)")
            return nil;
        }
        
    }
    
    public static func BTMessageEncoder(message: BTMessage) -> Data? {
                
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
