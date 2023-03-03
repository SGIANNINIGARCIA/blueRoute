# blueRoute

Working on a messaging app using a bluetooth mesh. 

## Currently working on
- [ ] Work on sending data bigger than the max packet size (for sharing adj matrices)
    - [ ] Rewrite everything to account for removal of matrix exchange from ping and handshake service
    - [ ] Create new service for adjMatrix exchange
    - [ ] Implement methods for sending data as multiple packages
- [ ] Implement Explore View and clearly show who is a direct connection and who requires routing

### Future:
- [ ] Manage undelivered Messages
    - [ ] Implement send message retry on reconnection
        - [ ] Save undelivered messages for later delivery
        - [ ] Reroute routed messages using different path?
    - [ ] Implement delivered message notification/flag (might just rely on continuos ping/heartbet)
        - [ ] Request received message receipt 
- [ ] Implement delivered message

### Done:
- [x] Rewrite addDevice to use Adjacency List
    - [x] Recognize when the device is a direct connection or a 2nd/3rd degree device based on reference to CBPeer 
- [x] Rewrite sendChatMessage to recognize if a message should be routed or sent directly based on BFS 
- [x] Implement a lastUpdated value in AdjecencyList we can compare to decide whether a value in our current adjacency list is the most up to date
- [x] Implement 3rd degree connections exchange (working on it)
    - [x] Rewrite updateList to account for 3rd degree connections
- [x] Implement Adjacency list exchange through handshake
- [x] Merge Vertex struct and device struct
- [x] Implement a pinging mechanism to determine if device is still in range
    - [x]  Create pinging route for peripheral and central
    - [x] Create method to remove device if no response to ping after x amount of time
    - [x] Update lastConnection of device when needed
    - [x] Add a pinging timer
- [x] (In BluetoothCentral)Respond to peripheral’s handshake with centrals information
- [x] (In BluetoothPeripheral) Process central’s response to handshake by adding it the device to the list of devices with a reference to the central
- [x] (In BluetoothManager) create functions to:
    - [x] Process data coming from peripheral/central (move all data processing to the manager)
    - [x] Decide whether to respond to peripheral or central, depending which one is available
    
### Known Issues:
- AdjList exchange currently exceeds MTU max byte size, generating an error when decoding the message
- ~If device B closes the app or the bluetooth connection restarts, device A will continue to message the device using old references to its peripheral/central, resulting in a undelivered message~
    
