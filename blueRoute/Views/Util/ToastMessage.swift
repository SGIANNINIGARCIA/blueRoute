//
//  ToastMessage.swift
//  blueRoute
//
//  Created by Sandro Giannini on 3/18/23.
//

import SwiftUI

struct ToastMessage: View {
    
    var action: () -> Void?;
    
    var body: some View {
        VStack() {
            HStack() {
                Spacer()
                Button {
                    action()
                } label: {
                    HStack {
                        Text("New Message")
                            .foregroundColor(Color.white)
                        Image(systemName: "arrow.down")
                            .foregroundColor(Color.white)
                            .font(.system(size: 18, weight: .light))
                    }
                }
                .padding(.top)
                .buttonStyle(GrowingButton())
                Spacer()
            }
            Spacer()
        }
    }
        
}

struct ToastMessage_Previews: PreviewProvider {
    static var previews: some View {
        ToastMessage(action: {})
    }
}



struct GrowingButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(.blue)
            .foregroundColor(.white)
            .clipShape(Capsule())
            .scaleEffect(configuration.isPressed ? 1.2 : 1)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}
