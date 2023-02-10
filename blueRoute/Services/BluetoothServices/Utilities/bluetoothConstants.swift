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
    static let blueRouteServiceID = CBUUID(string: "530F4EC6-8152-48F6-A604-8A884420776D")
    
    
    // Bluetooth services contain a number of characteristics, each representing a
    // specific functions of a service.
    
    // characteristic used to send message destined to the device advertising
    static let chatCharacteristicID = CBUUID(string: "1CB104B2-4804-47F8-AC96-80EEF0E2CECF")
    
    // characteristic used on first contact during discovery to exchange device name
    // and other devices nearby
    static let handshakeCharacteristicID = CBUUID(string: "A664834E-26DC-4FD9-A486-71CEF04B4569")
    
    // characteristic used to send message meant to be routed by advertising device
    static let routingCharacteristicID = CBUUID(string: "453FDFF2-EC7A-46CC-A300-617D5459E4F9")
    
    // characteristic used to send ping meant to check status of reachability
    static let pingCharacteristicID = CBUUID(string: "34D7134F-3EF9-4226-8CC5-05EEDD81FD11")
    
    static let qtyCharacteristics = 4;
    
    // The peripheral uses a local name to advertise with a custom name.
    // The local name contains the username provided by the user in adition to
    // a UUID used for persisting chats when the username changes,
    // the separator allows us to separate the current username from the
    // persistent UUID in the peripheral's local name
    static let NameIdentifierSeparator = "#?id?"
    
    // The amount of time in seconds after our last connection to a known device
    // before sending a ping
    static let LastConnectionInterval: Double = -180

}
