//
//  SupabaseTrackpoint.swift
//  qus-connect-ios
//
//  Created by Vedran Erak on 31. 10. 2025..
//

import Foundation

struct SupabaseTrackpoint: Codable {
    let userId: String
    let sessionId: String
    let timestamp: Date?
    let hrVal: Int?
    let hrRr: Int?
    let hrIsValid: Bool?
    let rrVal: Int?
    let rrIsValid: Bool?
    let tempSkin: Double?
    let tempCore: Double?
    let tempQuality: Int?
    let tempHrState: Int?
    let altitude: Double?
    let latitude: Double?
    let longitude: Double?
    let satellites: Int?
    let speed: Double?
    let heading: Double?
    let hdop: Double?
    let accX: Double?
    let accY: Double?
    let accZ: Double?
    let distance: Double?
    let explosiveDistance: Int?
    let playerLoad: Double?
    let accumulatedPlayerLoad: Int?
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case sessionId = "session_id"
        case timestamp
        case hrVal = "hr_value"
        case hrRr = "hr_rr"
        case hrIsValid = "hr_valid"
        case rrVal = "rr_value"
        case rrIsValid = "rr_valid"
        case tempSkin = "temp_skin"
        case tempCore = "temp_core"
        case tempQuality = "temp_quality"
        case tempHrState = "temp_hr_state"
        case altitude
        case latitude
        case longitude
        case satellites = "satellite_count"
        case speed
        case heading
        case hdop
        case accX = "acc_x"
        case accY = "acc_y"
        case accZ = "acc_z"
        case distance
        case explosiveDistance = "explosive_distance"
        case playerLoad = "player_load"
        case accumulatedPlayerLoad = "accumulated_player_load"
    }
}
