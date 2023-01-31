//
//  BTMessage.swift
//  blueRoute
//
//  Created by Sandro Giannini on 11/24/22.
//

import Foundation

struct BTMessage: Codable {
    
    var sender: String;
    var message: String;
    var receiver: String;
    
    enum CodingKeys: String, CodingKey {
        case sender
        case message
        case receiver
    }
}
