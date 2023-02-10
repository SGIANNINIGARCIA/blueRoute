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
struct Device: Identifiable, Equatable {
    
    
    
    // The peripheral object associated with the device
    var peripheral: CBPeripheral?
    
    // The peripheral object associated with the device
    var central: CBCentral?
    
    // The username provided by the device
    let displayName: String;
    
    // The ID to conform to identifiable
    let id: UUID;
    
    // The most recent bluetooth reference
    var sendTo: MostRecentRef?
    
    // Last connection to keep track of reachability
    var lastConnection: Date?
    
    init(name: String = "Unknown", central: CBCentral? = nil, peripheral: CBPeripheral? = nil) {
        self.displayName = BluetoothController.retrieveUsername(name: name)
        self.id = BluetoothController.retrieveID(name: name)
        self.lastConnection = Date();
        
        if let central = central {
            self.central = central
            self.sendTo = .central
            
        }
        
        if let peripheral = peripheral {
            self.peripheral = peripheral
            self.sendTo = .peripheral
        }
    }
    
    static func ==(lhs: Device, rhs: Device) -> Bool {
        return lhs.id == rhs.id;
    }
    
    static func ==(lhs: CBPeripheral, rhs: Device) -> Bool {
        return lhs.identifier == rhs.peripheral?.identifier;
    }
    
    static func ==(lhs: CBCentral, rhs: Device) -> Bool {
        return lhs.identifier == rhs.central?.identifier;
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
        self.lastConnection = Date()
    }
}

