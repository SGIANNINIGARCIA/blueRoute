//
//  File.swift
//  blueRoute
//
//  Created by Sandro Giannini on 11/10/22.
//

import Foundation
import CoreData

class DataController: ObservableObject {
    
    let container = NSPersistentContainer(name: "blueRoute")
    
    init(){
        container.loadPersistentStores {desc, error in
            if let error = error {
                print("Failed to load the data\(error.localizedDescription)")
            }
        }
        
        save();
    }
    
    func save() {
        do {
            try container.viewContext.save()
            print("UserModel data has been saved")
        } catch {
            print("unable to save data in UserModel")
        }
    }
}

extension DataController {
    
    public func saveMessage(message: BTMessage, isSelf: Bool, sendStatus: Bool) {
        
        let messageToSave = Message(context: container.viewContext)
        var user: User;
        var seen: Bool;
        
        // If message was sent by the user, the chat reference should point to the message receiver
        // else, it should point to the sender
        if(isSelf){
            user = findUser(name: message.receiver)!
            seen = true;
        } else {
            user = findUser(name: message.sender)!
            seen = false;
            
        }

        // save new message to chat
        messageToSave.chat = user;
        messageToSave.content = message.message
        messageToSave.senderIsSelf = isSelf;
        messageToSave.timestamp = Date();
        messageToSave.sendStatus = sendStatus;
        messageToSave.seen = seen;
        
        // change user lastmessage attribute to this new message
        user.latestMessage = message.message;
        
        save()
    }
    
    func updateMessageSeenStatus(message: Message) {
        
        if(message.seen == false) {
            message.seen = true;
            save()
        }
        
    }
    
    // find the user the chat is linked to and if there is no user
    // create one and return it
    private func findUser(name: String) -> User? {
        
        let fetchRequest: NSFetchRequest<User>
        fetchRequest = User.fetchRequest()
        
        let id = BluetoothController.retrieveID(name: name);
        
        fetchRequest.predicate = NSPredicate(format: "%K == %@", "identifier", id as CVarArg)
        
        // Get a reference to a NSManagedObjectContext
        let context = container.viewContext
        
        // Perform the fetch request to get the objects
        // matching the predicat
        do {
             let user = try context.fetch(fetchRequest)
            
            guard user.isEmpty == false else {
                return createNewUser(name: name)
            }
            
            return user[0]
          
        } catch {
            print("there was an error finding the user in coredata")
            return nil;
        }
    }
    
    // creates new user for core data and returns the user
    private func createNewUser(name: String) -> User {
        
        let user = User(context: container.viewContext)
        
        user.displayName = BluetoothController.retrieveUsername(name: name)
        user.identifier = BluetoothController.retrieveID(name: name)
        
        save()
        
        
        return user;
    }
    
    
    
}

