//
//  AdjacencyExchange.swift
//  blueRoute
//
//  Created by Sandro Giannini on 3/4/23.
//

import Foundation
import CoreBluetooth

/// Based  on testing we can exchange up to 524 bytes, leaving 200 bytes to hold metadata info like sender
/// package number and totalamountofpackages
let MAX_MTU = 150;

extension BluetoothController {
    
    /// Receives the data sent by one of our neighbors through the AdjacencyExchange characteristic
    /// and process the data according to the type wrapped by the AdjacencyExchangeMessageWrapper
    func processAdjacencyExchangeMessage(_ data: Data, from ref: CBPeer) {
        
        let receivedData = String(decoding: data, as: UTF8.self)
        
        /// update last connection for sender
        updateLastConnectionAndInvalidateTimer(for: ref)
        
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
           // print("receive an exchange request")
            processIncomingAdjacencyExchangeRequest(from: sender, data: decodedMessageWrapper.messagePayload)
            
        case .exchangePackage:
            //print("receive a package")
            processReceivedPackage(from: sender, data: decodedMessageWrapper.messagePayload)
            
        case .packageAcknowledgement:
            //print("receive an acknowledgment")
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
        
        /// if we already have an exchange in process with this requestor, then disregard.
        /// it can happen when we already connected with the requestor's peripheral during discovery and
        /// initiated an exchange but the requestor entered discovery as well and
        /// is trying to connect with us through the peripheral while the exchange is still ongoing
        /// which if left to continue, can cause an array out bounds error
        let exchangeInProcess = self.pendingAdjacencyExchangesSent.contains(where: {$0.key == requestor})
        if exchangeInProcess {return;}
        
        /// if we have updated our Adjacency List after our last exchange with the requestor
        /// and the requestor did not trigger our last update, then we initiate the exchange
        /// otherwise an exchange is not warrated and we can dismiss the request with no need for acknowledgement
        guard let timeOfLastUpdate  = self.adjList.timeOfLastUpdate, let lastUpdateTriggeredBy = self.adjList.lastUpdateTriggeredBy, let timeOfLastExchange = request.lastUpdateReceived else {
            return initiateAdjacencyExchange(with: requestor);
        }
        
        if(timeOfLastUpdate > timeOfLastExchange && lastUpdateTriggeredBy != requestor.id) {
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
        /// if else executes, remove the vertex from pending list
        /// this is caused by error when trying to access out of bound index in the dataSegments 
        guard let nextSegment: Data = pendingExchangeData.retrieveNextSegment() else {
            self.pendingAdjacencyExchangesSent.removeValue(forKey: vertex)
            return
        }
        
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
            
        } else {
            print("failed to send data package number: \(packageToSend.currentPackageNumber) to \(vertex.displayName)")
        }
    }
    
    
    /// Method to send acknowledgment when we succesfully received a AdjacencyExchangePackage from a neighbor
    /// so they can send the next package, if any
    func sendPackageAcknowledgment(packagedReceived: Int, to vertex: Vertex){
        
        /// create acknowledgment
        let acknowledgement = AdjacencyPackageAcknowledgement(receivedPackageNumber: packagedReceived)
        
        /// encode acknowledgment
        guard let messageData = AdjacencyPackageAcknowledgement.encoder(message: acknowledgement) else {
            print("could not enconde message")
            return;
        }
        
        /// wrap acknowledgment
        guard let wrappedMessageData = prepareMessageWrapper(payload: messageData, type: .packageAcknowledgement) else {
            return;
        }
        
        /// Send the wrapped acknowledgment through the AdjacencyExchange characteristic
       _ = sendData(send: wrappedMessageData, to: vertex, characteristic: BluetoothConstants.adjExchangeCharacteristicID)
    }
    
    /// Method to process an acknowledgment sent by a vertex we are currently sending our adjacencyList to
    /// and begin sending the next package, if any.
    func processReceivedPackageAcknowledgment(from sender: Vertex, data: Data){
        
        let receivedData = String(decoding: data, as: UTF8.self)
        
        guard let acknowledgement = AdjacencyPackageAcknowledgement.decoder(message: receivedData) else {
            return print("unable to decode ack data")
        }
        
        /// If all packages have been sent, then we remove the PendingExchange from our list
        /// else, we send the next data segment
        
        guard let totalPackageCount = self.pendingAdjacencyExchangesSent[sender]?.dataSegments.count else {
            return;
        }
        
        
        if (acknowledgement.receivedPackageNumber == totalPackageCount) {
            self.pendingAdjacencyExchangesSent.removeValue(forKey: sender)
        } else {
            sendDataSegment(to: sender)
        }
    }
    
    /// Method to send an Adjacency Exchange request if certain amount of time has passed since the last exchange happen
    func sendAdjacencyRequest(to vertex: Vertex) {
        
        let request = AdjacencyExchangeRequest(lastUpdateReceived: vertex.lastExchangeDate)
        
        guard let encodedRequest = AdjacencyExchangeRequest.encoder(message: request) else {
            return print("unable to encode the request")
        }
        
        guard let wrappedRequest = prepareMessageWrapper(payload: encodedRequest, type: .exchangeRequest) else {
            return print("unable to wrap the request")
        }
        
       _ = sendData(send: wrappedRequest, to: vertex, characteristic: BluetoothConstants.adjExchangeCharacteristicID)
        
        /// update the time of our last exchange date with this vertex
        vertex.updateLastExchangeDate()
    }
    
