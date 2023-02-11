//
//  BluetoothController.swift
//  blueRoute
//
//  Created by Sandro Giannini on 11/22/22.
//

import Foundation
import CoreBluetooth
import CoreData

class BluetoothController: ObservableObject {
    
    // Variables holding our bluetooth managers
    @Published var peripheral: BluetoothPeripheralManager?
    @Published var central: BluetoothCentralManager?
    @Published var devices = [Device]();
    var managedObjContext: NSManagedObjectContext?;
    weak var dataController: DataController?;
    
    // Full name (displayName + unique ID)
    var name: String?
    
    private var pingDevicesTimer: Timer?
    private var pingedDevices = [Device]();
    
    
    init(dataController: DataController, context: NSManagedObjectContext) {
        self.dataController = dataController;
        self.managedObjContext = context;
    }
    
    public func setUp(name: String) -> Void {
        self.name = name;
        // instantiating the peripheral manager which wont start broadcasting immediately
        // but will wait until we provide an username
        self.peripheral = BluetoothPeripheralManager(name: name, bluetoothController: self )
        // instantiating the central manager which wont start discovering immediately
        // but will wait until we provide an username
        self.central = BluetoothCentralManager(name: name, bluetoothController: self)
        
        self.pingDevicesTimer = Timer.scheduledTimer(timeInterval: 120,
                                         target: self,
                                         selector: #selector(checkDevicesLastConnection),
                                         userInfo: nil,
                                         repeats: true)
    }
    
    // send data to a characteristic and returns true if it succeded
    public func sendData(send data: Data, to name: String, characteristic: CBUUID) -> Bool {
                
        guard let device = findDevice(name: name) else {
            print("could not find \(name)")
            return false;
        }
        
        // send the message using the newest reference we saved for the device
        switch device.sendTo {
        case .peripheral:
           if let peripheral = device.peripheral {
               central!.sendData(data, peripheral: peripheral, characteristic: characteristic)
               return true;
           } else {
               fallthrough
           }
        case .central:
            if let central = device.central {
                peripheral!.sendData(data, central: central, characteristic: characteristic)
                return true;
            } else {
                fallthrough
            }
        default:
            print("unable to send message - could not find a reference to the device")
            return false;
        }
    }
    
    
    private func saveMessage(message: BTMessage, isSelf: Bool, sendStatus: Bool) {
        dataController?.saveMessage(message: message, context: managedObjContext!, isSelf: isSelf, sendStatus: sendStatus)
    }
}

/*
 *  Methods to handle sending/receiving chat messages
 */

extension BluetoothController {
    
    public func sendChatMessage(send message: String, to name: String) {
        
        let codedMessage = BTMessage(sender: self.name!, message: message, receiver: name, type: .chat)
        
        guard let messageData = BTMessageEncoder(message: codedMessage) else {
            print("could not enconde message")
            return;
        }
        
       var successful = sendData(send: messageData, to: name, characteristic: BluetoothConstants.chatCharacteristicID)
        saveMessage(message: codedMessage, isSelf: true, sendStatus: successful)
    }
    
    // Decodes chat message sent to this devices through the chat characteristic
    public func processIncomingChatMessage(_ data: Data){
        
        let receivedData = String(decoding: data, as: UTF8.self)
        
        guard let decodedMessage: BTMessage = BTMessageDecoder(message: receivedData) else {
            print("unable to decode message")
            return;
        }
        
        saveMessage(message: decodedMessage, isSelf: false, sendStatus: true)
    
    }
    
    // TO-DO
    // Decodes routing message sent to this devices through the routing characteristic
    // Searches for next node and sends it
    public func processIncomingRoutingMessage(){}
    
}

// Methods to handle Pinging
extension BluetoothController {
    
    @objc private func checkDevicesLastConnection() {
        for (index, device) in devices.enumerated() {
                if(Date.now.timeIntervalSince(device.lastConnection!) > BluetoothConstants.LastConnectionInterval) {
                   // Send a Ping to the device
                    sendInitialPing(device)
                    
                    // Set a timer to check if there was ever a response to the ping
                    let context = ["name": device.fullName]
                    devices[index].pingTimeOutTimer = Timer.scheduledTimer(timeInterval: 30,
                                                                           target: self,
                                                                           selector: #selector(pingTimeout),
                                                                           userInfo: context,
                                                                           repeats: false)
                    
                    print("sent a ping to \(devices[index].displayName), timer starting")
                }
            }
    }
    public func processReceivedPing(_ data: Data){
        
        let receivedData = String(decoding: data, as: UTF8.self)
        
        guard let decodedBTPing: BTPing = BTPingDecoder(message: receivedData) else {
            print("unable to decode message")
            return;
        }
        
        switch(decodedBTPing.pingType) {
        // if a device ping us first, we respond to the ping
        // and update the last connection which also invalidates any active timers
        case .initialPing:
            respondToPing(decodedBTPing)
            if let index = findDeviceIndex(name: decodedBTPing.pingSender) {
                devices[index].updateLastConnection()
                print("received an initial ping from \(devices[index].displayName)")
            }
            
        // if we receive a response to a ping we update
        // the last connection which also invalidates any active timers
        case .responsePing:
            if let index = findDeviceIndex(name: decodedBTPing.pingReceiver) {
                devices[index].updateLastConnection()
                print("received a response ping from \(devices[index].displayName)")
            }
        }
    }
    public func sendInitialPing(_ device: Device){
        
        guard let sender = self.name else {
            print("unable to ping, name not set")
            return;
        }
        
        let receiver = device.displayName + BluetoothConstants.NameIdentifierSeparator + device.id.uuidString
        let codedMessage = BTPing(pingType: .initialPing, pingSender: sender, pingReceiver: receiver)
        
        guard let messageData = BTPingEncoder(message: codedMessage) else {
            print("could not enconde message")
            return;
        }
        
        sendData(send: messageData, to: receiver, characteristic: BluetoothConstants.pingCharacteristicID)
        
    }
    private func respondToPing(_ pingReceived: BTPing){
        
        var pingResponse = pingReceived;
        pingResponse.pingType = .responsePing
        
        guard let messageData = BTPingEncoder(message: pingResponse) else {
            print("could not enconde message")
            return;
        }
        
        sendData(send: messageData, to: pingReceived.pingSender, characteristic: BluetoothConstants.pingCharacteristicID)
    }
    
