//
//  Device.swift
//  blueRoute
//
//  Created by Sandro Giannini on 11/10/22.
//

import Foundation
import CoreBluetooth


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
    
    init(name: String = "Unknown", central: CBCentral? = nil, peripheral: CBPeripheral? = nil) {
        self.displayName = BluetoothController.retrieveUsername(name: name)
        self.id = BluetoothController.retrieveID(name: name)
        
        if let central = central { self.central = central}
        if let peripheral = peripheral { self.peripheral = peripheral}
        
        
        }
    
    static func ==(lhs: Device, rhs: Device) -> Bool {
        return lhs.id == rhs.id;
    }
}
