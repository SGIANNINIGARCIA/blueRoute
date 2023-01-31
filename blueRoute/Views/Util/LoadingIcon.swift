//
//  LoadingIcon.swift
//  blueRoute
//
//  Created by Sandro Giannini on 11/19/22.
//

import SwiftUI

struct LoadingIcon: View {
    
    @State private var isLoading = false
 
    var body: some View {
        ZStack {
 
            Circle()
                .stroke(Color(.systemGray5), lineWidth: 7)
                .frame(width: 50, height: 50)
 
            Circle()
                .trim(from: 0, to: 0.2)
                .stroke(Color.blue, lineWidth: 3.5)
                .frame(width: 50, height: 50)
                .rotationEffect(Angle(degrees: isLoading ? 360 : 0))
                .animation(Animation.linear(duration: 1).repeatForever(autoreverses: false))
                .onAppear() {
                    self.isLoading = true
            }
        }
    }
}

struct LoadingIcon_Previews: PreviewProvider {
    static var previews: some View {
        LoadingIcon()
    }
}
