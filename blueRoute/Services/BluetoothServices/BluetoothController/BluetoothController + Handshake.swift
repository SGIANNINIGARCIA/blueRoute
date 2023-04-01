//
//  BluetoothController + Handshake.swift
//  blueRoute
//
//  Created by Sandro Giannini on 3/31/23.
//

import Foundation
import CoreBluetooth

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
           let vertex = self.adjList.processHandshake(from: decodedBTHandshake.name, peripheral: device as! CBPeripheral)
            print("adding/updating vertex with peripheral")
            sendAdjacencyRequest(to: vertex)
            
        case is CBCentral:
            let vertex = self.adjList.processHandshake(from: decodedBTHandshake.name, central: device as! CBCentral)
            print("adding/updating vertex with central")
            sendAdjacencyRequest(to: vertex)
        default:
            print("unable to process")
        }
    }
}
