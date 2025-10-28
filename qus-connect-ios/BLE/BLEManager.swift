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
    
    var obuTraceData: OBUTrace = OBUTrace()
    var obuUUIDData: OBUPage_124?
    var obuInfoData: OBUPage_127?
    
    @Published var trackpoint: Trackpoint = Trackpoint()
    
    lazy var bleStorage = BLEStorage(stateChange: { [weak self] devices in
        guard let self = self else { return }
        
        self.connectedDevices = devices.filter { $0.isConnected }
        print("ConnectionStorage statChange: updated connected devices: \(self.connectedDevices.count)")
        
        self.scannedDevices = devices
    })
    
    private var scanTimer: Timer?
    private let scanTimeout: TimeInterval = 5.0
    
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
        
        // reset scanned devices
        bleStorage.clearScannedDevices()
        
        scanTimer?.invalidate()
        
        scanTimer = Timer.scheduledTimer(withTimeInterval: scanTimeout, repeats: false) { [weak self] _ in
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
       
        let scannedDeviceSensorType = getSensorTypeFromScanResult(for: peripheral, advertisementData: advertisementData)
        
        print("Discovered sensor type \(scannedDeviceSensorType)")
        
        let scannedDeviceWrapper = BluetoothDeviceWrapper(peripheral: peripheral, sensorType: scannedDeviceSensorType, RSSI: rssi)
        bleStorage.addDevice(scannedDeviceWrapper)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected to \(peripheral.identifier.uuidString)")
        
        peripheral.delegate = self
        
        guard let connectedDeviceWrapper = scannedDevices.first(where: { $0.peripheral.identifier == peripheral.identifier }) else {
            print("Error: Connected peripheral not found in scanned devices list.")
            // Disconnect if this happens, unexpected state.
            central.cancelPeripheralConnection(peripheral)
            return
        }
        
        bleStorage.updateConnectedState(for: connectedDeviceWrapper.peripheral, isConnected: true)
        
        peripheral.discoverServices(nil)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Failed to connect to \(peripheral.name ?? "device"). Error: \(error?.localizedDescription ?? "No error info")")
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnected from \(peripheral.identifier.uuidString)")
        bleStorage.updateConnectedState(for: peripheral, isConnected: false)
    }
    
    // MARK: - CBPeripheralDelegate Methods
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        
        bleStorage.updateServices(services: services, for: peripheral)
        
        for service in services {
            print("Discovering characteristics for service: \(service.uuid.uuidString)")
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        print("Discovered characteristics for service: \(service.uuid.uuidString)")
        
        bleStorage.updateCharacteristics(service: service, characteristics: characteristics, for: peripheral)
        
        // enable notifications after discovering characteristics
//        startDeviceNotifications(for: peripheral)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let data = characteristic.value else { return }
        
        let receivedSensorType = bleStorage.getSensorType(for: peripheral)
        
        if (receivedSensorType == .obu) {
            switch characteristic.uuid {
            case SensorType.OBU.SERVICE_NUS_TX_ID:
                let page = OBUIntegrationService.txNotificationListener(from: data)
                
                switch page.pageId {
                case 1:
                    // Page 1 - Session Basics
                    obuTraceData = obuTraceData.updating(with: page as! OBUPage_1)
                case 2:
                    obuTraceData = obuTraceData.updating(with: page as! OBUPage_2)
                case 3:
                    obuTraceData = obuTraceData.updating(with: page as! OBUPage_3)
                case 24:
                    // Page 24 - GNSS Data
                    obuTraceData = obuTraceData.updating(with: page as! OBUPage_24)
                    
                    trackpoint = trackpoint.updating(with: obuTraceData)
                case 124:
                    obuUUIDData = page as! OBUPage_124
                case 127:
                    obuInfoData = page as! OBUPage_127
                default:
                    break
                }
            
            default:
                print("Should never be reached")
            }
        }
    }
    
    func startDeviceNotifications(for device: CBPeripheral) {
        guard let bluetoothDeviceWrapper = bleStorage.getDevice(for: device) else { return }
        let allCharacteristics = bluetoothDeviceWrapper.serviceCharacteristics.values.flatMap { $0 }
        
        switch bluetoothDeviceWrapper.sensorType {
        case .obu:
            guard let obuNusTxCharacteristic = allCharacteristics.first(where: { $0.uuid == SensorType.OBU.SERVICE_NUS_TX_ID }) else { return }
            print("Enabling notifications for OBU NUS TX characteristic")
            device.setNotifyValue(true, for: obuNusTxCharacteristic)
            
        case .core:
            guard let coreBodyTempNotificationCharacteristic = allCharacteristics.first(where: { $0.uuid == SensorType.CORE.SERVICE_TEMPERATURE_TEMP_ID }) else { return }
            print("Enabling notifications for CORE Body Temperature characteristic")
            device.setNotifyValue(true, for: coreBodyTempNotificationCharacteristic)
            
            guard let coreBodyControlPointCharacteristic = allCharacteristics.first(where: { $0.uuid == SensorType.CORE.SERVICE_TEMPERATURE_CONTROL_POINT_ID }) else { return }
            print("Enabling notifications for control point as it does not accept writes without notification enabled!!!")
            device.setNotifyValue(true, for: coreBodyControlPointCharacteristic)
            
        case .unknown:
            print("startDeviceNotifications: unknown sensor type")
        }
    }
    
    func stopDeviceNotifications(for device: CBPeripheral) {
        guard let bluetoothDeviceWrapper = bleStorage.getDevice(for: device) else { return }
        let allCharacteristics = bluetoothDeviceWrapper.serviceCharacteristics.values.flatMap { $0 }
        
        switch bluetoothDeviceWrapper.sensorType {
        case .obu:
            guard let obuNusTxCharacteristic = allCharacteristics.first(where: { $0.uuid == SensorType.OBU.SERVICE_NUS_TX_ID }) else { return }
            print("Disabling notifications for OBU NUS TX characteristic")
            device.setNotifyValue(false, for: obuNusTxCharacteristic)
            
        case .core:
            guard let coreBodyTempNotificationCharacteristic = allCharacteristics.first(where: { $0.uuid == SensorType.CORE.SERVICE_TEMPERATURE_TEMP_ID }) else { return }
            print("Disabling notifications for CORE Body Temperature characteristic")
            device.setNotifyValue(false, for: coreBodyTempNotificationCharacteristic)
            
            guard let coreBodyControlPointCharacteristic = allCharacteristics.first(where: { $0.uuid == SensorType.CORE.SERVICE_TEMPERATURE_CONTROL_POINT_ID }) else { return }
            print("Disabling notifications for control point as it does not accept writes without notification enabled!!!")
            device.setNotifyValue(false, for: coreBodyControlPointCharacteristic)
            
        case .unknown:
            print("stopDeviceNotifications: unknown sensor type")
        }
    }
    
    func writeCharacteristic(for device: BluetoothDeviceWrapper, serviceUUID: CBUUID, characteristicUUID: CBUUID, value: Data, writeType: CBCharacteristicWriteType ) {
        guard let characteristic = device.peripheral.services?.first(where: { $0.uuid == serviceUUID })?.characteristics?.first(where: { $0.uuid == characteristicUUID }) else {
            print("Characteristic not found")
            return
        }

        device.peripheral.writeValue(value, for: characteristic, type: writeType)
    }
}
