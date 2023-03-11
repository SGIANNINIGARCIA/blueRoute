//
//  AdjacencyExchangeSegment.swift
//  blueRoute
//
//  Created by Sandro Giannini on 3/11/23.
//

import Foundation



/// Struct used to send a segment of AdjacencyList being shared
///
/// AdjacencyLists need to be broken down since their size is bigger than the MTU
///
/// - Members:
///     - packageTotalCount: Total number of packages being exchange in order to share the AdjacencyList
///     - currentPackageNumber: Number of this current package in reference to total count
///     - payload: A segment of BTAdjacencyList
///
struct AdjacencyExchangePackage: Codable {
    var packageTotalCount: Int;
    var currentPackageNumber: Int;
    var payload: Data;
    
    enum CodingKeys: String, CodingKey {
        case packageTotalCount
        case currentPackageNumber
        case payload
    }
    
    public static func decoder(message: String) -> AdjacencyExchangePackage? {
        
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
    
    public static func encoder(message: AdjacencyExchangePackage) -> Data? {
                
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
