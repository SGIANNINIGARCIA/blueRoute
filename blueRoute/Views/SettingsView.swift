//
//  SettingsView.swift
//  blueRoute
//
//  Created by Sandro Giannini on 11/25/22.
//

import SwiftUI

struct SettingsView: View {
    @State var username: String = "";
    @EnvironmentObject var dataController: DataController;
    @State var generatedUserInput: String = ""
    
    var body: some View {
        Form {
            Section("Generate Test Chat") {
                VStack {
                    TextField("Type the Test Username here", text:$generatedUserInput)
                        .foregroundColor(.black)
                        .font(Font.custom("KarlaRegular", size: 16))
                    Divider()
                        .background(/*@START_MENU_TOKEN@*//*@PLACEHOLDER=View@*/Color.white/*@END_MENU_TOKEN@*/)
                    Button("Create") {
                        self.dataController.createTestConversation(username: generatedUserInput)
                        generatedUserInput = ""
                    }.padding(.top, 8).buttonStyle(.bordered)
                }
            }
        }
        .scrollDismissesKeyboard(.immediately)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
