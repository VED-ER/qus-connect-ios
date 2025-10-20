//
//  SensorType.swift
//  qus-connect-ios
//
//  Created by Vedran Erak on 16. 10. 2025..
//

import CoreBluetooth

enum SensorType {
    case obu
    case core
    case unknown
    
    init?(fromString string: String) {
        switch string.uppercased() {
        case "OBU":
            self = .obu
        case "CORE":
            self = .core
        default:
            self = .unknown
        }
    }
    
    // Example usage:

    // --- Success Case ---
//    let obuString = "OBU"
//    if let sensorType = SensorType(fromString: obuString) {
//        print("Successfully created type: \(sensorType.name)") // Prints: "Successfully created type: OBU"
//        // Now you can use the 'sensorType' variable
//        // connect(to: myPeripheral, type: sensorType)
//    }
    
    static let CCC_DESCRIPTOR_UUID = CBUUID(string: "00002902-0000-1000-8000-00805F9B34FB") // Client Characteristic Configuration Descriptor

    enum OBU {
        static func toString() -> String {
            return "OBU"
        }
        
        // Nordic UART Service UUIDs
        static let SERVICE_NUS_SERVICE_ID = CBUUID(string:"6E400001-B5A3-F393-E0A9-E50E24DCCA9E") // Nordic UART Service UUID
        static let SERVICE_NUS_RX_ID = CBUUID(string:"6E400002-B5A3-F393-E0A9-E50E24DCCA9E") // RX Characteristic UUID
        static let SERVICE_NUS_TX_ID = CBUUID(string:"6E400003-B5A3-F393-E0A9-E50E24DCCA9E") // TX Characteristic UUID
        
        // HRM Service UUIDs
        static let SERVICE_HRM_SERVICE_ID = CBUUID(string:"0000180D-0000-1000-8000-00805F9B34FB") // Heart Rate Service UUID
        static let SERVICE_HRM_MEASUREMENT_ID = CBUUID(string:"00002A37-0000-1000-8000-00805F9B34FB") // Heart Rate Measurement Characteristic UUID
        //static let SERVICE_HRM_BODY_SENSOR_LOCATION_ID = CBUUID(string:"2A38") // Body Sensor Location Characteristic UUID
        //static let SERVICE_HRM_CONTROL_POINT_ID = CBUUID(string:"2A39") // Heart Rate Control Point Characteristic UUID

        // Device Information Service UUIDs
        static let SERVICE_DEVICE_INFO_SERVICE_ID = CBUUID(string:"0000180A-0000-1000-8000-00805F9B34FB") // Device Information Service UUID
        static let SERVICE_DEVICE_INFO_MANUFACTURER_ID = CBUUID(string:"00002A29-0000-1000-8000-00805F9B34FB") // Manufacturer Name Characteristic UUID
        static let SERVICE_DEVICE_INFO_MODEL_ID = CBUUID(string:"00002A24-0000-1000-8000-00805F9B34FB") // Model Number Characteristic UUID
        //static let SERVICE_DEVICE_INFO_SERIAL_ID = CBUUID(string:"00002A25-0000-1000-8000-00805F9B34FB") // Serial Number Characteristic UUID
        static let SERVICE_DEVICE_INFO_FIRMWARE_ID = CBUUID(string:"00002A26-0000-1000-8000-00805F9B34FB") // Firmware Revision Characteristic UUID
        static let SERVICE_DEVICE_INFO_HARDWARE_ID = CBUUID(string:"00002A27-0000-1000-8000-00805F9B34FB") // Hardware Revision Characteristic UUID

