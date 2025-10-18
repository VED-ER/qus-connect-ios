//
//  BLEConnectionStorage.swift
//  qus-connect-ios
//
//  Created by Vedran Erak on 18. 10. 2025..
//

import CoreBluetooth

// Used to manage the state of ble devices while the app is running.
class BLEStorage {
    private var devices: [UUID: BluetoothDeviceWrapper] = [:] // holds both scanned and connected devices
    private var stateChange: ([BluetoothDeviceWrapper]) -> Void
    
    init(stateChange: @escaping ([BluetoothDeviceWrapper]) -> Void) {
        self.stateChange = stateChange
    }
    
    func addDevice(_ deviceWrapper: BluetoothDeviceWrapper) {
        let identifier = deviceWrapper.peripheral.identifier
        
        if devices[identifier] == nil {
            print("Adding new device to ble storage for peripheral: \(identifier)")
            devices[identifier] = deviceWrapper
            performStateChange()
        } else {
            print("Ble storage for peripheral \(identifier) already exists.")
        }
    }
    
    func getDevice(for device: CBPeripheral) -> BluetoothDeviceWrapper? {
        return devices[device.identifier]
    }
    
    func removeDevice(for device: CBPeripheral) {
        devices.removeValue(forKey: device.identifier)
        performStateChange()
    }
    
    func getAllDevices() -> [BluetoothDeviceWrapper] {
        return Array(devices.values)
    }
    
    func clearAllDevices() {
        devices.removeAll()
        stateChange([])
    }
    
    func getDeviceBySensorType(_ sensorType: SensorType) -> BluetoothDeviceWrapper? {
        return getAllDevices().first(where: { $0.sensorType == sensorType })
    }
    
    func updateConnectedState(for device: CBPeripheral, isConnected: Bool) {
        devices[device.identifier]?.isConnected = isConnected
        performStateChange()
    }
    
    func updateAutoConnectState(for device: CBPeripheral, isAutoConnect: Bool) {
        devices[device.identifier]?.isAutoConnect = isAutoConnect
        performStateChange()
    }
    
    func updateServices(services: [CBService], for device: CBPeripheral) {
        devices[device.identifier]?.services = services
        performStateChange()
    }
    
    func updateCharacteristics(service: CBService ,characteristics: [CBCharacteristic], for device: CBPeripheral) {
        if let deviceWrapper = devices[device.identifier] {
            deviceWrapper.serviceCharacteristics[service.uuid] = characteristics
            performStateChange()
        } else {
            print("Error: Could not find device with identifier \(device.identifier) to update.")
        }
    }
    
    func getSensorType(for device: CBPeripheral) -> SensorType {
        return devices[device.identifier]?.sensorType ?? .unknown
    }
    
    func clearScannedDevices() {
        devices = devices.filter { $0.value.isConnected }
        stateChange(Array(devices.values))
    }
    
    func performStateChange() {
        stateChange(getAllDevices())
    }
}
