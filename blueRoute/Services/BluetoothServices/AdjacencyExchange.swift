//
//  AdjacencyExchange.swift
//  blueRoute
//
//  Created by Sandro Giannini on 3/4/23.
//

import Foundation

struct AdjExchangePackage: Codable, Hashable {
    var sender: String;
    var packageTotalCount: Int;
    var currentPackageNumber: Int;
    var payload: Data;
    
    enum CodingKeys: String, CodingKey {
        case sender
        case packageTotalCount
        case currentPackageNumber
        case payload
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(sender)
    }
    
    public static func AdjExchangePackageDecoder(message: String) -> AdjExchangePackage? {
        
        //2 - Convert the string to data
        let messageData = Data(message.utf8)

        //3 - Create a JSONDecoder instance
        let jsonDecoder = JSONDecoder()
        
        //4 - set the keyDecodingStrategy to convertFromSnakeCase on the jsonDecoder instance
        jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
        
        //5 - Use the jsonDecoder instance to decode the json into a Person object
        do {
            let decodedMessage = try jsonDecoder.decode(AdjExchangePackage.self, from: messageData)
            print("AdjacencyList Packahe sent by -- \(decodedMessage.sender)")
            return decodedMessage;
        } catch {
            print("Error: \(error.localizedDescription)")
            return nil;
        }
        
    }
    
    public static func AdjExchangePackageEncoder(message: BTAdjacencyListExchange) -> Data? {
                
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

struct PendingExchange {
    var dataChunks: [Data];
    var chunksSent: Int;
}

/// Based  on testing we can exchange up to 524 bytes, leaving 200 bytes to hold metadata info like sender
/// package number and totalamountofpackages
let MAX_MTU = 350;

extension BluetoothController {
    
    func prepareData() -> PendingExchange? {
        let adjList = self.adjList.processForCompressedExchange();
        let codedMessage = BTAdjacencyListExchange(sender: self.name!, adjacencyList: adjList)
        
        guard var messageData = BTAdjacencyListExchange.BTAdjacencyListExchangeEncoder(message: codedMessage) else {
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
        
        return PendingExchange(dataChunks: chunks, chunksSent: 0)
    }
    
    func startAdjacencyExchange(with vertex: Vertex) {
        
        guard let exchangePackage = prepareData() else {
            return print("unable to start exchange");
        }
        
        self.pendingAdjacencyExchangesSent[vertex] = exchangePackage;
    }
    
    func sendDataChunk(for vertex: Vertex) {
        
        guard let pendingExchangeData = self.pendingAdjacencyExchangesSent[vertex] else {
            return;
        }

        var nextChunk = pendingExchangeData.dataChunks[pendingExchangeData.chunksSent - 1]
        var packageToSend = AdjExchangePackage(sender: self.name!, packageTotalCount: pendingExchangeData.dataChunks.count, currentPackageNumber: pendingExchangeData.chunksSent - 1, payload: nextChunk)
        
        self.pendingAdjacencyExchangesSent[vertex]?.chunksSent =  self.pendingAdjacencyExchangesSent[vertex]!.chunksSent + 1;
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
