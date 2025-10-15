//
//  BLEManager.swift
//  qus-connect-ios
//
//  Created by Vedran Erak on 15. 10. 2025..
//

import Foundation
import CoreBluetooth
import Combine

struct Device: Identifiable {
    let id: UUID
    let name: String
    let peripheral: CBPeripheral
}

class BLEManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    // MARK: - Published Properties
    @Published var devices = [Device]()
    @Published var isBluetoothOn = false
    @Published var connectedDevice: CBPeripheral?

    // MARK: - Private Properties
    private var centralManager: CBCentralManager!

    // MARK: - Initialization
    override init() {
        super.init()
        // Initialize the central manager
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    // MARK: - Scanning and Connection
    func startScanning() {
        print("Scanning started")
        centralManager.scanForPeripherals(withServices: nil, options: nil)
    }

    func stopScanning() {
        print("Scanning stopped")
        centralManager.stopScan()
    }
    
    func connect(to device: Device) {
        print("Connecting to \(device.name)")
        centralManager.stopScan()
        centralManager.connect(device.peripheral, options: nil)
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
        guard let peripheralName = peripheral.name, !devices.contains(where: { $0.id == peripheral.identifier }) else { return }
        
        let newPeripheral = Device(id: peripheral.identifier, name: peripheralName, peripheral: peripheral)
        self.devices.append(newPeripheral)
        print("Discovered \(peripheralName)")
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected to \(peripheral.name ?? "device")")
        self.connectedDevice = peripheral
        peripheral.delegate = self
        // Discover services
        peripheral.discoverServices([])
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Failed to connect to \(peripheral.name ?? "device"). Error: \(error?.localizedDescription ?? "No error info")")
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
}
