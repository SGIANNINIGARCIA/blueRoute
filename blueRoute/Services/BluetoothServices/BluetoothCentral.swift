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
    public var name:String = "unknown";
    
    // Delegate object handling shared resources and exposing the central manager to the UI
    weak var bluetoothController: BluetoothController!
    
    
    // The central manager scanning and connecting to peripherals
    private var central: CBCentralManager!
    
    // Temp list for peripherals discovered by the central
    var discoveredDevices = [CBPeripheral]()
    
    // Property to prevent stop scanning when
    // not all characteristics have been subscribed to
    var latestConnectedDevice: LatestDevice?
    
    var stopScanningSignal: Bool = false;
    
    
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
        central.scanForPeripherals(withServices: [BluetoothConstants.blueRouteServiceID],
                                          options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
        
    }

   fileprivate func stopScanning() {
       print("central has stopped scanning")
        central.stopScan()
       self.stopScanningSignal = false;
    }
    
    public func sendStopScanningSignal() {
        self.stopScanningSignal = true;
    }
    
    
    // Write to one of the peripheral Characteristics
    public func sendData(_ data: Data, peripheral: CBPeripheral, characteristic: CBUUID) {
        
        guard let characteristicToWrite = getCharacteristic(peripheral: peripheral, serviceId: BluetoothConstants.blueRouteServiceID, characteristicId: characteristic) else {
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
        //startScanning()
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
            
            // If we received the siganl to stop scanning, dont proceed with
            // connecting to this peripheral
            if(stopScanningSignal) {
                return;
            }
            
            // Save a reference to the peripheral before connecting
            self.discoveredDevices.append(peripheral)
            
            /**
             ** TESTING IF PERIPHERAL IDENTIFIER CHANGES
             **/
            print("1. central didDiscover peripheral with id: \(peripheral.identifier.uuidString)")
            
            // Start connection to the peripheral
            central.connect(peripheral, options: nil)
        }
    
    
    // Called when a peripheral has successfully connected to this device
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {

        // Configure a delegate for the peripheral
        peripheral.delegate = self
        
        /**
         ** TESTING IF PERIPHERAL IDENTIFIER CHANGES
         **/
        print("2. central didConnect peripheral with id: \(peripheral.identifier.uuidString)")
        
        // set this device as the latestConnectedDevice
        self.latestConnectedDevice = LatestDevice(id: peripheral.identifier)

        // Scan for the chat characteristic we'll use to communicate
        peripheral.discoverServices([BluetoothConstants.blueRouteServiceID])
    
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
        
        /**
         ** TESTING IF PERIPHERAL IDENTIFIER CHANGES
         **/
        print("3. central didDiscoverServices peripheral with id: \(peripheral.identifier.uuidString)")

        // It's possible there may be more than one service, so loop through each one to discover
        // the characteristic that we want
        peripheral.services?.forEach { service in
            peripheral.discoverCharacteristics([BluetoothConstants.chatCharacteristicID, BluetoothConstants.handshakeCharacteristicID, BluetoothConstants.routingCharacteristicID, BluetoothConstants.pingCharacteristicID], for: service)
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
        
        /**
         ** TESTING IF PERIPHERAL IDENTIFIER CHANGES
         **/
        print("4. central didDiscoverCharacteristicFor peripheral with id: \(peripheral.identifier.uuidString)")

        // Perform a loop in case we received more than one
        service.characteristics?.forEach { characteristic in
            guard characteristic.uuid == BluetoothConstants.chatCharacteristicID || characteristic.uuid == BluetoothConstants.handshakeCharacteristicID || characteristic.uuid == BluetoothConstants.routingCharacteristicID || characteristic.uuid == BluetoothConstants.pingCharacteristicID else { return }
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
         
         /**
          ** TESTING IF PERIPHERAL IDENTIFIER CHANGES
          **/
         print("central didUpdateNotificationStateFor peripheral with id: \(peripheral.identifier.uuidString)")

         // Ensure this characteristic is the one we configured
         guard characteristic.uuid == BluetoothConstants.chatCharacteristicID || characteristic.uuid == BluetoothConstants.handshakeCharacteristicID || characteristic.uuid == BluetoothConstants.routingCharacteristicID || characteristic.uuid == BluetoothConstants.pingCharacteristicID else { return }
         
         // if this peripheral is the last one our central connected to
         // append the current characteristic we subscribed to to the
         // subscribedCharacteristic array
         if(self.latestConnectedDevice?.id == peripheral.identifier) {
             self.latestConnectedDevice?.subscribedChars.append(characteristic.uuid)
         }
         
         // Check if it is successfully set as notifying
             if characteristic.isNotifying {
                 print("Characteristic notifications have begun.")
                 
                 // If we received the siganl to stop scanning and
                 // we finished subscribing to all it's characteristics
                 // then we can safely stop scanning
                 if(latestConnectedDevice?.subscribedChars.count == BluetoothConstants.qtyCharacteristics && self.stopScanningSignal) {
                     stopScanning()
                 }
                 
             } else {
                 print("Characteristic notifications have stopped. Disconnecting.")
                // CANCEL CONNECTION TO PERIPHERAL
                 // TO-DO
             }
     }
    
    // The peripheral has written value to one of the characteristics we are subscribed to
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        // Perform any error handling if one occurred
        if let error = error {
            print("Characteristic value update failed: \(error.localizedDescription)")
            return
        }
        
        /**
         ** TESTING IF PERIPHERAL IDENTIFIER CHANGES
         **/
        print("central  didUpdateValueFor peripheral with id: \(peripheral.identifier.uuidString)")
        
        // process data received depending on the characteristic
        switch(characteristic.uuid) {
            
            // PROCESS THE HANDSHAKE
        case BluetoothConstants.handshakeCharacteristicID :
            print("wrote to handshake")
            // Decode the data to pull the name and save to list of devices
            guard let data = characteristic.value else { return }
            bluetoothController.addDevice(data: data, peripheral: peripheral)
            
            // Send this central's information so the peripheral can write back
            // if it doesnt have a connection to our device's peripheral
            respondToHandshake(peripheral: peripheral)
            
        case BluetoothConstants.routingCharacteristicID:
            print("wrote to routing")
            //guard let data = characteristic.value else { return }
            bluetoothController.processIncomingRoutingMessage()
            // Update the last connection of the device
            bluetoothController.updateLastConnection(peripheral)
            
        case BluetoothConstants.chatCharacteristicID:
            print("wrote to chat")
            //process chat
            guard let data = characteristic.value else { return }
            bluetoothController.processIncomingChatMessage(data)
            // Update the last connection of the device
            bluetoothController.updateLastConnection(peripheral)
            
            
        case BluetoothConstants.pingCharacteristicID:
            print("ping received")
            //process ping
            bluetoothController.processReceivedPing()
           // guard let data = characteristic.value else { return }
            // send ping back?
           
            
        default:
            print("default")
            bluetoothController.updateLastConnection(peripheral)
            
            
        }
    }
    
    // a peripheral has changed the services it advertises
    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        print("peripheral \(peripheral.identifier) has changed it services ")
        // DO-SOMETHING?
    }
    
    // If we connect to a peripheral and finished the initial Handshake,
    // add the peripheral to the list

    
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
    
}

