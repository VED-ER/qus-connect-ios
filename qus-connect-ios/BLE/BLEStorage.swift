//
//  BLEConnectionStorage.swift
//  qus-connect-ios
//
//  Created by Vedran Erak on 18. 10. 2025..
//

import CoreBluetooth

// Used to manage the state of ble devices while the app is running.
class BleStorage {
    private var connections: [UUID: ConnectionWrapper] = [:]
    private var stateChange: ([ConnectionWrapper]) -> Void
    
    init(stateChange: @escaping ([ConnectionWrapper]) -> Void) {
        self.stateChange = stateChange
    }
    
    func addConnection(_ connectionWrapper: ConnectionWrapper) {
        let identifier = connectionWrapper.peripheral.identifier
        
        if connections[identifier] == nil {
            print("Adding new connection to storage for peripheral: \(identifier)")
            connections[identifier] = connectionWrapper
            performStateChange()
        } else {
            print("Connection storage for peripheral \(identifier) already exists.")
        }
    }
    
    func getConnection(for device: CBPeripheral) -> ConnectionWrapper? {
        return connections[device.identifier]
    }
    
    func removeConnection(for device: CBPeripheral) {
        connections.removeValue(forKey: device.identifier)
        performStateChange()
    }
    
    func getAllConnections() -> [ConnectionWrapper] {
        return Array(connections.values)
    }
    
    func clearAllConnections() {
        connections.removeAll()
        stateChange([])
    }
    
    func getConnectionBySensorType(_ sensorType: SensorType) -> ConnectionWrapper? {
        return getAllConnections().first(where: { $0.sensorType == sensorType })
    }
    
    func updateConnectedState(for device: CBPeripheral, isConnected: Bool) {
        connections[device.identifier]?.isConnected = isConnected
        performStateChange()
    }
    
    func updateAutoConnectState(for device: CBPeripheral, isAutoConnect: Bool) {
        connections[device.identifier]?.isAutoConnect = isAutoConnect
        performStateChange()
    }
    
    func updateServices(services: [CBService], for device: CBPeripheral) {
        connections[device.identifier]?.services = services
        performStateChange()
    }
    
    func updateCharacteristics(characteristics: [CBCharacteristic], for device: CBPeripheral) {
        connections[device.identifier]?.characteristics = characteristics
        performStateChange()
    }
    
    func getSensorType(for device: CBPeripheral) -> SensorType {
        return connections[device.identifier]?.sensorType ?? .unknown
    }
    
    func performStateChange() {
        stateChange(getAllConnections())
    }
}
