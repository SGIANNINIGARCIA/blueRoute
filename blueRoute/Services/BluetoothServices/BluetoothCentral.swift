//
//  BluetoothCentral.swift
//  blueRoute
//
//  Created by Sandro Giannini on 11/19/22.
//

import Foundation
import CoreBluetooth


// The BluetoothCentralManager scans for peripherals advertising the blueRoute service.
//
// On discovery, it saves a strong reference to the peripheral in an array and begins
// the connection. It then receives the displayName & UUID id of the peripheral and
// saves this information as a Device in the array provided by the BluetoothController
//
// It is also responsible for removing devices once they disconnect and sending messages to
// the peripheral associated with the DisplayName the user wants to message


class BluetoothCentralManager: NSObject {
    
    // Full Name containing the displayName provided by user during onboarding + unique ID
    public var name:String = "unknown" {
        didSet { startScanning() }
    }
    
    // Delegate object handling shared resources and exposing the central manager to the UI
    weak var bluetoothController: BluetoothController!
    
    
    // The central manager scanning and connecting to peripherals
    private var central: CBCentralManager!
    
    // Temp list for peripherals discovered by the central
    var discoveredDevices = [CBPeripheral]()
    
    
    // Make a queue we can run all of the events off
    private let queue = DispatchQueue(label: "blueRoute-central.bluetooth-discovery",
                                      qos: .background, attributes: .concurrent,
                                      autoreleaseFrequency: .workItem, target: nil)
    
    
    
    // Initializer
    init(name: String? = nil, bluetoothController: BluetoothController? = nil) {
        super.init()
        
        // Create the Bluetooth central
        self.central = CBCentralManager(delegate: self, queue: queue)
        
        
        if let bluetoothController = bluetoothController { self.bluetoothController = bluetoothController}
        
        // If a device name is provided, assign it to class property
        if let name = name { self.name = name }
    
    }
    
    
    // Scans for all peripherals advertising our service
    fileprivate func startScanning() {
        
        // return if we are not ready to start scanning
        guard central.state == .poweredOn else { return }
        
        
        print("central: i am scanning for peripherals")
        
        // Call the centralManager to start scanning
        central.scanForPeripherals(withServices: [BluetoothConstants.chatDiscoveryServiceID],
                                          options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
        
    }

   fileprivate func stopScanning() {
        central.stopScan()
    }
    
    // If we connect to a peripheral and finished the initial Handshake,
    // add the peripheral to the list
    fileprivate func addToDeviceList(with device: Device) {
        
        print("\(name) found \(device.displayName)")
        // If a device already exists in the list, replace it with this new device
        if let index = bluetoothController.devices.firstIndex(where: { $0.id == device.id }) {
          //  guard bluetoothController.devices[index].id != device.id else { return }
            print("\(device.displayName)  already existed- updating now")
            bluetoothController.devices.remove(at: index)
            bluetoothController.devices.insert(device, at: index)
            return
        }
    
        // If this item didn't exist in the list, append it to the end
        bluetoothController.devices.append(device)
       
    }
    
    fileprivate func removeDeviceFromList(with device: CBPeripheral) {
        
        print("removing \(device.identifier)")
        // If a device already exists in the list, replace it with this new device
        if let index = bluetoothController.devices.firstIndex(where: { $0.peripheral?.identifier == device.identifier }) {
          //  guard bluetoothController.devices[index].id != device.id else { return }
            print("\(bluetoothController.devices[index].displayName)  found- removing now")
            bluetoothController.devices.remove(at: index)
            return
        }
    }
    
    // Send a message to our connected peripheral once a connection have been stablished
    public func sendData(_ data: Data, peripheral: CBPeripheral) {
        
        guard let characteristicToWrite = getCharacteristic(peripheral: peripheral, serviceId: BluetoothConstants.chatDiscoveryServiceID, characteristicId: BluetoothConstants.chatCharacteristicID) else {
            // Could not find characteristic
            print("could not find a characteristic to write to")
            return;
        }
        
        peripheral.writeValue(data, for: characteristicToWrite, type: .withResponse)
        
        print("central: message sent to peripheral")
    }
}

extension BluetoothCentralManager: CBCentralManagerDelegate {
    
    // Delegate function called when the Bluetooth central state changes
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
        // return if we are not ready to start scanning
        guard central.state == .poweredOn else { return }
        