// Extension to process handshake
extension BluetoothCentralManager {
    func respondToHandshake(peripheral: CBPeripheral) {
        print("Central: sending handshake ")
        let data: Data =  Data(self.name.utf8)
        sendData(data, peripheral: peripheral, characteristic: BluetoothConstants.handshakeCharacteristicID)
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



// Controller + Bluetooth Central
extension BluetoothController {
    
    public func startDiscovery() {
        self.central?.startScanning()
    }
    
    public func stopDiscovery() {
        self.central?.sendStopScanningSignal()
    }
    
    public func addDevice(data: Data, peripheral: CBPeripheral) {
        
        let name = String(decoding: data, as: UTF8.self)
        let displayName = BluetoothController.retrieveUsername(name: name)
        let id = BluetoothController.retrieveID(name: name)
        
        // Loop trhough the array and check if it already has the device
        for (index, device) in devices.enumerated() {
            if(self.devices[index].id == id) {
                print("central: \(device.displayName)  already existed- updating reference to peripheral now")
                // if it does,  Add the new reference to the peripheral and exit
                self.devices[index].changePeripheralReference(peripheral)
                return;
            }
        }
        
        print("central: Adding new device with name: \(displayName) to the device array")
        // This is a new device, so we must add it to the list
        let newDevice = Device(name: name, peripheral: peripheral)
        self.devices.append(newDevice)
    }
}



/*
  To prevent the cental from stop scanning while we are still subscribing
  to a peripheral's characteristic
 */

struct LatestDevice {
    
    let id: UUID;
    var subscribedChars = [CBUUID]()
    
    init(id: UUID) {
        self.id = id;
    }
}
