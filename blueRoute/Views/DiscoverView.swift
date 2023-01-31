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
                    ForEach(bluetoothController.devices) { user in
                        NavigationLink {
                            ChatView(displayName: user.displayName, id: user.id)
                        } label: {
                            Text(user.displayName)
                        }
                    }
                    
                    
                    .emptyState(bluetoothController.devices.count == 0) {
                        
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
    }
}

struct DiscoverView_Previews: PreviewProvider {
    static var previews: some View {
        DiscoverView()
    }
}
