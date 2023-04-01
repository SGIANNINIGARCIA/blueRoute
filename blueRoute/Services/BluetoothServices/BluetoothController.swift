//
//  BluetoothController.swift
//  blueRoute
//
//  Created by Sandro Giannini on 11/22/22.
//

import Foundation
import CoreBluetooth
import CoreData

typealias Device = Vertex;

class BluetoothController: ObservableObject {
    
    /// Variables holding our bluetooth managers
    @Published var peripheral: BluetoothPeripheralManager?
    @Published var central: BluetoothCentralManager?
    @Published var adjList: AdjacencyList = AdjacencyList();
    
    //var managedObjContext: NSManagedObjectContext?;
    weak var dataController: DataController?;
    
    /// Full name (displayName + unique ID)
    var name: String?
    
    private var pingDevicesTimer: Timer?
    private var pingedDevices = [Device]();
    
    /// Members to hold the AdjList exchanges that have not been completed yet
    /// where the key is the vertex we are sending/receiving the AdjacencyList and PendingExchange is
    /// a struct holding the data to send/receive
    public var pendingAdjacencyExchangesSent: [Vertex: PendingExchange] = [:]
    public var pendingAdjacencyExchangesReceived: [Vertex: PendingExchange] = [:]
    
    /// timer to check for due exchanges and clean up expired ones
    private var exchangeTimer: Timer?
    
    
    init(dataController: DataController) {
        self.dataController = dataController;
    }
    
    public func setUp(name: String) -> Void {
        self.name = name;
        // instantiating the peripheral manager which wont start broadcasting immediately
        // but will wait until we provide an username
        self.peripheral = BluetoothPeripheralManager(name: name, bluetoothController: self )
        // instantiating the central manager which wont start discovering immediately
        // but will wait until we provide an username
        self.central = BluetoothCentralManager(name: name, bluetoothController: self)
        
        self.adjList.setSelf(name: name)
        
        self.pingDevicesTimer = Timer.scheduledTimer(timeInterval: 30,
                                         target: self,
                                         selector: #selector(checkDevicesLastConnection),
                                         userInfo: nil,
                                         repeats: true)
        
        
        self.exchangeTimer = Timer.scheduledTimer(timeInterval: 30,
                                                  target: self,
                                                  selector: #selector(checkForDueOrExpiredExchanges),
                                                  userInfo: nil,
                                                  repeats: true)
    }
    
    // send data to a characteristic and returns true if it succeded
    public func sendData(send data: Data, to name: String, characteristic: CBUUID) -> Bool {
            
        guard let vertex = findVertex(name: name) else {
            print("could not find \(name)")
            return false;
        }
        
        // send the message using the newest reference we saved for the device
        switch vertex.sendTo {
        case .peripheral:
           if let peripheral = vertex.peripheral {
               central!.sendData(data, peripheral: peripheral, characteristic: characteristic)
               return true;
           } else {
               fallthrough
           }
        case .central:
            if let central = vertex.central {
                peripheral!.sendData(data, central: central, characteristic: characteristic)
                return true;
            } else {
                fallthrough
            }
        default:
            print("unable to send message - could not find a reference to the device")
            return false;
        }
    }
    
    // send data to a characteristic and returns true if it succeded with a vertex
    public func sendData(send data: Data, to vertex: Vertex, characteristic: CBUUID) -> Bool {
        
        // send the message using the newest reference we saved for the device
        switch vertex.sendTo {
        case .peripheral:
           if let peripheral = vertex.peripheral {
               central!.sendData(data, peripheral: peripheral, characteristic: characteristic)
               return true;
           } else {
               fallthrough
           }
        case .central:
            if let central = vertex.central {
                peripheral!.sendData(data, central: central, characteristic: characteristic)
                return true;
            } else {
                fallthrough
            }
        default:
            print("unable to send message - could not find a reference to the device")
            return false;
        }
    }
    
    
     func saveMessage(message: BTMessage, isSelf: Bool, sendStatus: Bool) {
        dataController?.saveMessage(message: message, isSelf: isSelf, sendStatus: sendStatus)
    }
}

/*
 *  Methods to handle sending/receiving chat messages
 */




/*
 * Utility methods for device/user and ID/DisplayName look up
 */
extension BluetoothController {
      
    /// Returns the displayName in a fullName
    ///
    ///  - Parameters:
    ///     - name: string containing the fullName of a vertex
    ///
   public static func retrieveUsername(name: String) -> String {
       return name.components(separatedBy: BluetoothConstants.NameIdentifierSeparator)[0]
       
   }
   
    /// Returns the unique ID in a fullName
    ///
    ///  - Parameters:
    ///     - name: string containing the fullName of a vertex
    ///
   public static func retrieveID(name: String) -> UUID {
       guard let ID: UUID = UUID(uuidString: name.components(separatedBy: BluetoothConstants.NameIdentifierSeparator)[1]) else {
           return UUID()
       }
       
       return ID;
   }
    
    ///  Retrieves vertex from Adjacency List with matching name
    ///
    ///  - Parameters:
    ///     - name: the fullName of the vertex
    ///
    public func findVertex(name: String) -> Vertex? {
        let id = BluetoothController.retrieveID(name: name)
        
        guard let vertex = self.adjList.adjacencies.first(where: {$0.id == id}) else {
            return nil;
        }
        
        return vertex;
    }
    
    /// Retrieve the vertex with matching reference to central
    ///
    ///  - Parameters:
    ///     - central: reference of the central to match
    ///
    public func findVertex(central: CBCentral) -> Vertex? {
        guard let vertex = self.adjList.adjacencies.first(where: {$0.central?.identifier == central.identifier}) else {
            return nil;
        }
        
        return vertex;
    }
    
    /// Retrieve the vertex with matching reference to peripheral
    ///
    ///  - Parameters:
    ///     - peripheral: reference of the peripheral to match
    ///
    public func findVertex(peripheral: CBPeripheral) -> Vertex? {
        guard let vertex = self.adjList.adjacencies.first(where: {$0.peripheral?.identifier == peripheral.identifier}) else {
            return nil;
        }
        
        return vertex;
    }
   
   // Returns true if the device is reachable, else false.
   // Used for displaying the current availability of the user in the UI
   public func isReachable(_ toFind: UUID) -> Bool {
       
       let isReachable = self.adjList.adjacencies.contains(where: {$0.id == toFind})
       
       return isReachable;
   }
}

