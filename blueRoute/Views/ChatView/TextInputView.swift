//
//  TextInputView.swift
//  blueRoute
//
//  Created by Sandro Giannini on 3/4/23.
//

import SwiftUI

/// Max number of characters allowed per chat message
let MAX_MESSAGE_LENGHT = 250;

struct TextInputView: View {
    
    // bluetooth controller for sending/receiving messages
    @EnvironmentObject var bluetoothController: BluetoothController;
    
    // message being typed
    @ObservedObject var textInputManager = TextManager()
    
    // Username of the user this chat is with
    var id: UUID;
    var displayName: String;
    
    init(displayName: String, id: UUID) {
        self.id = id;
        self.displayName = displayName;
    }
    
    
    var body: some View {
        VStack{
            HStack {
                TextArea(text: $textInputManager.text, count: $textInputManager.counted)
                SubmitButton(textInput: $textInputManager.text, count: $textInputManager.counted, id: id, displayName: displayName, AdjacencyList: $bluetoothController.adjList)
            }
        }
        .padding([.leading, .bottom, .trailing])
    }
}

struct TextInputView_Previews: PreviewProvider {
    static var previews: some View {
        TextInputView(displayName: "Testing Subject", id: UUID())
    }
}

struct SubmitButton: View {
    
    // bluetooth controller for sending/receiving messages
    @EnvironmentObject var bluetoothController: BluetoothController;
    @Binding var AdjacencyList: AdjacencyList;
    
    @Binding var textInput: String;
    @Binding var count: Int;
    
    // Username of the user this chat is with
    var id: UUID;
    var displayName: String;
    
    init(textInput: Binding<String>, count: Binding<Int>, id: UUID, displayName: String, AdjacencyList: Binding<AdjacencyList>) {
        self._textInput = textInput
        self._count = count
        self.id = id
        self.displayName = displayName
        self._AdjacencyList = AdjacencyList;
    }
    var body: some View {
        Button {
            bluetoothController.sendChatMessage(send: $textInput.wrappedValue, to: displayName + BluetoothConstants.NameIdentifierSeparator +    id.uuidString)
            $textInput.wrappedValue = ""
        } label: {
            if($count.wrappedValue > 0 && $AdjacencyList.adjacencies.contains(where: {$0.id == id})) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32, weight: .light))
            } else {
                Image(systemName: "arrow.up.circle")
                    .font(.system(size: 32, weight: .light))
            }
        }.padding(.leading, 6)
            .disabled($count.wrappedValue <= 0 || $count.wrappedValue > MAX_MESSAGE_LENGHT || ($AdjacencyList.adjacencies.contains(where: {$0.id == id}) == false))
    }
}

struct TextArea: View {
    
    @Binding var text: String;
    @Binding var count: Int;
    
    var body: some View {
        HStack(alignment: .bottom) {
            TextField("Message...", text: $text, axis: .vertical)
                .lineLimit(1...5)
                .padding(.bottom, 8)
            Text("\(MAX_MESSAGE_LENGHT - $count.wrappedValue)")
                .font(.footnote)
                .foregroundColor(Color.gray)
                .padding(.bottom, 4)
        }.padding([.top, .leading], 8)
            .padding(.trailing, 6)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.blue, lineWidth: 2)
            )
    }
}

class TextManager: ObservableObject {
    @Published var counted = 0;
    @Published var text = "" {
        didSet {
            counted = text.count
            if text.count > MAX_MESSAGE_LENGHT {
                text = String(text.prefix(MAX_MESSAGE_LENGHT))
            }
        }
    }
    
    func reset() {
        text = "";
    }
}
