//
//  EdgeShape.swift
//  blueRoute
//
//  Created by Sandro Giannini on 12/2/22.
//

import Foundation
import SwiftUI

struct EdgeShape: Shape {
    var start: CGPoint
    var end: CGPoint
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        path.move(to: start)
        path.addLine(to: end)
        
        return path
    }
}
