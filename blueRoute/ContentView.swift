//
//  ContentView.swift
//  blueRoute
//
//  Created by Sandro Giannini on 11/10/22.
//

import SwiftUI

struct ContentView: View {
    
    @FetchRequest(sortDescriptors: [
        SortDescriptor(\.displayName)
    ],  predicate: NSPredicate(format: "isSelf == %@", NSNumber(true))) var user: FetchedResults<User>
    
    @Environment(\.managedObjectContext) var managedObjContext;
    @EnvironmentObject var dataController: DataController;
    
    @State var userIsOnboarded:Bool = false;
    
    var body: some View {
        NavigationView {
           
            MainPage(name: (user[0].displayName ?? "unknown") + BluetoothConstants.NameIdentifierSeparator + (user[0].identifier?.uuidString ?? "UUID()"))
            /*
            Button("Continue") {
                dataController.delete(user: user[0], context: managedObjContext)
            }
              .accentColor(/*@START_MENU_TOKEN@*/.white/*@END_MENU_TOKEN@*/)
              .fontWeight(/*@START_MENU_TOKEN@*/.regular/*@END_MENU_TOKEN@*/)
              .font(Font.custom("KarlaBold", size: 24))
             */
            
        }
        .sheet(isPresented: $userIsOnboarded) {
            OnboardingView()
        }
        .onAppear{
            if user.isEmpty {userIsOnboarded = true}
        }
    }
        
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(
        )
    }
}
