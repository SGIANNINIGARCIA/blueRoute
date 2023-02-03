//
//  ContentView.swift
//  blueRoute
//
//  Created by Sandro Giannini on 11/10/22.
//

import SwiftUI

struct ContentView: View {
    
    // Pull the name of the current user from Core Data
    // if it doesn't exist, then bring the onboarding page
    // if it exist, pass it to the mainpage
    @FetchRequest(sortDescriptors: [
        SortDescriptor(\.displayName)
    ],  predicate: NSPredicate(format: "isSelf == %@", NSNumber(true))) var user: FetchedResults<User>
    
    // Variable controlling if the onboarding page should pop-up
    // on Appear, check if the query returned empty. if it did,
    // change the value of the variable to true
    @State var userIsOnboarded:Bool = false;
    
    var body: some View {
        NavigationView {
            MainPage(name: user[0].displayName ?? "unknown", identifier: user[0].identifier?.uuidString ?? "unknownIdentifier")            
        }
        .sheet(isPresented: $userIsOnboarded) {
            OnboardingView()
        }
        .onAppear{
            if (user.isEmpty) {
                userIsOnboarded = true
            }
        }
    }
        
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(
        )
    }
}
