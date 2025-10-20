//
//  OBUClasses.swift
//  qus-connect-ios
//
//  Created by Vedran Erak on 20. 10. 2025..
//

import Foundation

enum OBUPageError: Error {
    case invalidPageId(id: UInt)
}

protocol OBUPage {
    var pageId: UInt { get }
    var pageCount: UInt { get }
}

enum OBUPageHelpers {
    
    static func unixToDate(from input: UInt) -> Date? {
        guard input != 0 else { return nil }
        return Date(timeIntervalSince1970: TimeInterval(input))
    }
    
    static func unixToDate(start: UInt, offset: UInt = 0) -> Date {
        let totalSeconds = TimeInterval(start) + TimeInterval(offset)
        return Date(timeIntervalSince1970: totalSeconds)
    }
    
    static func pageIdToBand(id: UInt) throws -> Int {
        switch id {
        case 4, 8, 16: return 1
        case 5, 9, 17: return 3
        case 6, 10, 18: return 5
        case 7, 11, 19: return 7
        default: throw OBUPageError.invalidPageId(id: id)
        }
    }
    
    static func convertNMEAToGPS(coordinate: Int) -> Double {
        let absCoordinate = abs(coordinate)
        let tempDeg = absCoordinate / 1_000_000
        let tempMin = absCoordinate - 1_000_000 * tempDeg
        
        var result = Double(tempDeg) + (Double(tempMin) / 10000.0 / 60.0)
        
        if coordinate < 0 {
            result = -result
        }
        
        return result
    }
    
    static func convertDecimetersToMeters(input: UInt) -> Double {
        return Double(input) / 10.0
    }
    
    static func convertNMEAHeadingToDegrees(heading: UInt) -> Double {
        return Double(heading) / 100.0
    }
    
    static func convertSpeedToKmh(speed: UInt) -> Double {
        let kmh = Double(speed) * 1.852 / 100.0
        return roundToFourDecimalPlaces(value: kmh)
    }
    
    static func roundToFourDecimalPlaces(value: Double) -> Double {
        return (value * 10000).rounded() / 10000
    }
    
    static func convertHDOPToPrecision(hdop: UInt) -> Double {
        return Double(hdop) / 10.0
    }
}

struct OBUPage_Logging: OBUPage {
    let pageId: UInt
    let pageCount: UInt
    let loggingData: Data
}

struct OBUPage_1: OBUPage {
    let pageId: UInt
    let pageCount: UInt
    let sessionStart: Date
    let intervalDuration: UInt
    let sessionDurationTimeStamp: UInt
    let sessionMetaData: UInt8
    let periodNumber: UInt
    let heartRate: UInt?
    let respiration: UInt?
}

struct OBUPage_2: OBUPage {
    let pageId: UInt
    let pageCount: UInt
    let accelerationX: Int
    let accelerationY: Int
    let accelerationZ: Int
    let playerLoad: UInt
}

struct OBUPage_3: OBUPage {
    let pageId: UInt
    let pageCount: UInt
    let hrValidFlag: Bool
    let respValidFlag: Bool
    let accumulatedPlayerLoad: UInt
    let highSpeedRange: Int
    let explosiveDistance: Int
    let totalDistanceTravelled: UInt
}

struct OBUPage_4_8_16: OBUPage {
    let pageId: UInt
    let pageCount: UInt
    let dwellTime_A: UInt
    let distanceCovered_A: UInt
    let dwellTime_B: UInt
    let distanceCovered_B: UInt
    let bandNumber_A: Int
}

struct OBUPage_20_22_23: OBUPage {
    let pageId: UInt
    let pageCount: UInt
    let counterBand1: UInt
    let counterBand2: UInt
    let counterBand3: UInt
    let counterBand4: UInt
    let counterBand5: UInt
    let counterBand6: UInt
    let counterBand7: UInt
    let counterBand8: UInt
}

struct OBUPage_24: OBUPage {
    let pageId: UInt
    let pageCount: UInt
    let longitude: Double?
    let latitude: Double?
    let altitude: Double?
    let heading: Double?
    let speed: Double?
    let satelliteNumber: UInt
    let hdop: Double
}

struct OBUPage_120: OBUPage {
    let pageId: UInt = 120
    let pageCount: UInt = 0
    
    static let PREFIX: [UInt8] = [0x01, 0x00, 0x00, 0x78, 0x00]
    static let SUFFIX_MODE_RUNNING: UInt8 = 0x00
    static let SUFFIX_MODE_CYCLING: UInt8 = 0x01
    static let SUFFIX_MODE_SWIMMING: UInt8 = 0x02
    static let SUFFIX_MODE_CAR: UInt8 = 0x03
    static let SUFFIX_MODE_CUSTOM: UInt8 = 0x04
}

struct OBUPage_123: OBUPage {
    let pageId: UInt = 123
    let pageCount: UInt = 0
}

struct OBUPage_124: OBUPage {
//    let pageId: UInt = 124
//    let pageCount: UInt = 0
    let pageId: UInt
    let pageCount: UInt
    let UUID_0: UInt
    let UUID_1: UInt
    let UUID_2: UInt
    
    static let PREFIX: [UInt8] = [0x01, 0x00, 0x00, 0x7C]
    
    func toSupabasePayloadv1() -> [String: Any?] {
        return [
            "pageId": Int(pageId),
            "pageCount": Int(pageCount),
            "UUID_0": Int(UUID_0),
            "UUID_1": Int(UUID_1),
            "UUID_2": Int(UUID_2),
        ]
    }
}

struct OBUPage_125: OBUPage {
    let pageId: UInt = 125
    let pageCount: UInt = 0
    
    static let PREFIX: [UInt8] = [0x01, 0x00, 0x00, 0x7D]
    static let SUFFIX_START_SESSION: UInt8 = 0x01
    static let SUFFIX_STOP_SESSION: UInt8 = 0x02
    static let SUFFIX_PAUSE_SESSION: UInt8 = 0x03
    static let SUFFIX_RESUME_SESSION: UInt8 = 0x04
    static let SUFFIX_START_SESSION_GNSS_DISABLED: UInt8 = 0x05
    static let SUFFIX_SET_TEAM_MODE: UInt8 = 0x06
    static let SUFFIX_SET_INDIVIDUAL_MODE: UInt8 = 0x07
    static let SUFFIX_SET_SLEEP_MODE: UInt8 = 0x08
}

struct OBUPage_126: OBUPage {
    let pageId: UInt = 126
    let pageCount: UInt = 0
    
    static let PREFIX: [UInt8] = [0x01, 0x00, 0x00, 0x7E]
}

struct OBUBatteryStatus {
    let batteryVoltage: Int
    let batteryLevel: Int
}

struct OBUPage_127: OBUPage {
    let pageId: UInt
    let pageCount: UInt
    let fwPartNumber: UInt
    let fwVersion: UInt
    let modPartNumber: UInt
    let batteryVoltage: UInt
    let batteryLevel: UInt
    
    static let PREFIX: [UInt8] = [0x01, 0x00, 0x00, 0x7F]
    
    func toOBUBatteryStatus() -> OBUBatteryStatus {
        return OBUBatteryStatus(
            batteryVoltage: Int(batteryVoltage),
            batteryLevel: Int(batteryLevel)
        )
    }
    
    func toSupabasePayloadv1() -> [String: Any?] {
        return [
            "fwPartNumber": Int(fwPartNumber),
            "fwVersion": Int(fwVersion),
            "modPartNumber": Int(modPartNumber),
            "batteryVoltage": Int(batteryVoltage),
            "batteryLevel": Int(batteryLevel)
        ]
    }
}
