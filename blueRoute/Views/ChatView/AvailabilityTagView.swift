//
//  AvailabilityTagView.swift
//  blueRoute
//
//  Created by Sandro Giannini on 12/3/22.
//

import SwiftUI

struct AvailabilityTagView: View {
    
    var isReachable: Bool;
    
    var body: some View {
        isReachable ?
        Circle()
            .fill(.blue)
            .frame(width: 10, height: 10) :
        Circle()
            .fill(.red)
            .frame(width: 10, height: 10)
    }
}

struct AvailabilityTagView_Previews: PreviewProvider {
    static var previews: some View {
        AvailabilityTagView(isReachable: true)
    }
}
