//
//  AdjacencyExchange.swift
//  blueRoute
//
//  Created by Sandro Giannini on 3/4/23.
//

import Foundation

/// Based  on testing we can exchange up to 524 bytes, leaving 200 bytes to hold metadata info like sender
/// package number and totalamountofpackages
let MAX_MTU = 350;

extension BluetoothController {
    
    /// Receives the data sent by one of our neighbors through the AdjacencyExchange characteristic
    /// and process the data according to the type wrapped by the AdjacencyExchangeMessageWrapper
    func processAdjacencyExchangeMessage(_ data: Data) {
        
        let receivedData = String(decoding: data, as: UTF8.self)
        
        /// decode the wrapper
        guard let decodedMessageWrapper: AdjacencyExchangeMessageWrapper = AdjacencyExchangeMessageWrapper.decoder(message: receivedData) else {
            print("unable to decode message")
            return;
        }
        
        /// retrieve the vertex based on the sender
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
        }
    }
    
    /**
     * Methods for handling requests
     */
    
    /// Method to determine if an exchange requested by an user is warranted giving the info passed
    /// in AdjacencyExchangeRequest.
    func processIncomingAdjacencyExchangeRequest(from requestor: Vertex, data: Data){
        
        let receivedData = String(decoding: data, as: UTF8.self)
        
        /// decode the request
        guard let request = AdjacencyExchangeRequest.decoder(message: receivedData) else {
            print("unable to decode adjlist exchange request")
            return;
        }
        
        /// if nil, then we have never done an exchange with this user so we initiate the exchange
        guard let timeOfLastExchange = request.lastUpdateReceived else {
            return initiateAdjacencyExchange(with: requestor)
        }
        
        /// if we have updated our Adjacency List after our last exchange with the requestor
        /// and the requestor did not trigger our last update, then we initiate the exchange
        /// otherwise an exchange is not warrated and we can dismiss the request with no need for acknowledgement
        if(self.adjList.timeOfLastUpdate! > timeOfLastExchange && self.adjList.lastUpdateTriggeredBy != requestor.id) {
            initiateAdjacencyExchange(with: requestor)
        }
    }
    
    /// Method to initiate and adjacency exchange
    /// It creates a compressed version of our adjacency list, segments the data and
    /// calls sendDataSegment to send the first segment to the requestor
    func initiateAdjacencyExchange(with vertex: Vertex) {
        
        /// create a new PendingExchange with the segmented data of our Adjacency List
        guard let pendingExchange: PendingExchange = prepareAdjacencyListExchangeData() else {
            return print("unable to start exchange");
        }
        
        /// Add the PendingExchange to our list of pending exchanges
        self.pendingAdjacencyExchangesSent[vertex] = pendingExchange;
        
        /// send the first data segment
        sendDataSegment(to: vertex);
    }
    
    /// send the next segment of data to the vertex
    func sendDataSegment(to vertex: Vertex) {
        
        guard let pendingExchangeData:PendingExchange = self.pendingAdjacencyExchangesSent[vertex] else {
            return;
        }
        
        /// Retrieve the next segment
        let nextSegment: Data = pendingExchangeData.retrieveNextSegment();
        
        /// Create the ExchangePackage and encode it
        let packageToSend = AdjacencyExchangePackage(packageTotalCount: pendingExchangeData.dataSegments.count, currentPackageNumber: pendingExchangeData.segmentsProcessed, payload: nextSegment)
        
        guard let encodedPackage = AdjacencyExchangePackage.encoder(message: packageToSend) else {
            return print("unable to encode package")
        }
        
        /// wrapped the encoded package in the AdjacencyExchangeMessageWrapper
        guard let wrappedPackage = prepareMessageWrapper(payload: encodedPackage, type: .exchangePackage) else {
            return print("unable to wrap the package")
        }
        
        /// Send the data through the AdjacencyExchange characteristic
        let sentSuccesfully = sendData(send: wrappedPackage, to: vertex, characteristic: BluetoothConstants.adjExchangeCharacteristicID)
        
        /// if it sends, then add one to the processed chunks
        if(sentSuccesfully) {
            self.pendingAdjacencyExchangesSent[vertex]?.update();
            
        }
    }
    
    
    /// Method to send acknowledgment when we succesfully received a AdjacencyExchangePackage from a neighbor
    /// so they can send the next package, if any
    func sendPackageAcknowledgment(packagedReceived: Int, to vertex: Vertex){
        
        /// create acknowledgment
        let acknowledgement = AdjacencyPackageAcknowledgement(receivedPackageNumber: packagedReceived)
        
        /// encode acknowledgment
        guard var messageData = AdjacencyPackageAcknowledgement.encoder(message: acknowledgement) else {
            print("could not enconde message")
            return;
        }
        
        /// wrap acknowledgment
        guard var wrappedMessageData = prepareMessageWrapper(payload: messageData, type: .packageAcknowledgement) else {
            return;
        }
        
        /// Send the wrapped acknowledgment through the AdjacencyExchange characteristic
        sendData(send: wrappedMessageData, to: vertex, characteristic: BluetoothConstants.routingCharacteristicID)
    }
    
    /// Method to process an acknowledgment sent by a vertex we are currently sending our adjacencyList to
    /// and begin sending the next package, if any.
    func processReceivedPackageAcknowledgment(from sender: Vertex, data: Data){
        
        let receivedData = String(decoding: data, as: UTF8.self)
        
        guard var acknowledgement = AdjacencyPackageAcknowledgement.decoder(message: receivedData) else {
            return print("unable to decode ack data")
        }
        
        /// If all packages have been sent, then we remove the PendingExchange from our list
        /// else, we send the next data segment
        if (acknowledgement.receivedPackageNumber == self.pendingAdjacencyExchangesSent[sender]?.segmentsProcessed) {
            self.pendingAdjacencyExchangesSent.removeValue(forKey: sender)
        } else {
            sendDataSegment(to: sender)
        }
    }
    
    /// Method to send an Adjacency Exchange request if certain amount of time has passed since the last exchange happen
    func sendAdjacencyRequest(to vertex: Vertex){
        
        let request = AdjacencyExchangeRequest(lastUpdateReceived: vertex.lastExchangeDate)
        
        guard let encodedRequest = AdjacencyExchangeRequest.encoder(message: request) else {
            return print("unable to encode the request")
        }
        
        guard let wrappedRequest = prepareMessageWrapper(payload: encodedRequest, type: .exchangeRequest) else {
            return print("unable to wrap the request")
        }
        
        sendData(send: wrappedRequest, to: vertex, characteristic: BluetoothConstants.adjExchangeCharacteristicID)
        
        /// update the time our last exchange date
        vertex.updateLastExchangeDate()
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
            
            /// update it with the data we received
            self.pendingAdjacencyExchangesReceived[sender]?.update(packageData)
            
            /// rebuild the exchanged adjacencyList if we received all packages
            if(packageData.packageTotalCount == self.pendingAdjacencyExchangesReceived[sender]?.segmentsProcessed) {
                rebuildSegmentedAdjacencyList(self.pendingAdjacencyExchangesReceived[sender]!.dataSegments, from: sender)
            }
            
        } else {
            /// create a new Pending Exchange if there isn't
            let inProcessExchange = PendingExchange(dataSegments: [packageData.payload])
            self.pendingAdjacencyExchangesReceived[sender] = inProcessExchange;
            
            /// rebuild the exchanged adjacencyList if we received all packages
            if(packageData.packageTotalCount == self.pendingAdjacencyExchangesReceived[sender]?.segmentsProcessed) {
                rebuildSegmentedAdjacencyList(self.pendingAdjacencyExchangesReceived[sender]!.dataSegments, from: sender)
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
    
    @objc func cleanUpPendingExchanges() {
        
        for (pending) in self.pendingAdjacencyExchangesSent {
            
            /// get the last update info
            var timeOfLastUpdate = pending.value.timeOfLastPackage!
            
            if(Date.now.timeIntervalSince(timeOfLastUpdate) > 120) {
                self.pendingAdjacencyExchangesSent.removeValue(forKey: pending.key)
            }
        }
        
        for (pending) in self.pendingAdjacencyExchangesReceived {
            
            /// get the last update info
            var timeOfLastUpdate = pending.value.timeOfLastPackage!
            
            if(Date.now.timeIntervalSince(timeOfLastUpdate) > 120) {
                self.pendingAdjacencyExchangesReceived.removeValue(forKey: pending.key)
            }
        }
    }
    
    /// Returns a PendingExchange with the segmented data of our AdjacencyList
    func prepareAdjacencyListExchangeData() -> PendingExchange? {
        let adjList = self.adjList.processListForExchange();
        let codedMessage = CompressedAdjacencyList(sender: self.name!, adjacencyList: adjList)
        
        guard var messageData = CompressedAdjacencyList.encoder(message: codedMessage) else {
            print("could not enconde message")
            return nil;
        }
        
        var segments: [Data] = [];
        
        /*
         upperBound is the max amount of bytes we are gonna allow the
         data payload to be
         **/
        let dataRange = Range(0...MAX_MTU)
        
        while(messageData.count > dataRange.lowerBound) {
            if(messageData.count >= dataRange.upperBound) {
                let subData = messageData.subdata(in: dataRange)
                segments.insert(subData, at: segments.endIndex)
                messageData.removeSubrange(dataRange)
            } else {
                segments.insert(messageData, at: segments.endIndex)
                messageData.removeSubrange(dataRange.lowerBound..<messageData.count)
            }
        }
        
        return PendingExchange(dataSegments: segments)
    }
    
    
    
    /// Returns an encoded AdjacencyExchangeMessageWrapper with the end message as data in payload
    ///
    /// - Parameters:
    ///     - payload: the encoded message to send
    ///     - type: the type of data in payload
    func prepareMessageWrapper(payload: Data, type: ExchangeMessageType) -> Data? {
        
        let codedMessage = AdjacencyExchangeMessageWrapper(type: type, sender: self.name!, messagePayload: payload)
        
        guard var messageData = AdjacencyExchangeMessageWrapper.encoder(message: codedMessage) else {
            print("could not enconde message")
            return nil;
        }
        
        return messageData
    }
    
    func rebuildSegmentedAdjacencyList(_ segments: [Data], from vertex: Vertex){
        
        var rebuiltData = Data();
        
        for segment in segments {
            rebuiltData.append(segment)
        }
        
        let processedRebuiltData = String(decoding: rebuiltData, as: UTF8.self)
        
        
        guard let decodedCompressedAdjList: CompressedAdjacencyList = CompressedAdjacencyList.decoder(message: processedRebuiltData) else {
            print("unable to decode compressed list")
            return;
        }
    }
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
