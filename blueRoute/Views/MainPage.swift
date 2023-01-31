//
//  MainPage.swift
//  blueRoute
//
//  Created by Sandro Giannini on 11/19/22.
//

import SwiftUI

struct MainPage: View {
    
    // This is the full name (displayName + unique ID)
    @State var name: String;
    
    @StateObject var bluetoothController = BluetoothController()
    @Environment(\.managedObjectContext) var managedObjContext;
    @EnvironmentObject var dataController: DataController;
    
    
    
    var body: some View {
        TabView {
            ConversationsView()
            .environmentObject(bluetoothController)
            .tabItem {
                Image(systemName: "bubble.left.fill")
                Text("Conversations")
            }
            
            DiscoverView()
                .tabItem {
                    Image(systemName: "point.3.filled.connected.trianglepath.dotted")
                    Text("Explore")
                }
                .environmentObject(bluetoothController)
            SettingsView()
            .tabItem {
                Image(systemName: "gearshape.fill")
                Text("Settings")
            }
            
        }
        .onAppear {
            bluetoothController.setUp(name: name, dataController: dataController, context: managedObjContext)
        }
    }
}

struct MainPage_Previews: PreviewProvider {
    static var previews: some View {
        MainPage(name: "Sandro")
    }
}
