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
            processReceivedPackageAcknowledgment(from: sender, data: decodedMessageWrapper.messagePayload)
            
        default:
            return;
            
        }
    }
    
    /**
     * Methods for handling requests
     */
    
    /// process to determine if an exchange requested by a user is warranted
    func processIncomingAdjacencyExchangeRequest(from requestor: Vertex, data: Data){
        
        let receivedData = String(decoding: data, as: UTF8.self)
        
        guard let request = AdjacencyExchangeRequest.decoder(message: receivedData) else {
            print("unable to decode adjlist exchange request")
            return;
        }
        
        /// if nil, then we have never done an exchange with this user
        guard let timeOfLastExchange = request.lastUpdateReceived else {
            return initiateAdjacencyExchange(with: requestor)
        }
        
        /// if the we have updated our Adjacency List after our last exchange with the requestor
        /// and the requestor did not trigger our last update, then we initiate the exchange
        if(self.adjList.timeOfLastUpdate! > timeOfLastExchange && self.adjList.lastUpdateTriggeredBy != requestor.fullName) {
            initiateAdjacencyExchange(with: requestor)
        }
    }
    
    /// create the compressed version of the list, segment the data and send
    func initiateAdjacencyExchange(with vertex: Vertex) {
        
        guard let pendingExchange: PendingExchange = prepareAdjacencyListExchangeData() else {
            return print("unable to start exchange");
        }
        
        self.pendingAdjacencyExchangesSent[vertex] = pendingExchange;
        vertex.lastExchangeDate = Date();
        
        /// send the first data segment
        sendDataChunk(for: vertex);
    }
    
    /// send the next segment of data to the vertex
    func sendDataChunk(for vertex: Vertex) {
        
        guard let pendingExchangeData:PendingExchange = self.pendingAdjacencyExchangesSent[vertex] else {
            return;
        }
        
        /// pull the next segment
        var nextSegment: Data = pendingExchangeData.dataChunks[pendingExchangeData.chunksProcessed - 1]
        
        /// create the ExchangePackage and encode it
        var packageToSend = AdjacencyExchangePackage(packageTotalCount: pendingExchangeData.dataChunks.count, currentPackageNumber: pendingExchangeData.chunksProcessed, payload: nextSegment)
        
        guard let encodedPackage = AdjacencyExchangePackage.encoder(message: packageToSend) else {
            return print("unable to encode package")
        }
        
        /// wrapped the encoded package in the  BTAdjacencyExchangeMessage
        guard let wrappedPackage = prepareMessageWrapper(payload: encodedPackage, type: .exchangePackage) else {
            return print("unable to wrap the package")
        }
        
        let sentSuccesfully = sendData(send: wrappedPackage, to: vertex, characteristic: BluetoothConstants.adjExchangeCharacteristicID)
        
        /// if it sends, then add one to the processed chunks
        if(sentSuccesfully) {
            self.pendingAdjacencyExchangesSent[vertex]?.chunksProcessed += 1;
            self.pendingAdjacencyExchangesSent[vertex]?.timeOfLastPackage = Date();
            
        }
    }
    
    
    /// send ack when receiving a AdjacencyExchangePackage
    func sendPackageAcknowledgment(packagedReceived: Int, to vertex: Vertex){
        
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
    func processReceivedPackageAcknowledgment(from sender: Vertex, data: Data){
        
        let receivedData = String(decoding: data, as: UTF8.self)
        
        guard var ackData = AdjacencyPackageAcknowledgement.AdjacencyPackageAcknowledgementDecoder(message: receivedData) else {
            return print("unable to decode ack data")
        }
        
        if (ackData.receivedPackageNumber == self.pendingAdjacencyExchangesSent[sender]?.chunksProcessed) {
            self.pendingAdjacencyExchangesSent.removeValue(forKey: sender)
        } else {
            sendDataChunk(for: sender)
        }
    }
    
    /// send a request if certain amount of time has passed
    func sendAdjacencyRequest(to vertex: Vertex){
        
        let request = AdjacencyExchangeRequest(lastUpdateReceived: vertex.lastExchangeDate)
        
        guard let encodedRequest = AdjacencyExchangeRequest.encoder(message: request) else {
            return print("unable to encode the request")
        }
        
        guard let wrappedRequest = prepareMessageWrapper(payload: encodedRequest, type: .exchangeRequest) else {
            return print("unable to wrap the request")
        }
        
        sendData(send: wrappedRequest, to: vertex, characteristic: BluetoothConstants.adjExchangeCharacteristicID)
        
        vertex.lastExchangeDate = Date();
    }
    
    /// process a received AdjacencyExchangePackage
    func processReceivedPackage(from sender: Vertex, data: Data){
        
        let receivedData = String(decoding: data, as: UTF8.self)
        
        guard let packageData = AdjacencyExchangePackage.decoder(message: receivedData) else {
            print("unable to decode adjlist exchange request")
            return;
        }
        
        /// send an acknowledgement back
        sendPackageAcknowledgment(packagedReceived: packageData.currentPackageNumber, to: sender)
        
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
    
    @objc func checkLastAdjacencyExchange() {
        
        let neighbors = self.adjList.getNeighbors()
        
        for (neighbor) in neighbors {
            // Check if its time to send an exchange request
            guard let lastExchange = neighbor.lastExchangeDate else {
                return sendAdjacencyRequest(to: neighbor)
                print("sent a exchange request to \(neighbor.displayName)")
            }
            
            if(Date.now.timeIntervalSince(lastExchange) > BluetoothConstants.LastExchangeInterval) {
                // Send an exchange request
                sendAdjacencyRequest(to: neighbor)
                print("sent a exchange request to \(neighbor.displayName)")
            }
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
