//
//  ExchangeVertex.swift
//  blueRoute
//
//  Created by Sandro Giannini on 2/28/23.
//

import Foundation

struct ExchangeVertex: Codable, Hashable {
    var name: String;
    var lastUpdated: Date;
    var edges: [String]
    
    enum CodingKeys: String, CodingKey {
        case name
        case lastUpdated
        case edges
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}
