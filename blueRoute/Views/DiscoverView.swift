//
//  DiscoverView.swift
//  blueRoute
//
//  Created by Sandro Giannini on 11/19/22.
//

import SwiftUI

struct DiscoverView: View {

    @EnvironmentObject var bluetoothController: BluetoothController;
    @ObservedObject var adjacencyList : AdjacencyList;
    
    
    
    
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
                    Section(header: Text("Neighbors")) {
                        ForEach(adjacencyList.adjacencies.filter({self.adjacencyList.isNeighbor($0.id)})) { user in
                            NavigationLink {
                                ChatView(displayName: user.displayName, id: user.id)
                            } label: {
                                DiscoveryAvatar(name: user.displayName)
                            }
                        }
                    }
                    Section(header: Text("Reachable")) {
                        ForEach(adjacencyList.adjacencies.filter({self.adjacencyList.notANeighbor($0.id)})) { user in
                            NavigationLink {
                                ChatView(displayName: user.displayName, id: user.id)
                            } label: {
                                DiscoveryAvatar(name: user.displayName)
                            }
                        }
                    }
                    
                }
                .listStyle(GroupedListStyle())
                .navigationTitle("Discover")
                .toolbar(Visibility.hidden)
                .emptyState(adjacencyList.adjacencies.count == 1) {
                    HStack {
                        Spacer()
                        LoadingIcon()
                        Spacer()
                    }.frame(maxHeight: .infinity)
                }
        
                
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
    
    
}


struct DiscoverView_Previews: PreviewProvider {
    static var previews: some View {
        DiscoverView(adjacencyList: AdjacencyList())
    }
}



struct ImmediateDiscover: View {
    
    @Binding var adjacencies: [Vertex];
    
    var body: some View {
        Section {
            ForEach(adjacencies) { user in
                NavigationLink {
                    ChatView(displayName: user.displayName, id: user.id)
                } label: {
                    Text(user.displayName)
                }
            }
        }
    }
}
