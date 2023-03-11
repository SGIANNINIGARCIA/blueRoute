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
    
    /// Variables holding our bluetooth managers
    @Published var peripheral: BluetoothPeripheralManager?
    @Published var central: BluetoothCentralManager?
    @Published var adjList: AdjacencyList = AdjacencyList();
    
    var managedObjContext: NSManagedObjectContext?;
    weak var dataController: DataController?;
    
    /// Full name (displayName + unique ID)
    var name: String?
    
    private var pingDevicesTimer: Timer?
    private var pingedDevices = [Device]();
    
    /// Member to hold the AdjList exchanges that have not been completed yet
    /// where the key is the vertex we are sending the AdjacencyList and PendingExchange is
    /// a struct holding the data to send
    public var pendingAdjacencyExchangesSent: [Vertex: PendingExchange] = [:]
    public var pendingAdjacencyExchangesReceived: [Vertex: PendingExchange] = [:]
    private var exchangeTimer: Timer?
    private var exchangeCleanUpTimer: Timer?
    
    
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
        
        self.adjList.setSelf(name: name)
        
        self.pingDevicesTimer = Timer.scheduledTimer(timeInterval: 30,
                                         target: self,
                                         selector: #selector(checkDevicesLastConnection),
                                         userInfo: nil,
                                         repeats: true)
        
        
        self.exchangeTimer = Timer.scheduledTimer(timeInterval: 30,
                                                  target: self,
                                                  selector: #selector(checkLastAdjacencyExchange),
                                                  userInfo: nil,
                                                  repeats: true)
        
        self.exchangeCleanUpTimer = Timer.scheduledTimer(timeInterval: 30,
                                                  target: self,
                                                  selector: #selector(cleanUpPendingExchanges),
                                                  userInfo: nil,
                                                  repeats: true)
    }
    
    // send data to a characteristic and returns true if it succeded
    public func sendData(send data: Data, to name: String, characteristic: CBUUID) -> Bool {
            
        guard let vertex = findVertex(name: name) else {
            print("could not find \(name)")
            return false;
        }
        
        // send the message using the newest reference we saved for the device
        switch vertex.sendTo {
        case .peripheral:
           if let peripheral = vertex.peripheral {
               central!.sendData(data, peripheral: peripheral, characteristic: characteristic)
               return true;
           } else {
               fallthrough
           }
        case .central:
            if let central = vertex.central {
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
    
    // send data to a characteristic and returns true if it succeded with a vertex
    public func sendData(send data: Data, to vertex: Vertex, characteristic: CBUUID) -> Bool {
        
        // send the message using the newest reference we saved for the device
        switch vertex.sendTo {
        case .peripheral:
           if let peripheral = vertex.peripheral {
               central!.sendData(data, peripheral: peripheral, characteristic: characteristic)
               return true;
           } else {
               fallthrough
           }
        case .central:
            if let central = vertex.central {
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
    
    /// Used by ChatView to send a chat message
    ///
    /// The method checks if the message needs to be routed or if the target useris one of our neighbors.
    /// If it needs to be routed, it is passed to the methiod sendRoutedMessage for processing; if not, it is coded and sent to
    /// the sendData method
    ///
    /// - Parameters:
    ///     - message: the string to be sent
    ///     - name: the name (displayName + ID) of the target user
    ///
    public func sendChatMessage(send message: String, to name: String) {
        
        if (self.adjList.isNeighbor(name) == false) {
            return sendRoutedMessage(send: message, to: name)
        }
        
        let codedMessage = BTMessage(sender: self.name!, message: message, receiver: name)
        
        guard let messageData = BTMessage.BTMessageEncoder(message: codedMessage) else {
            print("could not enconde message")
            return;
        }
        
       var successful = sendData(send: messageData, to: name, characteristic: BluetoothConstants.chatCharacteristicID)
        saveMessage(message: codedMessage, isSelf: true, sendStatus: successful)
    }
    
    /// Decodes chat message sent to this devices through the chat characteristic
    ///
    /// - parameters:
    ///     - data: the data received by our peripheral/central
    ///     - from: a reference to the device who sent the data which we use to update their last connection and invalidate ping, if any
    ///
    /// - note: the parameter from is not referencing the original sender of the message, but the device who sent the data
    public func processIncomingChatMessage(_ data: Data, from ref: CBPeer){
        
        let receivedData = String(decoding: data, as: UTF8.self)
        
        guard let decodedMessage: BTMessage = BTMessage.BTMessageDecoder(message: receivedData) else {
            print("unable to decode message")
            return;
        }
        
        updateLastConnectionAndInvalidateTimer(for: ref)
        saveMessage(message: decodedMessage, isSelf: false, sendStatus: true)
    
    }
    
    /// Decodes routing message sent to this devices through the routing characteristic, searches for next node and sends it
    ///
    /// - parameters:
    ///     - data: the data received by our peripheral/central
    ///     - from: a reference to the device who sent the data which we use to update their last connection and invalidate ping, if any
    ///
    /// - note: the parameter from is not referencing the original sender of the message, but the device who sent the data
    public func processIncomingRoutingMessage(_ data: Data, from ref: CBPeer){
        
        let receivedData = String(decoding: data, as: UTF8.self)
        
        guard let decodedMessage: BTRoutedMessage = BTRoutedMessage.BTRoutedMessageDecoder(message: receivedData) else {
            print("unable to decode message")
            return;
        }
        
        // save message if we are the target
        if(decodedMessage.targetUser == self.name) {
            saveMessage(message: decodedMessage.BTmessage, isSelf: false, sendStatus: true)
        } else {
            routeMessage(messageToRoute: decodedMessage)
        }
        
        updateLastConnectionAndInvalidateTimer(for: ref)
    }
    
    func routeMessage(messageToRoute: BTRoutedMessage) {
        
        guard let targetVertex = self.adjList.findVertex(messageToRoute.targetUser) else {
            return print("unable to find a vertex with this name")
        }
        
        guard let nextHop = self.adjList.nextHop(targetVertex) else {
            return print("unable to route the message, no known path to target")
        }
        
        guard let messageData = BTRoutedMessage.BTRoutedMessageEncoder(message: messageToRoute) else {
            print("could not enconde message")
            return;
        }
        
        var successful = sendData(send: messageData, to: nextHop.fullName, characteristic: BluetoothConstants.routingCharacteristicID)
    }
    
    public func sendRoutedMessage(send message: String, to name: String){
        
        let btMessage = BTMessage(sender: self.name!, message: message, receiver: name)
        let messageToRoute = BTRoutedMessage(targetUser: name, BTmessage: btMessage)
        
        routeMessage(messageToRoute: messageToRoute)
        
    }
}

// Methods to handle Handshake
extension BluetoothController {
    
    // Send handshake to device using the passed CBPeer
    func sendHandshake(_ sendTo: CBPeer){
        let handshakeMessage = BTHandshake(name: self.name!)
        
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
            self.adjList.processHandshake(from: decodedBTHandshake.name, peripheral: device as! CBPeripheral)
            print("adding/updating vertex with peripheral")
            
        case is CBCentral:
            self.adjList.processHandshake(from: decodedBTHandshake.name, central: device as! CBCentral)
            print("adding/updating vertex with central")
        default:
            print("unable to process")
        }
    }
}

// Methods to handle Pinging
extension BluetoothController {
    
    @objc private func checkDevicesLastConnection() {
        
        let neighbors = self.adjList.getNeighbors()
        
        for (neighbor) in neighbors {
            
            // Check if its time to send a ping
                if(Date.now.timeIntervalSince(neighbor.lastKnownPing!) > BluetoothConstants.LastConnectionInterval) {
                   // Send a Ping to the device
                    sendInitialPing(neighbor)
                    
                    // Set a timer to check if there was ever a response to the ping
                    let context = ["name": neighbor.fullName]
                    neighbor.setPingTimer(Timer.scheduledTimer(timeInterval: BluetoothConstants.TimeOutInterval,
                                                                           target: self,
                                                                           selector: #selector(pingTimeout),
                                                                           userInfo: context,
                                                                           repeats: false))
                    
                    print("sent a ping to \(neighbor.displayName), timer starting")
                }
            }
    }
    public func processReceivedPing(_ data: Data){
        
        let receivedData = String(decoding: data, as: UTF8.self)
        
        guard let decodedBTPing: BTPing = BTPing.BTPingDecoder(message: receivedData) else {
            print("unable to decode message \(receivedData)")
            return;
        }
        
        switch(decodedBTPing.pingType) {
            
        // if a device ping us first, we respond to the ping
        // and update the last connection which also invalidates any active timers
        case .initialPing:
            respondToPing(decodedBTPing)
            if let vertex = findVertex(name: decodedBTPing.pingSender) {
                // Update our lastconnection to this device/vertex
                updateLastConnectionAndInvalidateTimer(for: vertex)
                
                print("received an initial ping from \(vertex.displayName)")
            }
            
        // if we receive a response to a ping we update
        // the last connection which also invalidates any active timers
        case .responsePing:
            if let vertex = findVertex(name: decodedBTPing.pingReceiver) {
                // Update our lastconnection to this device/vertex
                updateLastConnectionAndInvalidateTimer(for: vertex)
                
                print("received a response ping from \(vertex.displayName)")
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
        
        if let vertexToRemove = findVertex(name: name) {
            print("removing device \(vertexToRemove.displayName)")
            
            // removing central connection first, if there is one
            if let peripheralToDisconnect = vertexToRemove.peripheral {
                self.central?.removePeripheral(peripheralToDisconnect)
            }
            
            // removing from published devices list
            self.adjList.removeConnection(vertexToRemove)
            
        }
    }
    
    public func updateLastConnectionAndInvalidateTimer(for vertex: Vertex) {
        vertex.updateLastConnection();
    }
    
    
    public func updateLastConnectionAndInvalidateTimer(for ref: CBPeer) {
        switch(ref) {
        case is CBCentral:
            guard let vertex = findVertex(central: ref as! CBCentral) else {
                return;
            }
            vertex.updateLastConnection()
        case is CBPeripheral:
            guard let vertex = findVertex(peripheral: ref as! CBPeripheral) else {
                return;
            }
            vertex.updateLastConnection()
        default:
            print("none of the above")
        }
    }
}

///  Methods to handle the exchange of Adjacency list
extension BluetoothController {
    
}


/*
 * Utility methods for device/user and ID/DisplayName look up
 */
extension BluetoothController {
      
    /// Returns the displayName in a fullName
    ///
    ///  - Parameters:
    ///     - name: string containing the fullName of a vertex
    ///
   public static func retrieveUsername(name: String) -> String {
       return name.components(separatedBy: BluetoothConstants.NameIdentifierSeparator)[0]
       
   }
   
    /// Returns the unique ID in a fullName
    ///
    ///  - Parameters:
    ///     - name: string containing the fullName of a vertex
    ///
   public static func retrieveID(name: String) -> UUID {
       guard let ID: UUID = UUID(uuidString: name.components(separatedBy: BluetoothConstants.NameIdentifierSeparator)[1]) else {
           return UUID()
       }
       
       return ID;
   }
    
    ///  Retrieves vertex from Adjacency List with matching name
    ///
    ///  - Parameters:
    ///     - name: the fullName of the vertex
    ///
    public func findVertex(name: String) -> Vertex? {
        let id = BluetoothController.retrieveID(name: name)
        
        guard let vertex = self.adjList.adjacencies.first(where: {$0.id == id}) else {
            return nil;
        }
        
        return vertex;
    }
    
    /// Retrieve the vertex with matching reference to central
    ///
    ///  - Parameters:
    ///     - central: reference of the central to match
    ///
    public func findVertex(central: CBCentral) -> Vertex? {
        guard let vertex = self.adjList.adjacencies.first(where: {$0.central?.identifier == central.identifier}) else {
            return nil;
        }
        
        return vertex;
    }
    
    /// Retrieve the vertex with matching reference to peripheral
    ///
    ///  - Parameters:
    ///     - peripheral: reference of the peripheral to match
    ///
    public func findVertex(peripheral: CBPeripheral) -> Vertex? {
        guard let vertex = self.adjList.adjacencies.first(where: {$0.peripheral?.identifier == peripheral.identifier}) else {
            return nil;
        }
        
        return vertex;
    }
   
   // Returns true if the device is reachable, else false.
   // Used for displaying the current availability of the user in the UI
   public func isReachable(_ toFind: UUID) -> Bool {
       
       let isReachable = self.adjList.adjacencies.contains(where: {$0.id == toFind})
       
       return isReachable;
   }
}

