//
//  BluetoothPeripheral.swift
//  blueRoute
//
//  Created by Sandro Giannini on 11/20/22.
//

import Foundation
import CoreBluetooth

class BluetoothPeripheralManager: NSObject {
    
    // Full name containing displayName + uniqueID
    public var name: String = "nonameyet" {
        didSet {
            startAdvertising()
        }
    }
    
    // The peripherl advertising our services and characteristics
    private var peripheral: CBPeripheralManager!
    
    // Delegate object handling shared resources and exposing the central manager to the UI
    weak var bluetoothController: BluetoothController!
    
    // The characteristic used for our chat sessions
    private var peripheralChatCharacteristic: CBMutableCharacteristic!
    
    // The characteristic used for our chat sessions
    private var peripheralHandshakeCharacteristic: CBMutableCharacteristic!
    
    // The characteristic used for our chat sessions
    private var peripheralRoutingCharacteristic: CBMutableCharacteristic!
    
    // The characteristic used for pinging devices
    private var peripheralPingCharacteristic: CBMutableCharacteristic!
    
    // The characteristic used for exchanging Adjacency matrix
    private var peripheralAdjExchangeCharacteristic: CBMutableCharacteristic!
    
    // Make a queue we can run all of the events off
    /*private let queue = DispatchQueue(label: "bluetooth-peripheral.bluetooth-discovery",
                                      qos: .background, attributes: .concurrent,
                                      autoreleaseFrequency: .workItem, target: nil)
     */
    
    init(name: String? = nil, bluetoothController: BluetoothController? = nil) {
        super.init()
        
        self.peripheral = CBPeripheralManager(delegate: self, queue: nil)
        
        if let bluetoothController = bluetoothController { self.bluetoothController = bluetoothController}
        
        // If the displayName has been set, save it
        if let name = name {
            self.name = name;
            startAdvertising()
        }
        
    }
    
    // Start advertising (Or re-advertise) this device as a peipheral
    fileprivate func startAdvertising() {
                
        print("advertising as \(name)")
        
        // Don't start until we've finished warming up
        guard peripheral.state == .poweredOn else { return }

        // Stop advertising if we're already in progress
        if peripheral.isAdvertising { peripheral.stopAdvertising() }

        // Start advertising with this device's name
        
        peripheral.startAdvertising(
            [CBAdvertisementDataServiceUUIDsKey: [BluetoothConstants.blueRouteServiceID],
                CBAdvertisementDataLocalNameKey: self.name])
    }
    
    func sendData(_ data: Data, central: CBCentral, characteristic: CBUUID) {
        switch (characteristic) {
        case BluetoothConstants.chatCharacteristicID:
            peripheral.updateValue(data, for: self.peripheralChatCharacteristic,
                                    onSubscribedCentrals: [central])
        case BluetoothConstants.pingCharacteristicID:
            peripheral.updateValue(data, for: self.peripheralPingCharacteristic,
                                    onSubscribedCentrals: [central])
        case BluetoothConstants.routingCharacteristicID:
            peripheral.updateValue(data, for: self.peripheralRoutingCharacteristic,
                                    onSubscribedCentrals: [central])
        case BluetoothConstants.handshakeCharacteristicID:
            peripheral.updateValue(data, for: self.peripheralHandshakeCharacteristic,
                                    onSubscribedCentrals: [central])
        case BluetoothConstants.adjExchangeCharacteristicID:
            peripheral.updateValue(data, for: self.peripheralAdjExchangeCharacteristic,
                                    onSubscribedCentrals: [central])
        default:
            print("peripheral: no matching characteristic")
       
        }
    }
    
    private func sendInitialHandshake(central: CBCentral, characteristic: CBCharacteristic) {
        let data: Data =  Data(self.name.utf8)
        self.peripheral?.updateValue(data, for: characteristic as! CBMutableCharacteristic,
                                       onSubscribedCentrals: [central])
    }
    
}

extension BluetoothPeripheralManager: CBPeripheralManagerDelegate {
    // Called when the Bluetooth peripheral state changes
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        
        // Once we're powered on, configure the peripheral with the services
        // and characteristics we intend to support
        guard peripheral.state == .poweredOn else { return }
        
