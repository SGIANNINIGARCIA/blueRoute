//
//  AdjacencyPackageAcknowledgment.swift
//  blueRoute
//
//  Created by Sandro Giannini on 3/11/23.
//

import Foundation

/// Struct used to acknowledge the delivery of a AdjacencyExchangePackage
/// which prompts the receiver to send the next package, if any
///
/// - Members:
///    - receivedPackageNumber: The package number the being acknowledged
struct AdjacencyPackageAcknowledgement: Codable {
    
    ///  Member describes the quantity of packages we have received so far
    var receivedPackageNumber: Int;
    
    enum CodingKeys: String, CodingKey {
        case receivedPackageNumber
    }
    
    public static func decoder(message: String) -> AdjacencyPackageAcknowledgement? {
        
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
            print("\(String(describing: error)) error at AdjacencyPackageAcknowledgement decoder")
            return nil;
        }
        
    }
    
    public static func encoder(message: AdjacencyPackageAcknowledgement) -> Data? {
                
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = .prettyPrinted
        
        do {
            let encodeMessage = try jsonEncoder.encode(message)
            return encodeMessage;
        } catch {
            print("\(String(describing: error)) error at AdjacencyPackageAcknowledgement encoder")
            return nil;
        }
    }
}
