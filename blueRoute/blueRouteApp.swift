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
    @StateObject var bluetoothController: BluetoothController;
    @StateObject var userSettings: UserSettings = UserSettings()
    
    init() {
        
        // Initiate data controller to pass it to the bluetoothManager
        let dataController = DataController()
        self._dataController = StateObject(wrappedValue: dataController);
        
        // Initiate bluetoothManager and pass core data context and data manager
        let bluetoothController = BluetoothController(dataController: dataController, context: dataController.container.viewContext)
        self._bluetoothController = StateObject(wrappedValue: bluetoothController);
        
        
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, dataController.container.viewContext)
                .environmentObject(bluetoothController)
                .environmentObject(dataController)
                .environmentObject(userSettings)
        }
    }
}
