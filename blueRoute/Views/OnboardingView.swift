//
//  OnboardingView.swift
//  blueRoute
//
//  Created by Sandro Giannini on 11/10/22.
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var userSettings: UserSettings;
    
    @State var userInput:String = "";
    @State private var animationAmount = 5.0;
    
    var body: some View {
        VStack(alignment: .leading) {
            Spacer()
            Text("1.")
                .font(Font.custom("LatoBold", size: 112))
                .foregroundColor(Color.white)
            Text("You need an unique and memorable display name so other people can identify you when using the app")
                .font(Font.custom("LatoRegular", size: 27))
                .foregroundColor(Color.white)
           
            TextField("Type here", text:$userInput)
                .padding(.top, 24)
                .foregroundColor(/*@START_MENU_TOKEN@*/.white/*@END_MENU_TOKEN@*/)
                .font(Font.custom("KarlaRegular", size: 22))
            Divider()
                .background(/*@START_MENU_TOKEN@*//*@PLACEHOLDER=View@*/Color.white/*@END_MENU_TOKEN@*/)
            Text("Make sure it is at least 6 characters long and add some numbers for good measure")
                .font(Font.custom("KarlaRegular", size: 14))
                .foregroundColor(Color(hue: 1.0, saturation: 0.0, brightness: 0.96))
            HStack(alignment: .center) {
                    Spacer()
                if(!userInput.isEmpty && userInput.count > 6 && userInput.count < 16) {
                        Button("Continue") {
                            setUser(displayName: userInput)
                        }
                          .accentColor(/*@START_MENU_TOKEN@*/.white/*@END_MENU_TOKEN@*/)
                          .fontWeight(/*@START_MENU_TOKEN@*/.regular/*@END_MENU_TOKEN@*/)
                          .font(Font.custom("KarlaBold", size: 24))
                    
                        Image(systemName: "arrow.right")
                            .foregroundColor(/*@START_MENU_TOKEN@*/.white/*@END_MENU_TOKEN@*/)
                    }
                }
            .transition(.opacity)
            .animation(.easeIn, value: (userInput.count > 6 && userInput.count < 16))

            Spacer()
        }
        .padding(.horizontal)
        .background(/*@START_MENU_TOKEN@*//*@PLACEHOLDER=View@*/Color.blue/*@END_MENU_TOKEN@*/)
    }
    
    private func setUser(displayName: String){
        userSettings.setUserData(displayName: userInput)
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
    }
}
