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
