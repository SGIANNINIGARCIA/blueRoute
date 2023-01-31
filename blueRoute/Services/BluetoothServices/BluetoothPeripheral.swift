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
    private var peripheralCharacteristic: CBMutableCharacteristic!
    
    // Make a queue we can run all of the events off
    private let queue = DispatchQueue(label: "bluetooth-peripheral.bluetooth-discovery",
                                      qos: .background, attributes: .concurrent,
                                      autoreleaseFrequency: .workItem, target: nil)
    
    init(name: String? = nil, bluetoothController: BluetoothController? = nil) {
        super.init()
        
        self.peripheral = CBPeripheralManager(delegate: self, queue: queue)
        
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
            [CBAdvertisementDataServiceUUIDsKey: [BluetoothConstants.chatDiscoveryServiceID],
             CBAdvertisementDataLocalNameKey: name])
    }
    
    private func sendData(_ data: Data, central: CBCentral) {
        guard let characteristic = self.peripheralCharacteristic else { return }
        peripheral.updateValue(data, for: characteristic,
                                onSubscribedCentrals: [central])
    }
    
}

extension BluetoothPeripheralManager: CBPeripheralManagerDelegate {
    // Called when the Bluetooth peripheral state changes
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        
        // Once we're powered on, configure the peripheral with the services
        // and characteristics we intend to support
        guard peripheral.state == .poweredOn else { return }
        
        // Create the characteristic which will be the conduit for our chat data.
        // Make sure the properties are set to writeable so we can send data upstream
        // to the central, and notifiable, so we'll receive callbacks when data comes downstream
        peripheralCharacteristic = CBMutableCharacteristic(type: BluetoothConstants.chatCharacteristicID,
                                                 properties: [.write, .notify],
                                                 value: nil,
                                                 permissions: .writeable)
        
        // Create the service that will represent this characteristic
        let service = CBMutableService(type: BluetoothConstants.chatDiscoveryServiceID, primary: true)
        service.characteristics = [self.peripheralCharacteristic!]
        
        // Register this service to the peripheral so it can now be advertised
        self.peripheral?.add(service)

        // Start advertising as a peripheral
        let advertisementData: [String: Any] = [CBAdvertisementDataServiceUUIDsKey: [BluetoothConstants.chatDiscoveryServiceID]]
        self.peripheral?.startAdvertising(advertisementData)
    }
    
    // Called when someone has subscribed to our characteristic, allowing us to send them data
    func peripheralManager(_ peripheral: CBPeripheralManager,
                           central: CBCentral,
                           didSubscribeTo characteristic: CBCharacteristic) {
        
        print("A central has subscribed to the peripheral, initiating handshake")
        
        // Handshake which sends the central the fullname of the user
        initialHandshake(central: central, characteristic: characteristic)
        
     
    }
    
    func initialHandshake(central: CBCentral, characteristic: CBCharacteristic) {
               
        let data: Data =  Data(self.name.utf8)
        self.peripheral?.updateValue(data, for: characteristic as! CBMutableCharacteristic,
                                       onSubscribedCentrals: [central])
    }
    
    // Called when the central has sent a message to this peripheral
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        guard let request = requests.first, let data = request.value else { return }

        // pass received data to the controller for processing
        bluetoothController.processReceivedData(data: data)
    }
}
