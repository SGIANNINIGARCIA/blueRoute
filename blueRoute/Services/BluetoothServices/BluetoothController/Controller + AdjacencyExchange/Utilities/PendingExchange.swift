//
//  PendingExchange.swift
//  blueRoute
//
//  Created by Sandro Giannini on 3/11/23.
//

import Foundation

struct PendingExchange {
    var dataSegments: [Data];
    var segmentsProcessed: Int;
    var timeOfLastPackage: Date?
    
    init(dataSegments: [Data]) {
        self.dataSegments = dataSegments
        self.segmentsProcessed = 1;
        self.timeOfLastPackage = Date()
    }
    
    /// Updates the members when a new package has been received
    /// used when we are receiving an Adjacency List
    mutating func update(_ data: AdjacencyExchangePackage) {
        self.dataSegments.append(data.payload)
        self.segmentsProcessed += 1;
        self.timeOfLastPackage = Date();
    }
    
    /// Updates the members when a new package has been sent
    /// used when we are sending the AdjacencyList
    mutating func update() {
        self.segmentsProcessed += 1;
        self.timeOfLastPackage = Date();
    }
    
    /// Returns the next segment of data to send
    func retrieveNextSegment() -> Data? {
        
        if 0 > (segmentsProcessed - 1) {return nil}
        
        return self.dataSegments[segmentsProcessed - 1]
    }
    
    
}
