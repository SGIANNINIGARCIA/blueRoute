//
//  UserSettings.swift
//  blueRoute
//
//  Created by Sandro Giannini on 3/28/23.
//

import Foundation

class UserSettings: ObservableObject {
    
    @Published var displayName: String?;
    @Published var id: String?;
    @Published var needsOnboarding: Bool = true;
    
    init() {
        self.id = UserDefaults.standard.object(forKey: "id") as? String ?? nil
        self.displayName = UserDefaults.standard.object(forKey: "displayName") as? String ?? nil
        
        if displayName != nil {
            self.needsOnboarding = false;
        }
    }
    
    func setUserData(displayName: String) {
        self.displayName = displayName;
        self.id = UUID().uuidString
        
        UserDefaults.standard.set(self.displayName, forKey: "displayName")
        UserDefaults.standard.set(self.id, forKey: "id")
        
        self.needsOnboarding = false;
    }
    
    func getFullName() -> String? {
        
        guard self.displayName != nil, self.id != nil else {
            return nil;
        }
        
        return self.displayName! + BluetoothConstants.NameIdentifierSeparator + self.id!
    }
}