        // Don't continue if we're already scanning
        guard central.isScanning == false else { return }

        // Call function that triggers central to start scanning
        startScanning()
    }
    
    // Called when a peripheral is detected
        func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                            advertisementData: [String: Any], rssi RSSI: NSNumber) {
            
            // Get the string value of the UUID of this device as the default value
            var name = peripheral.identifier.description
            
            // Attempt to get the user-set device name of this peripheral
           if let deviceName = advertisementData[CBAdvertisementDataLocalNameKey] as? String {
              // print("i was able to find a name \(deviceName)")
               name = deviceName
            }
            
            print("central: found a peripheral with name = \(name) \ncentral: Attempting connection to peripheral with name = \(name)")
            
            // Save a reference to the peripheral before connecting
            self.discoveredDevices.append(peripheral)
            
            // Start connection to the peripheral
            central.connect(peripheral, options: nil)
        }
    
    
    // Called when a peripheral has successfully connected to this device
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {

        // Configure a delegate for the peripheral
        peripheral.delegate = self

        // Scan for the chat characteristic we'll use to communicate
        peripheral.discoverServices([BluetoothConstants.chatDiscoveryServiceID])
    }
    
    // Called when a peripheral has diconnected from this device (acting as a central)
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        
        print("peripheral has disconnected")
        
    }
    
    
}


// This extension handles the delegate functions of the peripheral we connected to
extension BluetoothCentralManager: CBPeripheralDelegate {
    
    // Called when the peripheral has discovered all of the services we requested,
    // so we can then check those services for the characteristics we need
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        // If an error occurred, print it, and then reset all of the state
        if let error = error {
            print("Unable to discover service: \(error.localizedDescription)")
            return
        }

        // It's possible there may be more than one service, so loop through each one to discover
        // the characteristic that we want
        peripheral.services?.forEach { service in
            peripheral.discoverCharacteristics([BluetoothConstants.chatCharacteristicID], for: service)
        }
        
        peripheral.services?.forEach { service in
            peripheral.discoverCharacteristics([BluetoothConstants.nameCharacteristicID], for: service)
        }
    }
    
    // A characteristic matching the ID that we specifed was discovered in one of the services of the peripheral
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        // Handle if any errors occurred
        if let error = error {
            print("Unable to discover characteristics: \(error.localizedDescription)")
           // do a cleanup
           // TO DO
            return
        }

        // Perform a loop in case we received more than one
        service.characteristics?.forEach { characteristic in
            guard characteristic.uuid == BluetoothConstants.chatCharacteristicID || characteristic.uuid == BluetoothConstants.nameCharacteristicID else { return }

            // Subscribe to this characteristic, so we can be notified when data comes from it
            peripheral.setNotifyValue(true, for: characteristic)

        }
    }
    
    // The peripheral returned back whether our subscription to the characteristic was successful or not
     func peripheral(_ peripheral: CBPeripheral,
                     didUpdateNotificationStateFor characteristic: CBCharacteristic,
                     error: Error?) {
         
         
         // Perform any error handling if one occurred
         if let error = error {
             print("Characteristic update notification failed: \(error.localizedDescription)")
             return
         }

         // Ensure this characteristic is the one we configured
         guard characteristic.uuid == BluetoothConstants.chatCharacteristicID || characteristic.uuid == BluetoothConstants.nameCharacteristicID else { return }
         
         // Check if it is successfully set as notifying
             if characteristic.isNotifying {
                 print("Characteristic notifications have begun.")
             } else {
                 print("Characteristic notifications have stopped. Disconnecting.")
                // CANCEL CONNECTION TO PERIPHERAL
                 // TO-DO
             }
     }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        // Perform any error handling if one occurred
        if let error = error {
            print("Characteristic value update failed: \(error.localizedDescription)")
            return
        }

        // Decode the message string and trigger the callback
        guard let data = characteristic.value else { return }
        let name = String(decoding: data, as: UTF8.self)
        
        let device = Device(name: name, peripheral: peripheral)
        
        DispatchQueue.main.async { [weak self] in
            self?.addToDeviceList(with: device)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        
        print("peripheral \(peripheral.identifier) disconnected ")
        
        
        removeDeviceFromList(with: peripheral)
      //  startScanning()
            
            
        
    }
}


// Extension to hold helper functions
extension BluetoothCentralManager {
    
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
