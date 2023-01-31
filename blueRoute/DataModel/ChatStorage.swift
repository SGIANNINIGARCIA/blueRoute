//
//  ChatStorage.swift
//  blueRoute
//
//  Created by Sandro Giannini on 12/4/22.
//

import Foundation
import CoreData

class ChatsStorage: NSObject, ObservableObject {
  @Published var chats: [User] = []
  private let chatsController: NSFetchedResultsController<User>

  init(managedObjectContext: NSManagedObjectContext) {
      chatsController = NSFetchedResultsController(fetchRequest: User.chatsFetchRequest,
    managedObjectContext: managedObjectContext,
    sectionNameKeyPath: nil, cacheName: nil)

    super.init()

    chatsController.delegate = self

    do {
      try chatsController.performFetch()
      chats = chatsController.fetchedObjects ?? []
    } catch {
      print("failed to fetch items!")
    }
  }
}

extension ChatsStorage: NSFetchedResultsControllerDelegate {
  func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    guard let fetchedChats = controller.fetchedObjects as? [User]
      else { return }

      chats = fetchedChats;
  }
}


extension User {
  static var chatsFetchRequest: NSFetchRequest<User> {
    let request: NSFetchRequest<User> = User.fetchRequest()
    request.predicate = NSPredicate(format: "isSelf == %@", NSNumber(false))
    request.sortDescriptors = [NSSortDescriptor(key: "displayName", ascending: true)]

    return request
  }
}
