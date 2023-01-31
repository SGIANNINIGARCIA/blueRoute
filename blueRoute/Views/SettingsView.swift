//
//  SettingsView.swift
//  blueRoute
//
//  Created by Sandro Giannini on 11/25/22.
//

import SwiftUI

struct SettingsView: View {
    
    @State var username: String = "";
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                Text("Change Username")
                    .font(Font.custom("KarlaRegular", size: 28))
                    .padding(.horizontal)
                TextField("Type here", text:$username)
                    .font(Font.custom("KarlaRegular", size: 22))
                    .padding(.horizontal)
                Divider()
                    .background(/*@START_MENU_TOKEN@*//*@PLACEHOLDER=View@*/Color.white/*@END_MENU_TOKEN@*/)
                    .padding(.horizontal)
                HStack {
                    Spacer()
                    Button("submit") {
                        print("clicked")
                    }
                        .fontWeight(/*@START_MENU_TOKEN@*/.regular/*@END_MENU_TOKEN@*/)
                        .font(Font.custom("KarlaBold", size: 24))
                }
                .padding(.horizontal)
            } .navigationTitle("Settings")
                .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .principal) {
                                HStack {
                                    Text("Settings")
                                        .font(Font.custom("LatoBold", size: 52))
                                        .padding(.top, 32.0)
                                    
                                    Spacer()
                                }
                            }
                        }
            
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
