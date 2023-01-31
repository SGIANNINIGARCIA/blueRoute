//
//  blueRouteApp.swift
//  blueRoute
//
//  Created by Sandro Giannini on 11/10/22.
//

import SwiftUI

@main
struct blueRouteApp: App {
    @StateObject private var dataController: DataController;
    @StateObject var chatsStorage: ChatsStorage;
    
    init() {
        let dataController = DataController()
        self._dataController = StateObject(wrappedValue: dataController);
        
        
        let chats = ChatsStorage(managedObjectContext: dataController.container.viewContext)
        self._chatsStorage = StateObject(wrappedValue: chats);
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, dataController.container.viewContext)
                .environmentObject(dataController)
                .environmentObject(chatsStorage)
                
        }
    }
}
