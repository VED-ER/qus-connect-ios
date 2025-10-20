//
//  OBUIntegrator.swift
//  qus-connect-ios
//
//  Created by Vedran Erak on 20. 10. 2025..
//

import Foundation

// Define a custom error for functions that are not yet implemented
enum OBUIntegrationError: Error {
    case notImplemented
}

// The main service, translated from a Kotlin `object` to a Swift `enum`
enum OBUIntegrationService {

    // MARK: - Listeners

    static func connectionChangeListener(input: Any?) {
        // TODO: Implement adequate measures
    }

    static func txNotificationListener(from data: Data) -> OBUPage {
        // A page ID is typically the 4th byte (index 3)
        guard data.count > 3 else {
            return OBUPage_Logging(pageId: 0, pageCount: 0, loggingData: data)
        }
        
        let pageId = safeToUInt(from: data, at: 3)
        
        switch pageId {
        case 1:         return pageParser_1(from: data)
        case 2:         return pageParser_2(from: data)
        case 3:         return pageParser_3(from: data)
        case 4...11,
             16...19:   return pageParser_4_8_16(from: data)
        case 20, 22, 23: return pageParser_20_22_23(from: data)
        case 24:        return pageParser_24(from: data)
        case 124:       return pageParser_124(from: data)
        case 127:       return pageParser_127(from: data)
        default:
            return OBUPage_Logging(pageId: pageId, pageCount: 0, loggingData: data)
        }
    }

    static func rxNotificationListener(from data: Data) -> OBUPage {
        let pageId = safeToUInt(from: data, at: 3)
        return OBUPage_Logging(pageId: pageId, pageCount: 0, loggingData: data)
    }

    static func heartRateNotificationListener(from data: Data) throws {
        throw OBUIntegrationError.notImplemented
    }

    // MARK: - Writers

    static func getODOProfileSet_120_Bytes(mode: SensorType.OBU.COMMANDS120) -> Data {
        return Data(OBUPage_120.PREFIX) + Data([mode.rawValue])
    }

    static func getDeviceUniqueId_124_Bytes() -> Data {
        return Data(OBUPage_124.PREFIX)
    }

    static func getOBUCommand_125_Bytes(mode: SensorType.OBU.COMMANDS125) -> Data {
        return Data(OBUPage_125.PREFIX) + Data([mode.rawValue])
    }

    static func getTimeSet_126_Bytes(targetTime: Date = Date()) -> Data {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: targetTime)
        
        // Note: Kotlin's `toByte()` truncates. `UInt8(truncatingIfNeeded:)` does the same.
        // The common BLE standard for year is often `year - 2000`. Verify with device specs.
        let year = UInt8(truncatingIfNeeded: components.year ?? 0)
        let month = UInt8(truncatingIfNeeded: components.month ?? 0)
        let day = UInt8(truncatingIfNeeded: components.day ?? 0)
        let hour = UInt8(truncatingIfNeeded: components.hour ?? 0)
        let minute = UInt8(truncatingIfNeeded: components.minute ?? 0)
        let second = UInt8(truncatingIfNeeded: components.second ?? 0)
        
        let payload: [UInt8] = [year, month, day, hour, minute, second]
        
