//
//  Avatar.swift
//  blueRoute
//
//  Created by Sandro Giannini on 11/16/22.
//

import SwiftUI

struct Avatar: View {
    
    @State var username:String;
    
    
    var body: some View {
        Text(GetFirstChar(username:username))
            .font(.system(size: 24))
            .fontWeight(.medium)
            .foregroundColor(Color.white)
            .background(Circle()
                    .fill(.blue)
                    .frame(width: 50, height: 50))
    }
    
    
    private func GetFirstChar(username:String) -> Substring {
        return username.prefix(1)
    }
}

struct Avatar_Previews: PreviewProvider {
    static var previews: some View {
        Avatar(username: "May")
    }
}
