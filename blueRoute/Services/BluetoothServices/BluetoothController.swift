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
    
    init() {
    }
    
    public func setUp(name: String, dataController: DataController, context: NSManagedObjectContext) -> Void {
        self.name = name;
        // instantiating the peripheral manager which wont start broadcasting immediately
        // but will wait until we provide an username
        self.peripheral = BluetoothPeripheralManager(name: name, bluetoothController: self )
        // instantiating the central manager which wont start discovering immediately
        // but will wait until we provide an username
        self.central = BluetoothCentralManager(name: name, bluetoothController: self)
        
        self.dataController = dataController;
        self.managedObjContext = context;
    }
    
    // Returns true if the device is reachable, else false.
    // Used for displaying the current availability of the user in the UI
    public func isReachable(_ toFind: UUID) -> Bool {
        return devices.contains { $0.id == toFind };
    }
}

extension BluetoothController {
    
    public func sendMessage(send message: String, to name: String) -> Void {
        
        let codedMessage = BTMessage(sender: self.name!, message: message, receiver: name)
        
        guard let device = findDevice(name: name) else {
            print("could not find \(name)")
            return;
        }
        
        guard let messageData = MessageEncoder(message: codedMessage) else {
            print("could not enconde message")
            return;
        }
        
        central!.sendData(messageData, peripheral: device.peripheral!)
        dataController?.saveMessage(message: codedMessage, context: managedObjContext!, isSelf: true)
    }
    
    public func processReceivedData(data: Data) {
        
        // Decode the message string
        let receivedData = String(decoding: data, as: UTF8.self)
        
        guard let decodedMessage: BTMessage = MessageDecoder(message: receivedData) else {
            print("unable to decode message")
            return;
        }
        
        dataController?.saveMessage(message: decodedMessage, context: managedObjContext!, isSelf: false)
    }
    
    // Look up device using the unique ID
    private func findDevice(name: String) -> Device? {
        
        let id = BluetoothController.retrieveID(name: name)
        
        
        if let i = devices.firstIndex(where: { $0.id == id }) {
            return devices[i]
        } else {
            return nil;
        }
    }
    
    
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
    
    private func MessageEncoder(message: BTMessage) -> Data? {
                
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


// Extension for utility methods
extension BluetoothController {
    
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

    
    
}
