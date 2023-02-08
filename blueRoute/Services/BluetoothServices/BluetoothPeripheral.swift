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
    
     func sendChatMessage(_ data: Data, central: CBCentral) {
        guard let characteristic = self.peripheralChatCharacteristic else { return }
        peripheral.updateValue(data, for: characteristic,
                                onSubscribedCentrals: [central])
    }
    
     func sendRoutingData(_ data: Data, central: CBCentral) {
        guard let characteristic = self.peripheralChatCharacteristic else { return }
        peripheral.updateValue(data, for: characteristic,
                                onSubscribedCentrals: [central])
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
        
        // Create the service that will represent this characteristic
        let service = CBMutableService(type: BluetoothConstants.blueRouteServiceID, primary: true)
        service.characteristics = [self.peripheralChatCharacteristic!, self.peripheralHandshakeCharacteristic, self.peripheralRoutingCharacteristic]
        
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
        
        // Handshake which sends the central the fullname of the user
        if(characteristic.uuid == BluetoothConstants.handshakeCharacteristicID) {
            print("A central has subscribed to the peripheral, initiating handshake")
            initialHandshake(central: central, characteristic: characteristic)
        }
    }
    
    func initialHandshake(central: CBCentral, characteristic: CBCharacteristic) {
               
        let data: Data =  Data(self.name.utf8)
        self.peripheral?.updateValue(data, for: characteristic as! CBMutableCharacteristic,
                                       onSubscribedCentrals: [central])
    }
    
    // Called when the central has sent a message to this peripheral
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        guard let request = requests.first, let data = request.value else { return }
        
        switch (requests.first?.characteristic.uuid) {
            
        case BluetoothConstants.handshakeCharacteristicID:
            print("peripheral: central sent handshake data, proccessing now")
           
            // PROCCESS CENTRAL HANDSHAKE
            let name = String(decoding: data, as: UTF8.self)
            let device = Device(name: name, central: request.central)
            addToDeviceList(with: device)
            
        case BluetoothConstants.chatCharacteristicID:
            print("peripheral: central sent message for chat, proccess now")
            bluetoothController.processReceivedData(data: data)
            
        case BluetoothConstants.routingCharacteristicID:
            print("central sent message for routing, proccess now")
            
        default:
            print("peripheral: central send message: did not match a characteristic?")
            bluetoothController.processReceivedData(data: data)
        }
        
        //bluetoothController.processReceivedData(data: data)
    }
    
    func addToDeviceList(with device: Device) {
        
       // var newDevice = device;
        print("peripheral: Adding central reference to devices array")
        
        //print("\(name) found \(device.displayName)")
        
        for (index, device) in bluetoothController.devices.enumerated() {
            
            if(bluetoothController.devices[index].id == device.id) {
                
                print("peripheral: \(device.displayName)  already existed- updating now")
                
                // if it does,  Add the new reference to the central and exit
                bluetoothController.devices[index].central = device.central
                bluetoothController.devices[index].sendTo = .central
                
                return;
            }
        }
    
        print("peripheral: device did not exist, adding new device with reference to central")
        
        // If this item didn't exist in the list, append it to the end
        bluetoothController.devices.append(device)
       
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

