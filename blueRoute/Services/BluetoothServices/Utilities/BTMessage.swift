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
