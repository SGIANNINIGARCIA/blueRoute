//
//  MainPage.swift
//  blueRoute
//
//  Created by Sandro Giannini on 11/19/22.
//

import SwiftUI

struct MainPage: View {
    
    @State var name: String;
    @State var identifier: String;
    
    @EnvironmentObject var dataController: DataController;
    @EnvironmentObject var bluetoothController: BluetoothController;
    
    
    
    var body: some View {
        TabView {
            
            // View containing all the conversations
            ConversationsView()
            .tabItem {
                Image(systemName: "bubble.left.fill")
                Text("Conversations")
            }
            
            // View for finding reachable users
            DiscoverView()
                .tabItem {
                    Image(systemName: "point.3.filled.connected.trianglepath.dotted")
                    Text("Explore")
                }
                .environmentObject(bluetoothController)
            
            // View for changing settings
            SettingsView()
            .tabItem {
                Image(systemName: "gearshape.fill")
                Text("Settings")
            }
            test()
                .tabItem {
                    Image(systemName: "point.3.filled.connected.trianglepath.dotted")
                    Text("Explore")
                }
                .environmentObject(bluetoothController)
            
        }
        .onAppear {
            // on appear, set up the name of the device to start advertising as online
            bluetoothController.setUp(name: name + BluetoothConstants.NameIdentifierSeparator + identifier)
        }
    }
}

struct MainPage_Previews: PreviewProvider {
    static var previews: some View {
        MainPage(name: "Sandro", identifier: "Identifier")
    }
}
