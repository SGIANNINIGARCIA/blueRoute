//
//  ChatView.swift
//  blueRoute
//
//  Created by Sandro Giannini on 11/17/22.
//

import SwiftUI

struct ChatView: View {
    
    /// Namespace to use as reference to the bottom of the conversation, so
    /// we can programatically scroll to the bottom of the conversation on appear
    @Namespace var bottomID
    
    /// display name and ID of the user this chat is with
    var id: UUID;
    var displayName: String;
    
    @EnvironmentObject var dataController: DataController;
    
    /// variable to hold stored messages belonging to this chat
    @FetchRequest var messages: FetchedResults<Message>;
    
    /// toastMessage Controls
    @State var displayNewMessageBanner: Bool = false;
    
    init(displayName: String, id: UUID) {
        self.id = id
        self.displayName = displayName
        self._messages = FetchRequest<Message>(entity: Message.entity(),
                                               sortDescriptors: [NSSortDescriptor(keyPath: \Message.timestamp, ascending: true)],
                                               predicate: NSPredicate(format: "chat.identifier == %@", id as CVarArg),
                                               animation: .default)
    }
    
    var body: some View {
        VStack {
            ScrollViewReader { scrollViewProxy in
                ZStack {
                    ScrollView {
                        LazyVStack {
                            ForEach(messages) { message in
                                MessageView(message: message)
                                
                                /// Once the message appears on screen, mark it as seen
                                    .onAppear {
                                        self.dataController.updateMessageSeenStatus(message: message)
                                    }
                            }
                            
                            /// Text to identify the bottom of the message list
                            Text("").id(bottomID)
                        }
                        
                        /// Whenever there is a new message, trigger the toast message
                        .onChange(of: messages.endIndex) { newValue in
                            triggerToastMessage()
                        }
                        
                        .padding([.leading, .trailing], 8)
                        .padding([.top, .bottom], 16)
                    }
                    
                    /// Begin the view at the bottom of the conversation
                    .onAppear{
                        scrollViewProxy.scrollTo(bottomID)
                    }
                    
                    /// display ToastMessage as new message arrives
                    if displayNewMessageBanner {
                        NewMessageBanner(action: {
                            scrollViewProxy.scrollTo(bottomID)
                            displayNewMessageBanner = false;
                            }
                        )
                    }
                }
            }
            TextInputView(displayName: displayName, id: id)
        }
        .navigationBarTitle(Text(self.displayName), displayMode: .inline)
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
    
    func triggerToastMessage() {
        displayNewMessageBanner = true;
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.5) {
            displayNewMessageBanner = false;
        }
    }
}


struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView(displayName: "Testing Subject", id: UUID())
    }
}
