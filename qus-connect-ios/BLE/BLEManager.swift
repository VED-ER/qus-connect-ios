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
    @Published var scannedDevices = [BluetoothDeviceWrapper]()
    @Published var connectedDevices = [BluetoothDeviceWrapper]()
    @Published var isBluetoothOn = false
    @Published var isScanning = false
    @Published private(set) var stopwatchTime: Int = 0
    @Published var sessionId: UUID?
    
    @Published var latestTrackpoint: Trackpoint?
    @Published var hrAverage: Double = 0
    @Published var rrAverage: Double = 0
    @Published var coreTempAverage: Double = 0
    @Published var skinTempAverage: Double = 0
    
    @Published var hrChartData: [VitalChartData] = []
    @Published var rrChartData: [VitalChartData] = []
    @Published var skinTempChartData: [TempChartData] = []
    @Published var coreTempChartData: [TempChartData] = []
    
    private var hrTotal: Int = 0
    private var hrCount: Int = 0
    private var rrTotal: Int = 0
    private var rrCount: Int = 0
    private var coreTempTotal: Double = 0
    private var coreTempCount: Int = 0
    private var skinTempTotal: Double = 0
    private var skinTempCount: Int = 0
    
    private var trackpoints: [Trackpoint] = []
    
    let mqttManager = MQTTManager()
    
    private let stopwatch = Stopwatch()
    
    private let customQueue = DispatchQueue(label: "qus.connect.ios.ble.manager.queue")
    
    private let userId = UUID(uuidString: "6351ece5-c923-4591-8ce8-568b3d410636") // hardcoded for now
    
    private var scanTimer: Timer?
    private let scanTimeout: TimeInterval = 5.0
    
    private var centralManager: CBCentralManager!
    
    private var cancellables = Set<AnyCancellable>()
    
    private var obuTraceData: OBUTrace = OBUTrace()
    private var obuUUIDData: OBUPage_124?
    private var obuInfoData: OBUPage_127?
    
    lazy var bleStorage = BLEStorage(stateChange: { [weak self] devices in
        DispatchQueue.main.async {
            guard let self = self else { return }
            
            self.connectedDevices = devices.filter { $0.isConnected }
            print("ConnectionStorage statChange: updated connected devices: \(self.connectedDevices.count)")
            
            self.scannedDevices = devices
        }
    })
    
    override init() {
        super.init()
        stopwatch.$elapsedTime
            .assign(to: \.stopwatchTime, on: self)
            .store(in: &cancellables)
        
        // Initialize the central manager
        // TODO: Check background queue option, check third options argument
        self.centralManager = CBCentralManager(delegate: self, queue: customQueue, options: [
            CBCentralManagerOptionShowPowerAlertKey: true,
        ])
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
        
        customQueue.async {
            self.centralManager.scanForPeripherals(withServices: services, options: [
                CBCentralManagerScanOptionAllowDuplicatesKey: false,
                CBCentralManagerScanOptionSolicitedServiceUUIDsKey: services
            ])
        }
    }
    
    func stopScanning() {
        print("Scanning stopped")
        DispatchQueue.main.async {
            self.isScanning = false
        }
        scanTimer?.invalidate()
        customQueue.async {
            self.centralManager.stopScan()
        }
    }
    
    func connect(to device: BluetoothDeviceWrapper) {
        customQueue.async {
            if let scannedDevice = self.scannedDevices.first(where: { $0.peripheral.identifier == device.peripheral.identifier}){
                print("Connecting to \(device.sensorType) \(device.peripheral.identifier.uuidString)")
                self.stopScanning()
                self.centralManager.connect(scannedDevice.peripheral, options: nil)
            }
        }
    }
    
    func disconnectFromDevice(device: BluetoothDeviceWrapper) {
        customQueue.async {
            if let connectedDevice = self.connectedDevices.first(where: { $0.peripheral.identifier == device.peripheral.identifier}){
                print("Disconnecting from \(device.peripheral.identifier.uuidString)")
                self.centralManager.cancelPeripheralConnection(connectedDevice.peripheral)
            }
        }
    }
    
    // MARK: - CBCentralManagerDelegate Methods
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        let isBluetoothOn = central.state == .poweredOn
        
        if let userId = userId {
            customQueue.async {
                self.mqttManager.connect(
                    id: userId.uuidString,
                    username: userId.uuidString,
                    accessToken: "INVALID_FOR_TESTING",
                    port: 1883
                )
            }
        }
        
        DispatchQueue.main.async {
            self.isBluetoothOn = isBluetoothOn
            if isBluetoothOn {
                print("Bluetooth available")
            } else {
                print("Bluetooth is not available.")
            }
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
        clearSessionState()
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
        startDeviceNotifications(for: peripheral)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        //        print("IN", Date())
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
                    
                    let newTrackpoint = Trackpoint().updating(with: obuTraceData)
                    
                    print("newTrackpoint \(newTrackpoint)")
                    
                    if let sessionId = sessionId, let userId = userId {
                        mqttManager.publishTrackpoint(
                            trackpoint: newTrackpoint.toSupabaseTrackpoint(userId: userId.uuidString, sessionId: sessionId.uuidString)
                        )
                        
                        onNewTrackpointReceived(newTrackpoint)
//                        DispatchQueue.main.async {
//                            self.latestTrackpoint = newTrackpoint
//                        }
                    }
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
        customQueue.async {
            guard let bluetoothDeviceWrapper = self.bleStorage.getDevice(for: device) else { return }
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
    }
    
    func stopDeviceNotifications(for device: CBPeripheral) {
        customQueue.async {
            guard let bluetoothDeviceWrapper = self.bleStorage.getDevice(for: device) else { return }
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
    }
    
    func writeCharacteristic(for device: BluetoothDeviceWrapper, serviceUUID: CBUUID, characteristicUUID: CBUUID, value: Data, writeType: CBCharacteristicWriteType ) {
        customQueue.async {
            guard let characteristic = device.peripheral.services?.first(where: { $0.uuid == serviceUUID })?.characteristics?.first(where: { $0.uuid == characteristicUUID }) else {
                print("Characteristic not found")
                return
            }
            
            device.peripheral.writeValue(value, for: characteristic, type: writeType)
        }
    }
    
    // MARK: session controls
    func startSession(deviceId: String) {
        print("startSession called")
        guard let device = connectedDevices.first(where: { $0.peripheral.identifier.uuidString == deviceId }) else {
            return
        }
        
        sessionId = UUID(uuidString: "0155d543-c74c-414f-8795-8b33a495734f")
        
        stopwatch.start()
        
        writeCharacteristic(
            for: device,
            serviceUUID: SensorType.OBU.SERVICE_NUS_SERVICE_ID,
            characteristicUUID: SensorType.OBU.SERVICE_NUS_RX_ID,
            value: OBUIntegrationService.getOBUCommand_125_Bytes(SensorType.OBU.COMMANDS125.SUFFIX_START_SESSION),
            writeType: .withoutResponse
        )
    }
    
    func startSessionWithoutGNSS(deviceId: String) {
        print("startSessionWithoutGNSS called")
        guard let device = connectedDevices.first(where: { $0.peripheral.identifier.uuidString == deviceId }) else {
            return
        }
        
        sessionId = UUID()
        
        stopwatch.start()
        
        writeCharacteristic(
            for: device,
            serviceUUID: SensorType.OBU.SERVICE_NUS_SERVICE_ID,
            characteristicUUID: SensorType.OBU.SERVICE_NUS_RX_ID,
            value: OBUIntegrationService.getOBUCommand_125_Bytes(SensorType.OBU.COMMANDS125.SUFFIX_START_SESSION_GNSS_DISABLED),
            writeType: .withoutResponse
        )
    }
    
    func stopSession(deviceId: String) {
        print("stopSession called")
        guard let device = connectedDevices.first(where: { $0.peripheral.identifier.uuidString == deviceId }) else {
            return
        }
        
        sessionId = nil
        
        stopwatch.stop()
        
        clearSessionState()
        
        writeCharacteristic(
            for: device,
            serviceUUID: SensorType.OBU.SERVICE_NUS_SERVICE_ID,
            characteristicUUID: SensorType.OBU.SERVICE_NUS_RX_ID,
            value: OBUIntegrationService.getOBUCommand_125_Bytes(SensorType.OBU.COMMANDS125.SUFFIX_STOP_SESSION),
            writeType: .withoutResponse
        )
    }
    
    func pauseSession(deviceId: String) {
        print("pauseSession called")
        guard let device = connectedDevices.first(where: { $0.peripheral.identifier.uuidString == deviceId }) else {
            return
        }
        
        stopwatch.pause()
        
        writeCharacteristic(
            for: device,
            serviceUUID: SensorType.OBU.SERVICE_NUS_SERVICE_ID,
            characteristicUUID: SensorType.OBU.SERVICE_NUS_RX_ID,
            value: OBUIntegrationService.getOBUCommand_125_Bytes(SensorType.OBU.COMMANDS125.SUFFIX_PAUSE_SESSION),
            writeType: .withoutResponse
        )
    }
    
    func resumeSession(deviceId: String) {
        print("resumeSession called")
        guard let device = connectedDevices.first(where: { $0.peripheral.identifier.uuidString == deviceId }) else {
            return
        }
        
        stopwatch.resume()
        
        writeCharacteristic(
            for: device,
            serviceUUID: SensorType.OBU.SERVICE_NUS_SERVICE_ID,
            characteristicUUID: SensorType.OBU.SERVICE_NUS_RX_ID,
            value: OBUIntegrationService.getOBUCommand_125_Bytes(SensorType.OBU.COMMANDS125.SUFFIX_RESUME_SESSION),
            writeType: .withoutResponse
        )
    }
    
    private func onNewTrackpointReceived(_ trackpoint: Trackpoint) {
        var newTrackpoint = trackpoint
        newTrackpoint.timestamp = Date()
        
        trackpoints.append(newTrackpoint)
        
        // Update all published properties
        DispatchQueue.main.async {
            self.latestTrackpoint = newTrackpoint
            self.updateAverages(with: newTrackpoint)
            self.updateChartData(with: newTrackpoint)
        }
    }
    
    private func updateAverages(with tp: Trackpoint) {
        if let hrVal = tp.hrVal {
            hrTotal += hrVal
            hrCount += 1
            hrAverage = Double(hrTotal) / Double(hrCount)
        }
        if let rrVal = tp.rrVal {
            rrTotal += rrVal
            rrCount += 1
            rrAverage = Double(rrTotal) / Double(rrCount)
        }
        if let coreTemp = tp.tempCore {
            coreTempTotal += coreTemp
            coreTempCount += 1
            coreTempAverage = coreTempTotal / Double(coreTempCount)
        }
        if let skinTemp = tp.tempSkin {
            skinTempTotal += skinTemp
            skinTempCount += 1
            skinTempAverage = skinTempTotal / Double(skinTempCount)
        }
    }
    
    private func updateChartData(with tp: Trackpoint) {
        guard let timestamp = tp.timestamp else { return }
        
        if let hrVal = tp.hrVal {
            hrChartData.append(VitalChartData(type: "Heart rate", value: hrVal, timestamp: timestamp))
        }
        if let rrVal = tp.rrVal {
            rrChartData.append(VitalChartData(type: "Respiratory rate", value: rrVal, timestamp: timestamp))
        }
        if let coreTemp = tp.tempCore {
            coreTempChartData.append(TempChartData(type: "Core temperature", value: coreTemp, timestamp: timestamp))
        }
        if let skinTemp = tp.tempSkin {
            skinTempChartData.append(TempChartData(type: "Skin temperature", value: skinTemp, timestamp: timestamp))
        }
        
        // keep only the last 1000 points
        // if hrChartData.count > 1000 { hrChartData.removeFirst() }
    }
    
    private func clearSessionState() {
        DispatchQueue.main.async {
            self.trackpoints.removeAll()
            self.latestTrackpoint = nil
            
            self.hrAverage = 0
            self.rrAverage = 0
            self.coreTempAverage = 0
            self.skinTempAverage = 0
            
            self.hrTotal = 0
            self.hrCount = 0
            self.rrTotal = 0
            self.rrCount = 0
            self.coreTempTotal = 0
            self.coreTempCount = 0
            self.skinTempTotal = 0
            self.skinTempCount = 0
            
            self.hrChartData.removeAll()
            self.rrChartData.removeAll()
            self.skinTempChartData.removeAll()
            self.coreTempChartData.removeAll()
        }
    }
}
