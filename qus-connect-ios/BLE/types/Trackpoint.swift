//
//  Trackpoint.swift
//  qus-connect-ios
//
//  Created by Vedran Erak on 20. 10. 2025..
//

import Foundation

// --- Helper Structs (to make the example complete) ---

struct Trackpoint: Codable {
    var timestamp: Date? = nil
    var hrVal: Int? = nil
    var hrRr: Int? = nil
    var hrIsValid: Bool? = nil
    var rrVal: Int? = nil
    var rrIsValid: Bool? = nil
    var tempSkin: Double? = nil
    var tempCore: Double? = nil
    var tempQuality: Int? = nil
    var tempHrState: Int? = nil
    var altitude: Double? = nil
    var latitude: Double? = nil
    var longitude: Double? = nil
    var satellites: Int? = nil
    var speed: Double? = nil
    var heading: Double? = nil
    var hdop: Double? = nil
    var accX: Double? = nil
    var accY: Double? = nil
    var accZ: Double? = nil
    var distance: Double? = nil
    var explosiveDistance: Int? = nil
    var playerLoad: Double? = nil
    var accumulatedPlayerLoad: Int? = nil

    /// Returns a new Trackpoint instance by merging data from an OBUTrace.
    func updating(with trace: OBUTrace) -> Trackpoint {
        var newTrackpoint = self // Create a copy of the current instance
        
        newTrackpoint.timestamp = trace.timestamp ?? self.timestamp
        newTrackpoint.hrVal = trace.hrVal
        newTrackpoint.hrRr = trace.hrRr
        newTrackpoint.hrIsValid = trace.hrIsValid
        newTrackpoint.rrVal = trace.rrVal
        newTrackpoint.rrIsValid = trace.rrIsValid
        newTrackpoint.altitude = trace.altitude
        newTrackpoint.latitude = trace.latitude
        newTrackpoint.longitude = trace.longitude
        newTrackpoint.satellites = trace.satellites
        newTrackpoint.speed = trace.speed
        newTrackpoint.heading = trace.heading
        newTrackpoint.hdop = trace.hdop
        newTrackpoint.accX = trace.accX.map { Double($0) }
        newTrackpoint.accY = trace.accY.map { Double($0) }
        newTrackpoint.accZ = trace.accZ.map { Double($0) }
        newTrackpoint.distance = trace.distance
        newTrackpoint.explosiveDistance = trace.explosiveDistance
        newTrackpoint.playerLoad = trace.playerLoad.map { Double($0) }
        newTrackpoint.accumulatedPlayerLoad = trace.accumulatedPlayerLoad
        
        return newTrackpoint
    }

//    func updating(with coreTrace: CORETrace) -> Trackpoint {
//        var newTrackpoint = self
//        
//        newTrackpoint.tempSkin = coreTrace.tempSkin
//        newTrackpoint.tempCore = coreTrace.tempCore
//        newTrackpoint.tempQuality = coreTrace.dataQuality?.rawValue
//        newTrackpoint.tempHrState = coreTrace.heartRateState?.rawValue
//        
//        return newTrackpoint
//    }
    
//    func toSupabaseTrackpoint(userId: String, sessionId: String) -> SupabaseTrackpoint {
//        // In a real app, you would map all properties.
//        return SupabaseTrackpoint(
//            userId: userId,
//            sessionId: sessionId,
//            timestamp: Date() // Uses the current time, as in the Kotlin code
//            // hrVal: hrVal, etc...
//        )
//    }
    
    /// Creates a dictionary payload for a JavaScript monitoring service.
    func toJSLiveSessionMonitoringPayload() -> [String: Any?] {
        return [
            "timestamp": Date().ISO8601Format(),
            "hr_value": hrVal,
            "hr_rr": hrRr,
            "hr_valid": hrIsValid,
            "rr_value": rrVal,
            "rr_valid": rrIsValid,
            "temp_skin": tempSkin,
            "temp_core": tempCore
        ]
    }
}
