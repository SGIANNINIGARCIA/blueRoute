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
    
    enum CodingKeys: String, CodingKey {
        case pingType
        case pingSender
        case pingReceiver
    }
    
    
}
