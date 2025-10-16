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
    @Published var scannedDevices = [CBPeripheral]()
    @Published var isBluetoothOn = false
    @Published var connectedDevice: CBPeripheral?
    
    @Published var isScanning = false
    @Published var isConnecting = false
    
    // MARK: - Private Properties
    private var centralManager: CBCentralManager!
    
    // MARK: - Initialization
    override init() {
        super.init()
        // Initialize the central manager
        // TODO: Check initialization options
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    // MARK: - Scanning and Connection
    func startScanning() {
        print("Scanning started")
        self.isScanning = true
        
        let services: [CBUUID] = [SensorType.OBU.SERVICE_HRM_SERVICE_ID, SensorType.CORE.SERVICE_TEMPERATURE_SERVICE_ID, SensorType.CORE.ALTERNATIVE_TEMPERATURE_TEMP_ID]
        
        centralManager.scanForPeripherals(withServices: services, options: [
            CBCentralManagerScanOptionAllowDuplicatesKey: false,
            CBCentralManagerScanOptionSolicitedServiceUUIDsKey: services
        ])
    }
    
    func stopScanning() {
        print("Scanning stopped")
        self.isScanning = false
        centralManager.stopScan()
    }
    
    func connect(to device: CBPeripheral) {
        print("Connecting to \(device.name ?? device.identifier.uuidString)")
        self.isConnecting = true
        centralManager.stopScan()
        centralManager.connect(device, options: nil)
    }
    
    func disconnect() {
        guard let connectedDevice = connectedDevice else { return }
        print("Disconnecting from \(connectedDevice.name ?? "device")")
        centralManager.cancelPeripheralConnection(connectedDevice)
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
        guard !scannedDevices.contains(where: { $0.identifier == peripheral.identifier }) else { return }
        
        self.scannedDevices.append(peripheral)
        print("Discovered \(peripheral.name ?? "Unnamed device")")
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected to \(peripheral.name ?? "device")")
        self.isConnecting = false
        self.connectedDevice = peripheral
        peripheral.delegate = self
        // Discover services
        peripheral.discoverServices([])
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Failed to connect to \(peripheral.name ?? "device"). Error: \(error?.localizedDescription ?? "No error info")")
        self.isConnecting = false
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnected from \(peripheral.name ?? "device")")
        self.connectedDevice = nil
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
            print(characteristic)
        }
    }
    
    //    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
    //
    //    }
    
    func getPeripheralByMacAddress(_ macAddress: String) -> CBPeripheral? {
        return self.scannedDevices.first(where: { $0.identifier.uuidString == macAddress })
    }
}
