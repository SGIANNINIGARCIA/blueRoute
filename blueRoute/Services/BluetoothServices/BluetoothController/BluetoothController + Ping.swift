//
//  BluetoothController + Ping.swift
//  blueRoute
//
//  Created by Sandro Giannini on 3/31/23.
//

import Foundation
import CoreBluetooth

extension BluetoothController {
    
    @objc func checkDevicesLastConnection() {
        
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
    public func sendInitialPing(_ vertex: Vertex){
        
        guard let sender = self.name else {
            print("unable to ping, name not set")
            return;
        }
        
        let receiver = vertex.displayName + BluetoothConstants.NameIdentifierSeparator + vertex.id.uuidString
        let codedMessage = BTPing(pingType: .initialPing, pingSender: sender, pingReceiver: receiver)
        
        guard let messageData = BTPing.BTPingEncoder(message: codedMessage) else {
            print("could not enconde message")
            return;
        }
        
        _ = sendData(send: messageData, to: vertex, characteristic: BluetoothConstants.pingCharacteristicID)
        
    }
    private func respondToPing(_ pingReceived: BTPing){
        
        var pingResponse = pingReceived;
        pingResponse.pingType = .responsePing
        
        guard let messageData = BTPing.BTPingEncoder(message: pingResponse) else {
            print("could not enconde message")
            return;
        }
        
       _ = sendData(send: messageData, to: pingReceived.pingSender, characteristic: BluetoothConstants.pingCharacteristicID)
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