        // The characteristic which will be the conduit for our chat data.
        // to the central, and notifiable, so we'll receive callbacks when data comes downstream
        peripheralChatCharacteristic = CBMutableCharacteristic(type: BluetoothConstants.chatCharacteristicID,
                                                 properties: [.write, .notify],
                                                 value: nil,
                                                 permissions: .writeable)
        
        // The characteristic which will be the responsible for initial handshake.
        peripheralHandshakeCharacteristic = CBMutableCharacteristic(type: BluetoothConstants.handshakeCharacteristicID,
                                                 properties: [.write, .notify],
                                                 value: nil,
                                                 permissions: .writeable)
        
        // The characteristic which will be the responsible for receiving data to be routed
        peripheralRoutingCharacteristic = CBMutableCharacteristic(type: BluetoothConstants.routingCharacteristicID,
                                                 properties: [.write, .notify],
                                                 value: nil,
                                                 permissions: .writeable)
        
        //BluetoothConstants.pingCharacteristicID
        peripheralPingCharacteristic = CBMutableCharacteristic(type: BluetoothConstants.pingCharacteristicID,
                                                 properties: [.write, .notify],
                                                 value: nil,
                                                 permissions: .writeable)
        
        //BluetoothConstants.adjExchangeCharacteristicID
        peripheralAdjExchangeCharacteristic = CBMutableCharacteristic(type: BluetoothConstants.adjExchangeCharacteristicID,
                                                 properties: [.write, .notify],
                                                 value: nil,
                                                 permissions: .writeable)
        
        
        // Create the service that will represent this characteristic
        let service = CBMutableService(type: BluetoothConstants.blueRouteServiceID, primary: true)
        service.characteristics = [self.peripheralChatCharacteristic!, self.peripheralHandshakeCharacteristic, self.peripheralRoutingCharacteristic, self.peripheralPingCharacteristic, self.peripheralAdjExchangeCharacteristic]
        
        // Register this service to the peripheral so it can now be advertised
        self.peripheral?.add(service)

        // Start advertising as a peripheral
        let advertisementData: [String: Any] = [CBAdvertisementDataServiceUUIDsKey: [BluetoothConstants.blueRouteServiceID]]
        self.peripheral?.startAdvertising(advertisementData)
    }
    
    // Called when someone has subscribed to our characteristic, allowing us to send them data
    func peripheralManager(_ peripheral: CBPeripheralManager,
                           central: CBCentral,
                           didSubscribeTo characteristic: CBCharacteristic) {
        
        // Handshake which sends the central our fullname and our Adjcency List
        if(characteristic.uuid == BluetoothConstants.handshakeCharacteristicID) {
            print("A central has subscribed to the peripheral, initiating handshake")
            self.bluetoothController.sendHandshake(central)
        }
    }
    
    // Called when the central has sent a message to this peripheral
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        guard let request = requests.first, let data = request.value else { return }
        
        switch (requests.first?.characteristic.uuid) {

        case BluetoothConstants.handshakeCharacteristicID:
            print("peripheral: central sent handshake data")
            
            // now we pass the handshake processing  to the controller
            DispatchQueue.main.async { [weak self] in
                self?.bluetoothController.processHandshake(data, from: request.central)
                    }
            
        case BluetoothConstants.chatCharacteristicID:
            print("peripheral: central sent message for cha")
            bluetoothController.processIncomingChatMessage(data, from: request.central)
            
        case BluetoothConstants.routingCharacteristicID:
            print("peripheral: central sent message for routing")
            bluetoothController.processIncomingRoutingMessage(data, from: request.central)
            
        case BluetoothConstants.pingCharacteristicID:
            print("peripheral: central sent ping")
            bluetoothController.processReceivedPing(data)
            
        case BluetoothConstants.adjExchangeCharacteristicID:
            bluetoothController.processAdjacencyExchangeMessage(data)
            
        default:
            print("peripheral: central send message: did not match a characteristic?")
        }
    }
}


// Extension to hold helper functions
extension BluetoothPeripheralManager {
    
    private func getCharacteristic(peripheral: CBPeripheral, serviceId: CBUUID, characteristicId: CBUUID) -> CBCharacteristic? {
           guard peripheral.state == .connected, let services = peripheral.services else { return nil }
           for service in services {
               guard service.uuid == serviceId, let characteristics = service.characteristics else { return nil }
               for characteristic in characteristics {
                   if characteristic.uuid == characteristicId {
                       return characteristic
                   }
               }
           }
           return nil
       }
}
