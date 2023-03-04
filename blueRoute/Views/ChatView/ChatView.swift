//
//  ChatView.swift
//  blueRoute
//
//  Created by Sandro Giannini on 11/17/22.
//

import SwiftUI

class TextCountMgr: ObservableObject {
    @Published var counted = 0;
    @Published var text = "" {
        didSet {
            counted = text.count
        }
    }
    
    func reset() {
        text = "";
    }
}

struct TextInput: View {
    
    @Binding var text: String;
    @Binding var count: Int;
    
    var body: some View {
        HStack(alignment: .bottom) {
            TextField("Message...", text: $text, axis: .vertical)
                .lineLimit(1...5)
            Text("\($count.wrappedValue)")
        }.padding([.top, .leading], 8)
         .padding(.bottom, 8)
         .padding(.trailing, 6)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.blue, lineWidth: 2)
        )
    }
}

struct ChatView: View {
    
    // Username of the user this chat is with
    var id: UUID;
    var displayName: String;
    
    // variable to hold stored messages belonging to this chat
    @FetchRequest var messages: FetchedResults<Message>;
    
    // bluetooth controller for sending/receiving messages
    @EnvironmentObject var bluetoothController: BluetoothController;
    
    // message being typed
    @ObservedObject var textCountMgr = TextCountMgr()
    
    init(displayName: String, id: UUID) {
        self.id = id;
        self.displayName = displayName;
        self._messages = FetchRequest<Message>(entity: Message.entity(),
                                               sortDescriptors: [NSSortDescriptor(keyPath: \Message.timestamp, ascending: true)],
                                               predicate: NSPredicate(format: "chat.identifier == %@", id as CVarArg),
                                               animation: .default)
    }
    
    var body: some View {
            VStack {
                List {
                    ForEach(messages) { message in
                        MessageView(currentMessage: message.content!, displayName: (message.chat?.displayName)!, isSelf: message.senderIsSelf)
                            .listRowSeparator(.hidden)
                    }
                }.listStyle(PlainListStyle())
                VStack{
                    HStack {
                        TextInput(text: $textCountMgr.text, count: $textCountMgr.counted)
                        Button {
                            bluetoothController.sendChatMessage(send: $textCountMgr.text.wrappedValue, to: displayName + BluetoothConstants.NameIdentifierSeparator +    id.uuidString)
                            $textCountMgr.text.wrappedValue = ""
                        } label: {
                            if($textCountMgr.counted.wrappedValue > 0) {
                                Image(systemName: "arrow.up.circle.fill")
                                    .font(.system(size: 32, weight: .light))
                            } else {
                                Image(systemName: "arrow.up.circle")
                                    .font(.system(size: 32, weight: .light))
                            }
                        }.padding(.leading, 6)
                         .disabled($textCountMgr.counted.wrappedValue <= 0)
                    }
                }
                .padding([.leading, .bottom, .trailing])
            }.navigationBarTitle(Text(self.displayName), displayMode: .inline)
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        }
}

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView(displayName: "Testing Subject", id: UUID())
    }
}