    /// process a received AdjacencyExchangePackage
    func processReceivedPackage(from sender: Vertex, data: Data){
        
        let receivedData = String(decoding: data, as: UTF8.self)
        
        guard let packageData = AdjacencyExchangePackage.decoder(message: receivedData) else {
            print("unable to decode adjlist exchange request")
            return;
        }
        
        /// Check if there is already an ongoing exchange
        if(self.pendingAdjacencyExchangesReceived.contains(where: {$0.key == sender})) {
            
            /// update it with the data we received
            self.pendingAdjacencyExchangesReceived[sender]?.update(packageData)
            
            /// send an acknowledgement back
            sendPackageAcknowledgment(packagedReceived: packageData.currentPackageNumber, to: sender)
            
            /// rebuild the exchanged adjacencyList if we received all packages and remove PendingExchange
            if(packageData.packageTotalCount == self.pendingAdjacencyExchangesReceived[sender]?.segmentsProcessed) {
                
                guard let rebuiltList = rebuildSegmentedAdjacencyList(self.pendingAdjacencyExchangesReceived[sender]!.dataSegments, from: sender) else {
                    return;
                }
                
                self.adjList.processReceivedExchangedList(from: sender, compressedAdjList: rebuiltList)
                self.pendingAdjacencyExchangesReceived.removeValue(forKey: sender)
            }
            
        } else {
            /// create a new Pending Exchange if there isn't
            let inProcessExchange = PendingExchange(dataSegments: [packageData.payload])
            self.pendingAdjacencyExchangesReceived[sender] = inProcessExchange;
            
            /// send an acknowledgement back
            sendPackageAcknowledgment(packagedReceived: packageData.currentPackageNumber, to: sender)
            
            /// rebuild the exchanged adjacencyList if we received all packages and remove PendingExchange
            if(packageData.packageTotalCount == self.pendingAdjacencyExchangesReceived[sender]?.segmentsProcessed) {
                guard let rebuiltList = rebuildSegmentedAdjacencyList(self.pendingAdjacencyExchangesReceived[sender]!.dataSegments, from: sender) else {
                    return;
                }
                
                self.adjList.processReceivedExchangedList(from: sender, compressedAdjList: rebuiltList)
                self.pendingAdjacencyExchangesReceived.removeValue(forKey: sender)
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
        
        guard let messageData = AdjacencyExchangeMessageWrapper.encoder(message: codedMessage) else {
            print("could not enconde message")
            return nil;
        }
        
        return messageData
    }
    
    /// returns the rebuilt CompressedAdjacencyExchange passed in the form of data segments
    func rebuildSegmentedAdjacencyList(_ segments: [Data], from vertex: Vertex) -> CompressedAdjacencyList? {
        
        print("rebuilding list")
        
        var rebuiltData = Data();
        
        for segment in segments {
            rebuiltData.append(segment)
        }
        
        let processedRebuiltData = String(decoding: rebuiltData, as: UTF8.self)
        
        
        guard let decodedCompressedAdjList: CompressedAdjacencyList = CompressedAdjacencyList.decoder(message: processedRebuiltData) else {
            print("unable to decode compressed list")
            return nil;
        }
        
        return decodedCompressedAdjList;
    }
    
    
    /// Timer related methods for Adjacency Exchange
    
    @objc func checkForDueOrExpiredExchanges() {
        checkForDueExchanges();
        cleanUpPendingExchanges();
    }
    
    // Check if its time to send an exchange request
    private func checkForDueExchanges() {
        let neighbors = self.adjList.getNeighbors()
        
        for (neighbor) in neighbors {
            guard let lastExchange = neighbor.lastExchangeDate else {
                return sendAdjacencyRequest(to: neighbor)
              
            }
            
            /// check if there is an existing exchange
            let existingExchange = self.pendingAdjacencyExchangesReceived.contains(where: {$0.key == neighbor})
            
            /// if there is no ongoing exchange and time after last exchange exeeds interval, send request
            if((Date.now.timeIntervalSince(lastExchange) > BluetoothConstants.LastExchangeInterval)
               && existingExchange == false) {
                sendAdjacencyRequest(to: neighbor)
           //     print("sent a exchange request to \(neighbor.displayName)")
            }
            
        }
    }
    
    private func cleanUpPendingExchanges() {
        
        for (pending) in self.pendingAdjacencyExchangesSent {
            
            /// get the last update info
            let timeOfLastUpdate = pending.value.timeOfLastPackage!
            
            if(Date.now.timeIntervalSince(timeOfLastUpdate) > 120) {
                self.pendingAdjacencyExchangesSent.removeValue(forKey: pending.key)
            }
        }
        
        for (pending) in self.pendingAdjacencyExchangesReceived {
            
            /// get the last update info
            let timeOfLastUpdate = pending.value.timeOfLastPackage!
            
            if(Date.now.timeIntervalSince(timeOfLastUpdate) > 120) {
                self.pendingAdjacencyExchangesReceived.removeValue(forKey: pending.key)
            }
        }
    }
}

