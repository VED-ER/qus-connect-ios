//
//  MQTTManager.swift
//  qus-connect-ios
//
//  Created by Vedran Erak on 4. 11. 2025..
//

import Foundation
import CocoaMQTT
import Combine

enum MQTTConnectionState {
    case connected
    case disconnected
    case connecting
}

class MQTTManager: NSObject, ObservableObject, CocoaMQTTDelegate {
    @Published var connectionState: MQTTConnectionState = .disconnected
    
    private var client: CocoaMQTT?
    private var localId: String = ""
    private var topicTrackpoints: String = ""
    
    private var jsonEncoder: JSONEncoder
    
    override init() {
        jsonEncoder = JSONEncoder()
        
        let customFormatter = DateFormatter()
        
        // Exact format to match ISO 8601 with microseconds
        // SSSSSS = 6 decimal places for fractional seconds
        customFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ"
        
        // This prevents the user's device settings from changing the format
        customFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        // Set the timezone to UTC (Z)
        customFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        jsonEncoder.dateEncodingStrategy = .formatted(customFormatter)
        
        super.init()
    }
    
    // MARK: - Connection
    func connect(
        id: String,
        username: String,
        accessToken: String,
        host: String = "broker.internal.qus.tech",
        port: UInt16 = 8883 // 8883 for SSL, 1883 for non-SSL
    ) {
        // If already connected with the same ID, do nothing
        if client != nil && connectionState == .connected && id == localId {
            print("MQTTHandler: Already connected.")
            return
        }
        
        client?.disconnect()
        
        print("MQTTHandler: Setting up new connection...")
        self.localId = id
        self.topicTrackpoints = "mobile/\(id)/tp"
        self.connectionState = .connecting
        
        client = CocoaMQTT(clientID: id, host: host, port: port)
        client?.username = username
        client?.password = accessToken
        client?.keepAlive = 60
        client?.delegate = self
        
        if port == 8883 {
            client?.enableSSL = true
        }
        
        let connectRes = client?.connect()
        print("MQTT: connect res \(connectRes!)")
    }
    
    func disconnect() {
        print("MQTTHandler: User requested disconnect.")
        client?.disconnect()
    }
    
    func publishTrackpoint(trackpoint: SupabaseTrackpoint) {
        guard connectionState == .connected, let client = client else {
            print("MQTTHandler: Not connected. Cannot publish trackpoint.")
            return
        }
        
        do {
            let data: Data = try jsonEncoder.encode(trackpoint)
            
            let payload = [UInt8](data)
            
            let message = CocoaMQTTMessage(
                topic: topicTrackpoints,
                payload: payload,
                qos: .qos0, // "fire and forget"
                retained: false,
            )
            
            client.publish(message)
        } catch {
            print("MQTTHandler: Failed to encode or publish Trackpoint: \(error)")
        }
    }
    
    // MARK: - CocoaMQTTDelegate Callbacks
    func mqtt(_ mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck) {
        if ack == .accept {
            print("MQTTHandler: Connected successfully.")
            connectionState = .connected
        } else {
            print("MQTTHandler: Connection failed: \(ack)")
            connectionState = .disconnected
        }
    }
    
    func mqttDidDisconnect(_ mqtt: CocoaMQTT, withError err: Error?) {
        connectionState = .disconnected
        
        if let err = err {
            print("MQTTHandler: Disconnected with error: \(err.localizedDescription)")
        } else {
            print("MQTTHandler: Disconnected.")
        }
        
        // auto-reconnect
        // Wait 5 seconds before trying to connect again
//        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
//            print("MQTTHandler: Attempting to reconnect...")
//            self.client?.connect()
//        }
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16) {
        print("MQTTHandler: Received message on topic \(message.topic)")
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didPublishMessage message: CocoaMQTTMessage, id: UInt16) {
         print("MQTTHandler: Published message to \(message.topic)")
    }
    
    func mqttDidPing(_ mqtt: CocoaMQTT) {
        print("MQTT: did pong")
    }
    
    func mqttDidReceivePong(_ mqtt: CocoaMQTT) {
        print("MQTT: did receive pong")
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didPublishAck id: UInt16) { }
    func mqtt(_ mqtt: CocoaMQTT, didSubscribeTopics success: NSDictionary, failed: [String]) { }
    func mqtt(_ mqtt: CocoaMQTT, didUnsubscribeTopics topics: [String]) { }
}
