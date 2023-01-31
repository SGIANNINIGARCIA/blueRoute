//
//  bluetoothConstants.swift
//  blueRoute
//
//  Created by Sandro Giannini on 11/19/22.
//

import Foundation
import CoreBluetooth

struct BluetoothConstants {

    // Bluetooth peripherals advertise their supported capabilities as uniquely identified services
    // This service is used when a device is advertising itself to be available to other devices
    static let chatDiscoveryServiceID = CBUUID(string: "530F4EC6-8152-48F6-A604-8A884420776D")
    
    
    // Bluetooth services contain a number of characteristics, each representing a
    // specific functions of a service.
    static let chatCharacteristicID = CBUUID(string: "f0ab5a15-b003-4653-a248-73fd504c1281")
    
    // Bluetooth services contain a number of characteristics, each representing a
    // specific functions of a service.
    static let nameCharacteristicID = CBUUID(string: "A664834E-26DC-4FD9-A486-71CEF04B4569")
    
    // The peripheral uses a local name to advertise with a custom name.
    // The local name contains the username provided by the user in adition to
    // a UUID used for persisting chats when the username changes,
    // the separator allows us to separate the current username from the
    // persistent UUID in the peripheral's local name
    static let NameIdentifierSeparator = "#?id?"

}
