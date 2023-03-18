//
//  SwiftUIView.swift
//  blueRoute
//
//  Created by Sandro Giannini on 3/17/23.
//

import SwiftUI

struct DiscoveryAvatar: View {
    
    var name: String;
    
    var body: some View {
        HStack(alignment: .center, spacing: 32.0) {
            Avatar(username: name)
            Text(name)
                .fontWeight(.semibold)
        }
        .frame(width: .infinity)
        .padding(.leading, 12)
        .padding([.top, .bottom], 16)
    }
    
    /*
    var body: some View {
        VStack(alignment: .center, spacing: 16.0) {
            Avatar(username: name)
            Text(name)//.frame(width: 70)
                
        }
        .padding([.bottom, .trailing, .leading], 10)
        .padding(.top, 18)
        .background(
                    ZStack {
                        RoundedRectangle(
                            cornerRadius: 12,
                            style: .continuous
                        )
                        .fill(Color(UIColor(red: 240/255, green: 240/255, blue: 240/255, alpha: 1.0)))
                        RoundedRectangle(
                            cornerRadius: 12,
                            style: .continuous
                        )
                        .stroke(Color(UIColor(red: 240/255, green: 240/255, blue: 240/255, alpha: 1.0)), lineWidth: 2)
                    }
                    
                )
    }
     */
}

struct SwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        DiscoveryAvatar(name: "SantiagoMarriaga")
    }
}
