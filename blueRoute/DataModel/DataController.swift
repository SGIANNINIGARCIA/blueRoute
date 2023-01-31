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
        
        save(context: container.viewContext);
    }
    
    func save(context: NSManagedObjectContext) {
        do {
            try context.save()
            print("UserModel data has been saved")
        } catch {
            print("unable to save data in UserModel")
        }
    }
}

extension DataController {
    
    func setUser(displayName: String, isSelf: Bool = false, context: NSManagedObjectContext) {
        let user = User(context: context)
        
        // Unique identifier use for maintaining user information across name changes
        user.identifier = UUID()
        
        // User's display name
        user.displayName = displayName;
        
        // isSelf separates the current user from others in coredata
        user.isSelf = NSNumber(value: true);
        
        
        save(context: context)
    }
    
    public func saveMessage(message: BTMessage, context: NSManagedObjectContext, isSelf: Bool) {
        
        let messageToSave = Message(context: context)
        var user: User;
        
        // If message was sent by the user, the chat reference should point to the message receiver
        // else, it should point to the sender
        if(isSelf){
            user = findUser(name: message.receiver)!
        } else {
            user = findUser(name: message.sender)!
        }

        // save new message to chat
        messageToSave.chat = user;
        messageToSave.content = message.message
        messageToSave.senderIsSelf = isSelf;
        messageToSave.timestamp = Date();
        
        // change user lastmessage attribute to this new message
        user.latestMessage = message.message;
        
        save(context: context)
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
        user.isSelf = NSNumber(value: false);
        
        save(context: container.viewContext)
        
        
        return user;
    }
    
    public func delete(user: User, context: NSManagedObjectContext) {
        context.delete(user)
        
        save(context: context)
    }
    
    
}

