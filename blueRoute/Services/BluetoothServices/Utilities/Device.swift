//
//  Device.swift
//  blueRoute
//
//  Created by Sandro Giannini on 11/10/22.
//

import Foundation
import CoreBluetooth

enum MostRecentRef {
    case peripheral
    case central
}


// Devices available through bluetooth
struct Vertex: Identifiable, Equatable, Hashable {
    
    // The peripheral object associated with the device
    var peripheral: CBPeripheral?
    
    // The peripheral object associated with the device
    var central: CBCentral?
    
    // The username provided by the device
    let displayName: String;
    
    // The ID to conform to identifiable
    let id: UUID;
    
    // The name containing displayName and id
    let fullName: String;
    
    // The most recent bluetooth reference
    var sendTo: MostRecentRef?
    
    // Last connection to keep track of reachability
    var lastKnownPing: Date?
    
    var pingTimeOutTimer: Timer?
    
    init(name: String = "Unknown", peripheral: CBPeripheral) {
        self.displayName = BluetoothController.retrieveUsername(name: name)
        self.id = BluetoothController.retrieveID(name: name)
        self.fullName = name;
        self.lastKnownPing = Date();
        
       
            self.peripheral = peripheral
            self.sendTo = .peripheral
        
    }
    
    init(name: String = "Unknown", central: CBCentral) {
        self.displayName = BluetoothController.retrieveUsername(name: name)
        self.id = BluetoothController.retrieveID(name: name)
        self.fullName = name;
        self.lastKnownPing = Date();
        
        
       
            self.central = central
            self.sendTo = .central
            
    }
    
    init(name: String = "Unknown") {
        self.displayName = BluetoothController.retrieveUsername(name: name)
        self.id = BluetoothController.retrieveID(name: name)
        self.fullName = name;            
    }
    
    static func ==(lhs: Vertex, rhs: Vertex) -> Bool {
        return lhs.id == rhs.id;
    }
    
    static func ==(lhs: CBPeripheral, rhs: Vertex) -> Bool {
        return lhs.identifier == rhs.peripheral?.identifier;
    }
    
    static func ==(lhs: CBCentral, rhs: Vertex) -> Bool {
        return lhs.identifier == rhs.central?.identifier;
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    mutating func changePeripheralReference(_ newPeripheral: CBPeripheral) {
        
        self.peripheral = newPeripheral;
        self.sendTo = .peripheral;
        
    }
    
    mutating func changeCentralReference(_ newCentral: CBCentral) {
        
        self.central = newCentral;
        self.sendTo = .central;
        
    }
    
    mutating func updateLastConnection() {
        self.lastKnownPing = Date()
        self.pingTimeOutTimer?.invalidate()
    }
    
    mutating func setPingTimer(_ timer: Timer) {
        self.pingTimeOutTimer = timer;
        self.lastKnownPing = Date()
    }

}
