//
//  DeviceGraphView.swift
//  blueRoute
//
//  Created by Sandro Giannini on 12/2/22.
//

import SwiftUI

struct DeviceGraphView: View {
    
    let maxWidth: CGFloat = UIScreen.main.bounds.size.width;
    let maxHeight: CGFloat = UIScreen.main.bounds.size.height;
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            Rectangle()
                .fill(.white)
            EdgeShape(
                start: CGPoint(x: maxWidth/2, y: maxHeight/4),
                end: CGPoint(x: maxWidth/3, y: maxHeight/2))
            .stroke(Color(red: -0.003, green: 0.478, blue: 0.999, opacity: 0.418), lineWidth: 3)
            
                   VertexView(
                       radius: 35,
                       color: .blue,
                       coordinate: CGPoint(x: maxWidth/2, y: maxHeight/4))
                   VertexView(
                       radius: 35,
                       color: .blue,
                       coordinate: CGPoint(x: maxWidth/3, y: maxHeight/2))
            
               }
    }
}

struct DeviceGraphView_Previews: PreviewProvider {
    static var previews: some View {
        DeviceGraphView()
    }
}
