//
//  test.swift
//  blueRoute
//
//  Created by Sandro Giannini on 2/11/23.
//

import SwiftUI
import WrappingHStack

struct test: View {
    
    var neighbors = ["SandroGiannini", "SantiagoMarriaga", "NataliaGiannini", "TamaraGiannini", "ArturoSaatdjian"]
    
    var reachable = ["ValeriaSaatdjian", "GianfrancoGiannini", "JoseManuel"]
    
    
    var body: some View {
        List {
            Section("Neighbors") {
                WrappingHStack(alignment: .leading) {
                    ForEach(neighbors, id: \.self) { user in
                        DiscoveryAvatar(name: user)
                        
                    }
                }
            }
            Section("Reachable") {
                WrappingHStack(alignment: .leading) {
                    ForEach(neighbors, id: \.self) { user in
                        DiscoveryAvatar(name: user)
                    }
                }
            }
        }
    }
}

struct test_Previews: PreviewProvider {
    static var previews: some View {
        test()
    }
}
