//
//  BTHandshake.swift
//  blueRoute
//
//  Created by Sandro Giannini on 2/25/23.
//

import Foundation

struct BTHandshake: Codable {
    
    var name: String;
    
    enum CodingKeys: String, CodingKey {
        case name
    }
}


// Encode/Decode methods
extension BTHandshake {
    
    public static func BTHandshakeDecoder(message: String) -> BTHandshake? {
        
        //2 - Convert the string to data
        let messageData = Data(message.utf8)

        //3 - Create a JSONDecoder instance
        let jsonDecoder = JSONDecoder()
        
        //4 - set the keyDecodingStrategy to convertFromSnakeCase on the jsonDecoder instance
        jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
        
        //5 - Use the jsonDecoder instance to decode the json into a Person object
        do {
            let decodedMessage = try jsonDecoder.decode(BTHandshake.self, from: messageData)
            print("Handshake sent by -- \(decodedMessage.name) sent ping")
            return decodedMessage;
        } catch {
            print("Error: \(error.localizedDescription)")
            return nil;
        }
        
    }
    
    public static func BTHandshakeEncoder(message: BTHandshake) -> Data? {
                
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

