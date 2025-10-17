//
//  BLEManager.swift
//  qus-connect-ios
//
//  Created by Vedran Erak on 15. 10. 2025..
//

import Foundation
import CoreBluetooth
import Combine

class BLEManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    // MARK: - Published Properties
    @Published var scannedDevices = [BluetoothDeviceWrapper]()
    @Published var connectedDevices = [BluetoothDeviceWrapper]()
    @Published var isBluetoothOn = false
    @Published var isScanning = false
    
    private var scanTimer: Timer?
    
    private var centralManager: CBCentralManager!
    
    // MARK: - Initialization
    override init() {
        super.init()
        // Initialize the central manager
        // TODO: Check background queue option, check third options argument
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    // MARK: - Scanning and Connection
    func startScanning() {
        print("Scanning started")
        self.isScanning = true
        
        scanTimer?.invalidate()
        
        scanTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
            print("Scan timer finished.")
            self?.stopScanning()
        }
        
        let services: [CBUUID] = [SensorType.OBU.SERVICE_HRM_SERVICE_ID, SensorType.CORE.SERVICE_TEMPERATURE_SERVICE_ID, SensorType.CORE.ALTERNATIVE_TEMPERATURE_TEMP_ID]
        
        centralManager.scanForPeripherals(withServices: services, options: [
            CBCentralManagerScanOptionAllowDuplicatesKey: false,
            CBCentralManagerScanOptionSolicitedServiceUUIDsKey: services
        ])
    }
    
    func stopScanning() {
        print("Scanning stopped")
        self.isScanning = false
        scanTimer?.invalidate()
        centralManager.stopScan()
    }
    
    func connect(to device: BluetoothDeviceWrapper) {
        if let scannedDevice = scannedDevices.first(where: { $0.peripheral.identifier == device.peripheral.identifier}){
            print("Connecting to \(device.sensorType) \(device.peripheral.identifier.uuidString)")
            self.stopScanning()
            centralManager.connect(scannedDevice.peripheral, options: nil)
        }
    }
    
    func disconnectFromDevice(device: BluetoothDeviceWrapper) {
        if let connectedDevice = connectedDevices.first(where: { $0.peripheral.identifier == device.peripheral.identifier}){
            print("Disconnecting from \(device.peripheral.identifier.uuidString)")
            centralManager.cancelPeripheralConnection(connectedDevice.peripheral)
        }
    }
    
    // MARK: - CBCentralManagerDelegate Methods
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            isBluetoothOn = true
            print("Bluetooth available")
        } else {
            isBluetoothOn = false
            print("Bluetooth is not available.")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi: NSNumber) {
        guard !scannedDevices.contains(where: { $0.peripheral.identifier == peripheral.identifier }) else { return }
        print("Discovered \(peripheral.name ?? "Unnamed device")")
       
        let scannedDeviceSensorType = getSensorTypeFromDevice(for: peripheral, advertisementData: advertisementData)
        
        print("Discovered sensor type \(scannedDeviceSensorType)")
        
        self.scannedDevices.append(BluetoothDeviceWrapper(peripheral: peripheral, sensorType: scannedDeviceSensorType, RSSI: rssi))
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected to \(peripheral.identifier.uuidString)")
        
        peripheral.delegate = self
        
        let connectedDevice = scannedDevices.first(where: { $0.peripheral.identifier == peripheral.identifier })!
        
        connectedDevices.append(connectedDevice)
        
        peripheral.discoverServices([])
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Failed to connect to \(peripheral.name ?? "device"). Error: \(error?.localizedDescription ?? "No error info")")
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnected from \(peripheral.identifier.uuidString)")
        connectedDevices = connectedDevices.filter { $0.peripheral.identifier != peripheral.identifier }
    }
    
    // MARK: - CBPeripheralDelegate Methods
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services {
            print("Discovering characteristics for service: \(service.uuid.uuidString)")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics {
            print("Characteristic: \(characteristic)")
        }
    }
    
    //    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
    //
    //    }
}
