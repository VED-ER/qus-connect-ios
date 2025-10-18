//
//  Types.swift
//  qus-connect-ios
//
//  Created by Vedran Erak on 17. 10. 2025..
//

import CoreBluetooth

class BluetoothDeviceWrapper {
    let peripheral: CBPeripheral
    let sensorType: SensorType
    let RSSI: NSNumber
    
    init(peripheral: CBPeripheral, sensorType: SensorType = .unknown, RSSI: NSNumber){
        self.peripheral = peripheral
        self.sensorType = sensorType
        self.RSSI = RSSI
    }
}

class ConnectionStorage {
    let peripheral: CBPeripheral
    let sensorType: SensorType
    var isConnected: Bool
    var services: [CBService]
    var characteristics: [CBCharacteristic]
    var isAutoConnect: Bool
    
    init(peripheral: CBPeripheral, sensorType: SensorType, isConnected: Bool = false, characteristics: [CBCharacteristic] = [], services: [CBService] = [], isAutoConnect: Bool = false){
        self.peripheral = peripheral
        self.sensorType = sensorType
        self.isConnected = isConnected
        self.services = services
        self.characteristics = characteristics
        self.isAutoConnect = isAutoConnect
    }
}
