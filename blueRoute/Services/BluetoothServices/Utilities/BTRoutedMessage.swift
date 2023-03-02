//
//  BTRoutedMessage.swift
//  blueRoute
//
//  Created by Sandro Giannini on 3/1/23.
//

import Foundation

//
//  BTMessage.swift
//  blueRoute
//
//  Created by Sandro Giannini on 11/24/22.
//

import Foundation

struct BTRoutedMessage: Codable {
    
    var targetUser: String;
    var BTmessage: BTMessage;
    
    
    enum CodingKeys: String, CodingKey {
        case targetUser
        case BTmessage
    }
}

// Decode/Encode methods
extension BTRoutedMessage {
    
    public static func BTRoutedMessageDecoder(message: String) -> BTRoutedMessage? {
        
        //2 - Convert the string to data
        let messageData = Data(message.utf8)

        //3 - Create a JSONDecoder instance
        let jsonDecoder = JSONDecoder()
        
        //4 - set the keyDecodingStrategy to convertFromSnakeCase on the jsonDecoder instance
        jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
        
        //5 - Use the jsonDecoder instance to decode the json into a Person object
        do {
            let decodedMessage = try jsonDecoder.decode(BTRoutedMessage.self, from: messageData)
            print("target: -- \(decodedMessage.targetUser)")
            return decodedMessage;
        } catch {
            print("Error: \(error.localizedDescription)")
            return nil;
        }
        
    }
    
    public static func BTRoutedMessageEncoder(message: BTRoutedMessage) -> Data? {
                
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
