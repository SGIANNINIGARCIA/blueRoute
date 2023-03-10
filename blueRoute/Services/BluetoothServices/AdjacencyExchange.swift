//
//  AdjacencyExchange.swift
//  blueRoute
//
//  Created by Sandro Giannini on 3/4/23.
//

import Foundation

struct PendingExchange {
    var dataChunks: [Data];
    var chunksProcessed: Int;
    var timeOfLastPackage: Date?
    
    init(dataChunks: [Data]) {
        self.dataChunks = dataChunks
        self.chunksProcessed = 1;
        self.timeOfLastPackage = Date()
    }
    
    mutating func update(_ data: AdjacencyExchangePackage) {
        self.dataChunks.append(data.payload)
        self.chunksProcessed += 1;
        self.timeOfLastPackage = Date();
    }
}

/// Based  on testing we can exchange up to 524 bytes, leaving 200 bytes to hold metadata info like sender
/// package number and totalamountofpackages
let MAX_MTU = 350;

extension BluetoothController {
    
    ///  receive message from the characteristic and process accordingly
    func processAdjacencyExchangeMessage(_ data: Data) {
        
        let receivedData = String(decoding: data, as: UTF8.self)
        
        guard let decodedMessageWrapper: BTAdjacencyExchangeMessage = BTAdjacencyExchangeMessage.BTAdjacencyExchangeMessageDecoder(message: receivedData) else {
            print("unable to decode message")
            return;
        }
        
        guard let sender: Vertex = findVertex(name: decodedMessageWrapper.sender) else {
            print("unable to find a vertex for the sender")
            return;
        }
        
        switch(decodedMessageWrapper.type) {
        case .exchangeRequest:
            processIncomingAdjacencyExchangeRequest(from: sender, data: decodedMessageWrapper.messagePayload)
            
        case .exchangePackage:
            processReceivedPackage(from: sender, data: decodedMessageWrapper.messagePayload)
            
        case .packageAcknowledgement:
            processReceivedPackageAcknowledgment(from: sender)
            
        default:
            return;
            
        }
        
        
        
    }
    
    func prepareAdjacencyListExchangeData() -> PendingExchange? {
        let adjList = self.adjList.processForCompressedExchange();
        let codedMessage = BTAdjacencyList(sender: self.name!, adjacencyList: adjList)
        
        guard var messageData = BTAdjacencyList.BTAdjacencyListEncoder(message: codedMessage) else {
            print("could not enconde message")
            return nil;
        }
        
        var chunks: [Data] = [];
        
        /*
         upperBound is the max amount of bytes we are gonna allow the
         data payload to be
         **/
        let dataRange = Range(0...MAX_MTU)
        
        while(messageData.count > dataRange.lowerBound) {
            if(messageData.count >= dataRange.upperBound) {
                let subData = messageData.subdata(in: dataRange)
                chunks.insert(subData, at: chunks.endIndex)
                messageData.removeSubrange(dataRange)
            } else {
                chunks.insert(messageData, at: chunks.endIndex)
                messageData.removeSubrange(dataRange.lowerBound..<messageData.count)
            }
        }
        
        return PendingExchange(dataChunks: chunks)
    }
    
    func startAdjacencyExchange(with vertex: Vertex) {
        
        guard let pendingExchange = prepareAdjacencyListExchangeData() else {
            return print("unable to start exchange");
        }
        
        self.pendingAdjacencyExchangesSent[vertex] = pendingExchange;
        
        
        
        
        
        /// needs work
    }
    
    func sendDataChunk(for vertex: Vertex) {
        
        guard let pendingExchangeData = self.pendingAdjacencyExchangesSent[vertex] else {
            return;
        }
        
        var nextChunk = pendingExchangeData.dataChunks[pendingExchangeData.chunksProcessed - 1]
        
        var packageToSend = AdjacencyExchangePackage(packageTotalCount: pendingExchangeData.dataChunks.count, currentPackageNumber: pendingExchangeData.chunksProcessed - 1, payload: nextChunk)
        
        self.pendingAdjacencyExchangesSent[vertex]?.chunksProcessed =  self.pendingAdjacencyExchangesSent[vertex]!.chunksProcessed + 1;
        
    }
    
    
    /// send ack when receiving a AdjacencyExchangePackage
    func sendPackageAcknowledgment(packagedReceived: Int, to vertex: String){
        
        let acknowledgement = AdjacencyPackageAcknowledgement(receivedPackageNumber: packagedReceived)
        
        guard var messageData = AdjacencyPackageAcknowledgement.AdjacencyPackageAcknowledgementEncoder(message: acknowledgement) else {
            print("could not enconde message")
            return;
        }
        
        guard var wrappedMessageData = prepareMessageWrapper(payload: messageData, type: .packageAcknowledgement) else {
            return;
        }
        
        sendData(send: wrappedMessageData, to: vertex, characteristic: BluetoothConstants.routingCharacteristicID)
    }
    
