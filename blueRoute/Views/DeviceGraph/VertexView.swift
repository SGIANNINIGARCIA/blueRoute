//
//  VertexView.swift
//  blueRoute
//
//  Created by Sandro Giannini on 12/2/22.
//

import Foundation

import SwiftUI

struct VertexView: View {
    var radius: Double
    var color: Color
    var coordinate: CGPoint
    
    var body: some View {
        Text("S")
            .font(.system(size: 24))
            .fontWeight(.medium)
            .foregroundColor(Color.white)
            .frame(width: radius * 2, height: radius * 2, alignment: .center)
            .background(.blue)
            .clipShape(Circle())
            .offset(x: coordinate.x - radius, y: coordinate.y - radius)
        }
}