        return Data(OBUPage_126.PREFIX) + Data(payload)
    }

    static func getDeviceInfoRequest_127_Bytes() -> Data {
        return Data(OBUPage_127.PREFIX)
    }

    // MARK: - Page Parsers

    private static func pageParser_1(from data: Data) -> OBUPage {
        let hrValue = safeToUInt(from: data, at: 18)
        let respValue = safeToUInt(from: data, at: 19)
        
        return OBUPage_1(
            pageId: safeToUInt(from: data, at: 3),
            pageCount: safeToUInt(from: data, at: 0, length: 3),
            sessionStart: OBUPageHelpers.unixToDate(start: safeToUInt(from: data, at: 4, length: 4)),
            intervalDuration: safeToUInt(from: data, at: 8, length: 4),
            sessionDurationTimeStamp: safeToUInt(from: data, at: 12, length: 4),
            sessionMetaData: data[16],
            periodNumber: safeToUInt(from: data, at: 17),
            heartRate: hrValue == 0 ? nil : hrValue,
            respiration: respValue == 0 ? nil : respValue
        )
    }

    private static func pageParser_2(from data: Data) -> OBUPage {
        return OBUPage_2(
            pageId: safeToUInt(from: data, at: 3),
            pageCount: safeToUInt(from: data, at: 0, length: 3),
            accelerationX: safeToInt(from: data, at: 4, length: 4),
            accelerationY: safeToInt(from: data, at: 8, length: 4),
            accelerationZ: safeToInt(from: data, at: 12, length: 4),
            playerLoad: safeToUInt(from: data, at: 16, length: 4)
        )
    }
    
    private static func pageParser_3(from data: Data) -> OBUPage {
        return OBUPage_3(
            pageId: safeToUInt(from: data, at: 3),
            pageCount: safeToUInt(from: data, at: 0, length: 3),
            hrValidFlag: data[4] == 0,
            respValidFlag: data[5] == 0,
            accumulatedPlayerLoad: safeToUInt(from: data, at: 6, length: 2),
            highSpeedRange: safeToInt(from: data, at: 8, length: 4),
            explosiveDistance: safeToInt(from: data, at: 12, length: 4),
            totalDistanceTravelled: safeToUInt(from: data, at: 16, length: 4)
        )
    }

    private static func pageParser_4_8_16(from data: Data) -> OBUPage {
        let localPageId = safeToUInt(from: data, at: 3)
        // Using a default of 0 if pageIdToBand throws, but you could handle the error differently.
        let bandNumber = (try? OBUPageHelpers.pageIdToBand(id: localPageId)) ?? 0

        return OBUPage_4_8_16(
            pageId: localPageId,
            pageCount: safeToUInt(from: data, at: 0, length: 3),
            dwellTime_A: safeToUInt(from: data, at: 4, length: 4),
            distanceCovered_A: safeToUInt(from: data, at: 8, length: 4),
            dwellTime_B: safeToUInt(from: data, at: 12, length: 4),
            distanceCovered_B: safeToUInt(from: data, at: 16, length: 4),
            bandNumber_A: bandNumber
        )
    }
    
    private static func pageParser_20_22_23(from data: Data) -> OBUPage {
        return OBUPage_20_22_23(
            pageId: safeToUInt(from: data, at: 3),
            pageCount: safeToUInt(from: data, at: 0, length: 3),
            counterBand1: safeToUInt(from: data, at: 4, length: 2),
            counterBand2: safeToUInt(from: data, at: 6, length: 2),
            counterBand3: safeToUInt(from: data, at: 8, length: 2),
            counterBand4: safeToUInt(from: data, at: 10, length: 2),
            counterBand5: safeToUInt(from: data, at: 12, length: 2),
            counterBand6: safeToUInt(from: data, at: 14, length: 2),
            counterBand7: safeToUInt(from: data, at: 16, length: 2),
            counterBand8: safeToUInt(from: data, at: 18, length: 2)
        )
    }
    
    private static func pageParser_24(from data: Data) -> OBUPage {
        let localLongitude = safeToInt(from: data, at: 4, length: 4)
        let localLatitude = safeToInt(from: data, at: 8, length: 4)
        let localAltitude = safeToUInt(from: data, at: 12, length: 2)
        let localHeading = safeToUInt(from: data, at: 14, length: 2)
        let localSpeed = safeToUInt(from: data, at: 16, length: 2)

        return OBUPage_24(
            pageId: safeToUInt(from: data, at: 3),
            pageCount: safeToUInt(from: data, at: 0, length: 3),
            longitude: localLongitude == 0 ? nil : OBUPageHelpers.convertNMEAToGPS(coordinate: localLongitude),
            latitude: localLatitude == 0 ? nil : OBUPageHelpers.convertNMEAToGPS(coordinate: localLatitude),
            altitude: localAltitude == 0 ? nil : OBUPageHelpers.convertDecimetersToMeters(input: localAltitude),
            heading: localHeading == 0 ? nil : OBUPageHelpers.convertNMEAHeadingToDegrees(heading: localHeading),
            speed: localSpeed == 0 ? nil : OBUPageHelpers.convertSpeedToKmh(speed: localSpeed),
            satelliteNumber: safeToUInt(from: data, at: 18),
            hdop: OBUPageHelpers.convertHDOPToPrecision(hdop: safeToUInt(from: data, at: 19))
        )
    }
    
    private static func pageParser_124(from data: Data) -> OBUPage {
        return OBUPage_124(
            pageId: safeToUInt(from: data, at: 3),
            pageCount: safeToUInt(from: data, at: 0, length: 3),
            UUID_0: safeToUInt(from: data, at: 4, length: 4),
            UUID_1: safeToUInt(from: data, at: 8, length: 4),
            UUID_2: safeToUInt(from: data, at: 12, length: 4)
        )
    }

    private static func pageParser_127(from data: Data) -> OBUPage {
        return OBUPage_127(
            pageId: safeToUInt(from: data, at: 3),
            pageCount: safeToUInt(from: data, at: 0, length: 3),
            fwPartNumber: safeToUInt(from: data, at: 4, length: 4),
            fwVersion: safeToUInt(from: data, at: 8, length: 4),
            modPartNumber: safeToUInt(from: data, at: 12, length: 4),
            batteryVoltage: safeToUInt(from: data, at: 16, length: 2),
            batteryLevel: safeToUInt(from: data, at: 18, length: 1)
        )
    }

    private static func heartRateParser(from data: Data) {
        // TODO: to be verified and return values
        guard let flags = data.first else { return }

        let is16BitHR = (flags & 0x01) != 0
        let energyExpendedPresent = (flags & 0x08) != 0
        let rrIntervalPresent = (flags & 0x10) != 0

        let hrmValue = Int(data[1]) // 8-bit Heart Rate Value

        let rrInterval: Int
        let rrIntervalMilliseconds: Double
        if rrIntervalPresent {
            let rrIndex = energyExpendedPresent ? 4 : 2
            rrInterval = Int(safeToUInt(from: data, at: rrIndex, length: 2))
            rrIntervalMilliseconds = Double(rrInterval) * (1000.0 / 1024.0)
        } else {
            rrInterval = -1
            rrIntervalMilliseconds = -1.0
        }
    }

    // MARK: - Byte Parsing Helpers

    private static func safeToInt(from data: Data, at position: Int, length: Int = 1) -> Int {
        var result: Int = 0
        // Ensure we don't read past the end of the data buffer
        let safeLength = min(length, data.count - position)
        guard safeLength > 0 else { return 0 }

        for i in 0..<safeLength {
            let byte = Int(data[position + i])
            result |= (byte << (8 * i))
        }
        return result
    }

    private static func safeToUInt(from data: Data, at position: Int, length: Int = 1) -> UInt {
        var result: UInt = 0
        // Ensure we don't read past the end of the data buffer
        let safeLength = min(length, data.count - position)
        guard safeLength > 0 else { return 0 }

        for i in 0..<safeLength {
            let byte = UInt(data[position + i])
            result |= (byte << (8 * i))
        }
        return result
    }

    @available(*, deprecated, renamed: "safeToUInt(from:at:length:)", message: "Use safeToUInt instead with position 0 and length 3.")
    static func toPageCount(from data: Data) -> Int {
        return Int(safeToUInt(from: data, at: 0, length: 3))
    }
}
