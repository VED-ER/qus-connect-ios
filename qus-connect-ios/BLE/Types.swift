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
    var isConnected: Bool
    var services: [CBService]
    var serviceCharacteristics: [CBUUID : [CBCharacteristic]]
    var isAutoConnect: Bool
    
    init(peripheral: CBPeripheral, sensorType: SensorType, RSSI: NSNumber, isConnected: Bool = false, serviceCharacteristics: [CBUUID:[CBCharacteristic]] = [:], services: [CBService] = [], isAutoConnect: Bool = false){
        self.peripheral = peripheral
        self.sensorType = sensorType
        self.RSSI = RSSI
        self.isConnected = isConnected
        self.services = services
        self.serviceCharacteristics = serviceCharacteristics
        self.isAutoConnect = isAutoConnect
    }
}