    // If pingTimeout is triggered, we removed the device from the list
    @objc public func pingTimeout(timer: Timer){
        guard let context = timer.userInfo as? [String: String] else { return }
            let name = context["name", default: "Anonymous"]
        
        if let indexToRemove = findDeviceIndex(name: name) {
            print("removing device \(devices[indexToRemove].displayName)")
            self.devices.remove(at: indexToRemove)
            
        }
        
    }
    
    public func updateLastConnection(_ peripheral: CBPeripheral) {
        for (index, device) in devices.enumerated() {
            if(peripheral == device) {devices[index].updateLastConnection()}
        }
    }
    
    public func updateLastConnection(_ central: CBCentral) {
        for (index, device) in devices.enumerated() {
            if(central == device) {devices[index].updateLastConnection()}
        }
    }
}


/*
 * Utility methods for device/user look up
 */
extension BluetoothController {
   
   // Look up device using the unique ID
   private func findDevice(name: String) -> Device? {
       
       let id = BluetoothController.retrieveID(name: name)
       
       
       if let i = devices.firstIndex(where: { $0.id == id }) {
           return devices[i]
       } else {
           return nil;
       }
   }
    
    // Look up device using the unique ID
    private func findDeviceIndex(name: String) -> Int? {
        
        let id = BluetoothController.retrieveID(name: name)
        if let i = devices.firstIndex(where: { $0.id == id }) {
            return i
        } else {
            return nil;
        }
    }
   
   // Returns only the username of the device using the Separator
   public static func retrieveUsername(name: String) -> String {
       return name.components(separatedBy: BluetoothConstants.NameIdentifierSeparator)[0]
       
   }
   
   // Returns only the ID of the device using the Separator
   public static func retrieveID(name: String) -> UUID {
       guard let ID: UUID = UUID(uuidString: name.components(separatedBy: BluetoothConstants.NameIdentifierSeparator)[1]) else {
           return UUID()
       }
       
       return ID;
   }
   
   // Returns true if the device is reachable, else false.
   // Used for displaying the current availability of the user in the UI
   public func isReachable(_ toFind: UUID) -> Bool {
       return devices.contains { $0.id == toFind };
   }
}


/*
 * Utility functions for Encoding/Decoding Bluetooth Messages
 */
extension BluetoothController {
    
    private func BTMessageDecoder(message: String) -> BTMessage? {
        
        //2 - Convert the string to data
        let messageData = Data(message.utf8)

        //3 - Create a JSONDecoder instance
        let jsonDecoder = JSONDecoder()
        
        //4 - set the keyDecodingStrategy to convertFromSnakeCase on the jsonDecoder instance
        jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
        
        //5 - Use the jsonDecoder instance to decode the json into a Person object
        do {
            let decodedMessage = try jsonDecoder.decode(BTMessage.self, from: messageData)
            print("Sender -- \(decodedMessage.sender) said: \(decodedMessage.message)")
            return decodedMessage;
        } catch {
            print("Error: \(error.localizedDescription)")
            return nil;
        }
        
    }
    
    private func BTPingDecoder(message: String) -> BTPing? {
        
        //2 - Convert the string to data
        let messageData = Data(message.utf8)

        //3 - Create a JSONDecoder instance
        let jsonDecoder = JSONDecoder()
        
        //4 - set the keyDecodingStrategy to convertFromSnakeCase on the jsonDecoder instance
        jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
        
        //5 - Use the jsonDecoder instance to decode the json into a Person object
        do {
            let decodedMessage = try jsonDecoder.decode(BTPing.self, from: messageData)
            print("Sender -- \(decodedMessage.pingSender) sent ping")
            return decodedMessage;
        } catch {
            print("Error: \(error.localizedDescription)")
            return nil;
        }
        
    }
    
    public func BTMessageEncoder(message: BTMessage) -> Data? {
                
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = .prettyPrinted
        
        do {
            let encodeMessage = try jsonEncoder.encode(message)
            return encodeMessage;
        } catch {
            print(error.localizedDescription)
            return nil;
        }
    }
    
    public func BTPingEncoder(message: BTPing) -> Data? {
                
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = .prettyPrinted
        
        do {
            let encodeMessage = try jsonEncoder.encode(message)
            return encodeMessage;
        } catch {
            print(error.localizedDescription)
            return nil;
        }
    }
}

