//
//  OBUTrace.swift
//  qus-connect-ios
//
//  Created by Vedran Erak on 20. 10. 2025..
//

import Foundation

struct OBUTrace {
    var timestamp: Date? = nil
    var hrVal: Int? = nil
    var hrRr: Int? = nil
    var hrIsValid: Bool? = nil
    var rrVal: Int? = nil
    var rrIsValid: Bool? = nil
    var altitude: Double? = nil
    var latitude: Double? = nil
    var longitude: Double? = nil
    var satellites: Int? = nil
    var heading: Double? = nil
    var speed: Double? = nil
    var hdop: Double? = nil
    var accX: Int? = nil
    var accY: Int? = nil
    var accZ: Int? = nil
    var distance: Double? = nil
    var explosiveDistance: Int? = nil
    var playerLoad: Int? = nil
    var accumulatedPlayerLoad: Int? = nil
    
    func settingPageCreationTime(startTime: Date, sessionDuration: UInt) -> OBUTrace {
        var newTrace = self // Creates a copy because struct is a value type
        newTrace.timestamp = startTime.addingTimeInterval(TimeInterval(sessionDuration))
        return newTrace
    }
    
    func updating(with page: OBUPage_1) -> OBUTrace {
        var newTrace = self
        newTrace.timestamp = page.sessionStart.addingTimeInterval(TimeInterval(page.sessionDurationTimeStamp))
        newTrace.hrVal = page.heartRate.map { Int($0) }
        newTrace.rrVal = page.respiration.map { Int($0) }
        return newTrace
    }
    
    func updating(with page: OBUPage_2) -> OBUTrace {
        var newTrace = self
        newTrace.accX = page.accelerationX
        newTrace.accY = page.accelerationY
        newTrace.accZ = page.accelerationZ
        newTrace.playerLoad = Int(page.playerLoad)
        return newTrace
    }
    
    func updating(with page: OBUPage_3) -> OBUTrace {
        var newTrace = self
        newTrace.hrIsValid = page.hrValidFlag
        newTrace.rrIsValid = page.respValidFlag
        newTrace.accumulatedPlayerLoad = Int(page.accumulatedPlayerLoad)
        newTrace.distance = Double(page.totalDistanceTravelled)
        newTrace.explosiveDistance = page.explosiveDistance
        return newTrace
    }
    
    func updating(with page: OBUPage_24) -> OBUTrace {
        var newTrace = self
        newTrace.latitude = page.latitude
        newTrace.longitude = page.longitude
        newTrace.altitude = page.altitude
        newTrace.satellites = Int(page.satelliteNumber)
        newTrace.speed = page.speed
        newTrace.heading = page.heading
        newTrace.hdop = page.hdop
        return newTrace
    }
}
