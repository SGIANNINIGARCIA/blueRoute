//
//  ChatService.swift
//  blueRoute
//
//  Created by Sandro Giannini on 12/6/22.
//

import Foundation
import CoreData

// Main object for handling chat specific operations
// ChatService handles saving messages sent/received through Bluetooth
// and creating new chats/users when they don't exist in coredata
//
// On sending, the object sends the message using a weak reference to the
// BluetoothController and then looks up the chat the message belongs to,
// if it doesn't exist (first contact), then it creates a new user/chat and
// saves the sent message to that chat
//
// The same process applies for receiving. BluetoothController calls the processReceivedMessage function
// and the object looks up the existing chats, if it doesn't exist it creates it and saves the chat to it

class ChatService {
    
    weak var bluetoothController: BluetoothController?
    private var managedObjContext: NSManagedObjectContext?
    
    init(_ bluetoothController: BluetoothController, managedObjContext: NSManagedObjectContext ) {
        self.bluetoothController = bluetoothController;
        self.managedObjContext = managedObjContext;
    }
    
    
    public func processReceivedMessage(){}
    public func sendMessage(){}
    private func chatLookUp(){}
    private func createNewChat(){}
}