        // Battery Service UUIDs - non-existent for OBU, but included for completeness
        //static let SERVICE_BATTERY_SERVICE_ID = CBUUID(string:"0000180F-0000-1000-8000-00805F9B34FB") // Battery Service UUID
        //static let SERVICE_BATTERY_LEVEL_ID = CBUUID(string:"00002A19-0000-1000-8000-00805F9B34FB") // Battery Level Characteristic UUID
        //static let SERVICE_BATTERY_POWER_STATE_ID = CBUUID(string:"2A1A") // Battery Power State Characteristic UUID
        //static let SERVICE_BATTERY_LEVEL_STATE_ID = CBUUID(string:"2A1B") // Battery Level State Characteristic UUID

        enum COMMANDS125: UInt8 {
            case SUFFIX_START_SESSION = 0x01
            case SUFFIX_STOP_SESSION = 0x02
            case SUFFIX_PAUSE_SESSION = 0x03
            case SUFFIX_RESUME_SESSION = 0x04
            case SUFFIX_START_SESSION_GNSS_DISABLED = 0x05
            case SUFFIX_SET_TEAM_MODE = 0x06
            case SUFFIX_SET_INDIVIDUAL_MODE = 0x07
            case SUFFIX_SET_SLEEP_MODE = 0x08
        }
        
        enum COMMANDS120: UInt8 {
            case SUFFIX_MODE_RUNNING = 0x00
            case SUFFIX_MODE_CYCLING = 0x01
            case SUFFIX_MODE_SWIMMING = 0x02
            case SUFFIX_MODE_CAR = 0x03
            case SUFFIX_MODE_CUSTOM = 0x04
        }
    }
    
    enum CORE {
        static func toString() -> String {
            return "CORE"
        }
        // Temperature Service
        static let SERVICE_TEMPERATURE_SERVICE_ID = CBUUID(string: "00002100-5B1E-4347-B07C-97B514DAE121") // UUID for Temperature Service
        static let SERVICE_TEMPERATURE_TEMP_ID = CBUUID(string: "00002101-5B1E-4347-B07C-97B514DAE121") // UUID for Temperature Characteristic
        static let SERVICE_TEMPERATURE_CONTROL_POINT_ID = CBUUID(string: "00002102-5B1E-4347-B07C-97B514DAE121") // UUID for Control Point Characteristic
        static let ALTERNATIVE_TEMPERATURE_TEMP_ID = CBUUID(string: "00001809-0000-1000-8000-00805F9B34FB")
     
        enum InterpolationCommands: Int8 {
            case SCA_I_TOTAL_NUMBER = 0x0E
            case SCA_I_NAME_AT_INDEX = 0x0F
            case SCA_I_MAC_AT_INDEX = 0x10
            case SCA_T_SCAN = 0x0D
            case CON_I_TOTAL_NUMBER = 0x08
            case CON_I_NAME_AND_STATE_AT_INDEX = 0x09
            case CON_I_MAC_AND_STATE_AT_INDEX = 0x12
            case CON_T_PAIR = 0x06
            case CON_T_UNPAIR = 0x07
            case CON_T_CLEAR_ALL = 0x11
            case SEND_HRM_VALUE = 0x13
        }
    }
    
    enum UNKNOWN {
        static func toString() -> String {
            return "UNKNOWN"
        }
    }
}

// Utility function to determine SensorType from a scan result.
func getSensorTypeFromScanResult(for device: CBPeripheral, advertisementData: [String: Any]) -> SensorType {
    
    let deviceName = device.name
    let serviceUUIDs = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID]
    
    // First, check for the most reliable identifier: a specific service UUID
    if (serviceUUIDs?.contains(SensorType.OBU.SERVICE_NUS_SERVICE_ID)) != nil {
        return SensorType.obu
    }
    
    if (serviceUUIDs?.contains(SensorType.CORE.SERVICE_TEMPERATURE_SERVICE_ID)) != nil {
        return SensorType.core
    }
    
    // Fallback to name-based logic if no service UUID matches
    switch deviceName {
    case let name? where name.hasPrefix("OBU"):
        return .obu
    case let name? where name.hasPrefix("CORE"):
        return .core
    default:
        return .unknown
    }
}