    /// process an ack sent by a vertex we are currently sending our adjacencyList
    func processReceivedPackageAcknowledgment(from sender: Vertex){
        
        /// send the next package
        
        
    }
    
    /// process to determine if an exchange requested by a user is warranted
    func processIncomingAdjacencyExchangeRequest(from requestor: Vertex, data: Data){
        
        let receivedData = String(decoding: data, as: UTF8.self)
        
        guard let request = AdjacencyExchangeRequest.decoder(message: receivedData) else {
            print("unable to decode adjlist exchange request")
            return;
        }
        
        
        if(self.adjList.timeOfLastUpdate! > request.lastUpdateReceived && self.adjList.lastUpdateTriggeredBy != requestor.fullName) {
            startAdjacencyExchange(with: requestor)
        }
    }
    
    /// send a request if certain amount of time has passed
    func sendAdjacencyRequest(){}
    
    /// process a received AdjacencyExchangePackage
    func processReceivedPackage(from sender: Vertex, data: Data){
        
        let receivedData = String(decoding: data, as: UTF8.self)
        
        guard let packageData = AdjacencyExchangePackage.decoder(message: receivedData) else {
            print("unable to decode adjlist exchange request")
            return;
        }
        
        /// Check if there is already an ongoing exchange
        if(self.pendingAdjacencyExchangesReceived.contains(where: {$0.key == sender})) {
            /// update it with the new data if there is
            self.pendingAdjacencyExchangesReceived[sender]?.update(packageData)
            
            /// rebuild the exchanged adjacencyList if we received all packages
            if(packageData.packageTotalCount == self.pendingAdjacencyExchangesReceived[sender]?.chunksProcessed) {
                rebuildSegmentedAdjacencyList(self.pendingAdjacencyExchangesReceived[sender]!.dataChunks)
            }
            
        } else {
            /// create a new Pending Exchange if there isn't
            let inProcessExchange = PendingExchange(dataChunks: [packageData.payload])
            self.pendingAdjacencyExchangesReceived[sender] = inProcessExchange;
            
            /// rebuild the exchanged adjacencyList if we received all packages
            if(packageData.packageTotalCount == self.pendingAdjacencyExchangesReceived[sender]?.chunksProcessed) {
                rebuildSegmentedAdjacencyList(self.pendingAdjacencyExchangesReceived[sender]!.dataChunks)
            }
        }
        
        
    }
    
    
    
    
    
    
    
    
    /// wrapped the message with AdjacencyExchangeMessage
    func prepareMessageWrapper(payload: Data, type: ExchangeMessageType) -> Data? {
        
        let codedMessage = BTAdjacencyExchangeMessage(type: type, sender: self.name!, messagePayload: payload)
        
        guard var messageData = BTAdjacencyExchangeMessage.BTAdjacencyExchangeMessageEncoder(message: codedMessage) else {
            print("could not enconde message")
            return nil;
        }
        
        return messageData
    }
    
    func rebuildSegmentedAdjacencyList(_ segments: [Data]){}
    
    
}













struct TestStruct: Codable, Hashable {
    var one: String;
    //var two: Int;
    //var three: Int;
    //var four: Int;
    
    enum CodingKeys: String, CodingKey {
        case one
        // case two
        // case three
        //case four
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(one)
    }
    
    public static func tdecoder(message: String) -> TestStruct? {
        
        //2 - Convert the string to data
        let messageData = Data(message.utf8)
        
        //3 - Create a JSONDecoder instance
        let jsonDecoder = JSONDecoder()
        
        //4 - set the keyDecodingStrategy to convertFromSnakeCase on the jsonDecoder instance
        jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
        
        //5 - Use the jsonDecoder instance to decode the json into a Person object
        do {
            let decodedMessage = try jsonDecoder.decode(TestStruct.self, from: messageData)
            return decodedMessage;
        } catch {
            print("Error: \(error.localizedDescription)")
            return nil;
        }
        
    }
    
    public static func tencoder(message: TestStruct) -> Data? {
        
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = .prettyPrinted
        
        do {
            let encodeMessage = try jsonEncoder.encode(message)
            return encodeMessage;
        } catch {
            print(error.localizedDescription)
            return nil;
        }
        
    }
}
