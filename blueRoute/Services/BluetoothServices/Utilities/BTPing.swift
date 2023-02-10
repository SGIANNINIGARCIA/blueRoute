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
    var sender: String;
    var receiver: String;
    
    enum CodingKeys: String, CodingKey {
        case pingType
        case sender
        case receiver
    }
    
    
}
