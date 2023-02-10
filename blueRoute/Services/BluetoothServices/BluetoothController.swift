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
                                         selector: #selector(pingDevices),
                                         userInfo: nil,
                                         repeats: true)
    }
    
    public func sendMessage(send message: String, to name: String) -> Void {
        
        let codedMessage = BTMessage(sender: self.name!, message: message, receiver: name, type: .chat)
        
        guard let messageData = MessageEncoder(message: codedMessage) else {
            print("could not enconde message")
            return;
        }
        
        guard let device = findDevice(name: name) else {
            print("could not find \(name)")
            return;
        }
        
        // send the message using the newest reference we saved for the device
        switch device.sendTo {
        case .peripheral:
            
           if let peripheral = device.peripheral {
               central!.sendData(messageData, peripheral: peripheral, characteristic: BluetoothConstants.chatCharacteristicID)
           } else {
               fallthrough
           }
            
        case .central:
            if let central = device.central {
                peripheral!.sendChatMessage(messageData, central: central)
            } else {
                fallthrough
            }
            
        default:
            print("unable to send message - could not find a reference to the device")
            saveMessage(message: codedMessage, isSelf: true, sendStatus: false)
        }

        saveMessage(message: codedMessage, isSelf: true, sendStatus: true)
    }
    
    public func processReceivedData(data: Data) {
        
        // Decode the message string
        let receivedData = String(decoding: data, as: UTF8.self)
        
        guard let decodedMessage: BTMessage = MessageDecoder(message: receivedData) else {
            print("unable to decode message")
            return;
        }
        
        switch decodedMessage.type {
        case .chat:
            saveMessage(message: decodedMessage, isSelf: false, sendStatus: true)
        case .routing:
            print("message for routing")
        }
        
    }
    
    private func saveMessage(message: BTMessage, isSelf: Bool, sendStatus: Bool) {
        dataController?.saveMessage(message: message, context: managedObjContext!, isSelf: isSelf, sendStatus: sendStatus)
    }
}

/*
 * Functions to handle incoming data
 */

extension BluetoothController {
    
    // Decodes chat message sent to this devices through the chat characteristic
    public func processIncomingChatMessage(_ data: Data){
        
        let receivedData = String(decoding: data, as: UTF8.self)
        
        guard let decodedMessage: BTMessage = MessageDecoder(message: receivedData) else {
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


/*
 * Utility functions for Encoding/Decoding Bluetooth Messages (BTMessage)
 */
extension BluetoothController {
    
    private func MessageDecoder(message: String) -> BTMessage? {
        
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
    
    public func MessageEncoder(message: BTMessage) -> Data? {
                
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
    
    // Returns only the username of the device using the Separator
    public static func retrieveUsername(name: String) -> String {
        return name.components(separatedBy: BluetoothConstants.NameIdentifierSeparator)[0]
        
    }
    
    // Returns only the ID of the device using the Separator
    public static func retrieveID(name: String) -> UUID {
        print("this is the name\(name)")
        
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

// Background tasks
extension BluetoothController {
    
    @objc private func pingDevices() {
            for device in devices {
                if(Date.now.timeIntervalSince(device.lastConnection!) < BluetoothConstants.LastConnectionInterval) {
                    // Send Ping
                }
            }
    }
}
