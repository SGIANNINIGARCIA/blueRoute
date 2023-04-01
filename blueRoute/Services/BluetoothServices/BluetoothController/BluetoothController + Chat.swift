//
//  BluetoothController + Chat.swift
//  blueRoute
//
//  Created by Sandro Giannini on 3/31/23.
//

import Foundation
import CoreBluetooth

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
        
        
        /// check if the destination is a neighbor, else it passes the message to the routing method
        if (self.adjList.isNeighbor(name) == false) {
            return sendRoutedMessage(send: message, to: name)
        }
        
        let codedMessage = BTMessage(sender: self.name!, message: message, receiver: name)
        
        guard let messageData = BTMessage.BTMessageEncoder(message: codedMessage) else {
            print("could not enconde message")
            return;
        }
        
        let successful = sendData(send: messageData, to: name, characteristic: BluetoothConstants.chatCharacteristicID)
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
}
