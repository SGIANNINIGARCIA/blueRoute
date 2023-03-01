//
//  BluetoothController.swift
//  blueRoute
//
//  Created by Sandro Giannini on 11/22/22.
//

import Foundation
import CoreBluetooth
import CoreData

typealias Device = Vertex;

class BluetoothController: ObservableObject {
    
    // Variables holding our bluetooth managers
    @Published var peripheral: BluetoothPeripheralManager?
    @Published var central: BluetoothCentralManager?
    @Published var devices = [Device]();
    @Published var adjList: AdjacencyList?
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
        
        self.adjList = AdjacencyList(name: name)
        
        self.pingDevicesTimer = Timer.scheduledTimer(timeInterval: 30,
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
        
        guard let messageData = BTMessage.BTMessageEncoder(message: codedMessage) else {
            print("could not enconde message")
            return;
        }
        
       var successful = sendData(send: messageData, to: name, characteristic: BluetoothConstants.chatCharacteristicID)
        saveMessage(message: codedMessage, isSelf: true, sendStatus: successful)
    }
    
    // Decodes chat message sent to this devices through the chat characteristic
    public func processIncomingChatMessage(_ data: Data){
        
        let receivedData = String(decoding: data, as: UTF8.self)
        
        guard let decodedMessage: BTMessage = BTMessage.BTMessageDecoder(message: receivedData) else {
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

// Methods to handle Handshake
extension BluetoothController {
    
    // Send handshake to device using the passed CBPeer
    func sendHandshake(_ sendTo: CBPeer){
        
        let processedAdjList = adjList!.processForExchange()
        let handshakeMessage = BTHandshake(name: self.name!, adjList: processedAdjList)
        
        guard let messageData = BTHandshake.BTHandshakeEncoder(message: handshakeMessage) else {
            print("could not enconde message")
            return;
        }
        
        switch(sendTo) {
        case is CBCentral:
            self.peripheral?.sendData(messageData, central: sendTo as! CBCentral, characteristic: BluetoothConstants.handshakeCharacteristicID)
        case is CBPeripheral:
            self.central?.sendData(messageData, peripheral: sendTo as! CBPeripheral, characteristic: BluetoothConstants.handshakeCharacteristicID)
        default:
            print("unable to send handshale")
        }
    }
    
    func processHandshake(_ data: Data, from device: CBPeer){
        
        let receivedData = String(decoding: data, as: UTF8.self);
        
        guard let decodedBTHandshake: BTHandshake = BTHandshake.BTHandshakeDecoder(message: receivedData) else {
            print("unable to decode handshake")
            return;
        }
        
        switch(device) {
        case is CBPeripheral:
            // add the new/updated vertex to the adjlist with a reference to the peripheral
            print("adding/updating vertex with peripheral")
            
        case is CBCentral:
            // add the new/updated vertex to the adjlist with a reference to the peripheral
            print("adding/updating vertex with central")
        default:
            print("unable to process")
        }
    }
}

// Methods to handle Pinging
extension BluetoothController {
    
    @objc private func checkDevicesLastConnection() {
        for (index, device) in devices.enumerated() {
                if(Date.now.timeIntervalSince(device.lastKnownPing!) > BluetoothConstants.LastConnectionInterval) {
                   // Send a Ping to the device
                    sendInitialPing(device)
                    
                    // Set a timer to check if there was ever a response to the ping
                    let context = ["name": device.fullName]
                    devices[index].setPingTimer(Timer.scheduledTimer(timeInterval: BluetoothConstants.TimeOutInterval,
                                                                           target: self,
                                                                           selector: #selector(pingTimeout),
                                                                           userInfo: context,
                                                                           repeats: false))
                    
                    print("sent a ping to \(devices[index].displayName), timer starting")
                }
            }
    }
    public func processReceivedPing(_ data: Data){
        
        let receivedData = String(decoding: data, as: UTF8.self)
        
        guard let decodedBTPing: BTPing = BTPing.BTPingDecoder(message: receivedData) else {
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
        
        var adjList = (adjList?.processForExchange())!
        
        let receiver = device.displayName + BluetoothConstants.NameIdentifierSeparator + device.id.uuidString
        let codedMessage = BTPing(pingType: .initialPing, pingSender: sender, pingReceiver: receiver, adjList: adjList)
        
        guard let messageData = BTPing.BTPingEncoder(message: codedMessage) else {
            print("could not enconde message")
            return;
        }
        
        sendData(send: messageData, to: receiver, characteristic: BluetoothConstants.pingCharacteristicID)
        
    }
    private func respondToPing(_ pingReceived: BTPing){
        
        var pingResponse = pingReceived;
        pingResponse.pingType = .responsePing
        
        guard let messageData = BTPing.BTPingEncoder(message: pingResponse) else {
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
            
            // removing central connection first, if there is one
            if let peripheralToDisconnect = self.devices[indexToRemove].peripheral {
                self.central?.removePeripheral(peripheralToDisconnect)
            }
            
            // removing from published devices list
            self.devices.remove(at: indexToRemove)
            
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

