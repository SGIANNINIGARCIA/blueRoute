//
//  BluetoothController + Routing.swift
//  blueRoute
//
//  Created by Sandro Giannini on 3/31/23.
//

import Foundation
import CoreBluetooth

extension BluetoothController {
    
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
        
        _ = sendData(send: messageData, to: nextHop, characteristic: BluetoothConstants.routingCharacteristicID)
    }
    
    public func sendRoutedMessage(send message: String, to name: String){
        
        let btMessage = BTMessage(sender: self.name!, message: message, receiver: name)
        let messageToRoute = BTRoutedMessage(targetUser: name, BTmessage: btMessage)
        
        routeMessage(messageToRoute: messageToRoute)
        
    }
}
