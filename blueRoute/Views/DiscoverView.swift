//
//  DiscoverView.swift
//  blueRoute
//
//  Created by Sandro Giannini on 11/19/22.
//

import SwiftUI

struct DiscoverView: View {
    
    //temp testing array
    @EnvironmentObject var bluetoothController: BluetoothController;
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Text("Discover")
                        .font(Font.custom("LatoBold", size: 52))
                        .padding(.top, 16.0)
                        .padding(.leading, 16.0)
                    Spacer()
                }
                List {
                    ForEach(buildAvailableList() ?? []) { user in
                        
                        NavigationLink {
                            ChatView(displayName: user.displayName, id: user.id)
                        } label: {
                            Text(user.displayName)
                        }
                    }
                    .emptyState(bluetoothController.adjList?.adjacencies.count == 0 || (buildAvailableList() == nil || ((buildAvailableList()?.isEmpty) != nil))) {
                        HStack {
                            Spacer()
                            LoadingIcon()
                            Spacer()
                        }
                    }
                    
                } .navigationTitle("Discover")
                    .toolbar(Visibility.hidden)
                
            }
        }
        
        // When user opens the discovery page,
        // prompt the central to start scanning for devices
        .onAppear {
            bluetoothController.startDiscovery()
        }
        // When user closes the discovery page,
        // prompt the central to stop scanning for devices
        .onDisappear {
            bluetoothController.stopDiscovery()
        }
    }
    
    func buildAvailableList() -> [Vertex]? {
        return bluetoothController.adjList?.adjacencies.filter({$0.fullName != bluetoothController.name})
    }
}

struct DiscoverView_Previews: PreviewProvider {
    static var previews: some View {
        DiscoverView()
    }
}
