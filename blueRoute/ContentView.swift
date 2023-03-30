//
//  ContentView.swift
//  blueRoute
//
//  Created by Sandro Giannini on 11/10/22.
//

import SwiftUI

struct ContentView: View {
    
    @EnvironmentObject var userSettings: UserSettings;
    
    var body: some View {
        NavigationView {
            /// only proceed to MainPage once the user finish onboarding
            if $userSettings.needsOnboarding.wrappedValue == false {
                MainPage()
            }
        }
        .sheet(isPresented: $userSettings.needsOnboarding) {
            OnboardingView()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
