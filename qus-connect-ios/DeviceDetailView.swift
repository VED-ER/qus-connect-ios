//
//  DeviceDetailView.swift
//  qus-connect-ios
//
//  Created by Vedran Erak on 15. 10. 2025..
//
import SwiftUI

struct DeviceDetailView: View {
    let peripheralUUID: String
    let disconnectAction: () -> Void
    let startTxNotifications: () -> Void
    let stopTxNotifications: () -> Void
    let trackpoint: Trackpoint?
    
    private var jsonString: String {
        if(trackpoint != nil){
            if let formattedJson = stringifyTrackpoint(trackpoint!){
                return formattedJson
            } else {
                return "Error parsing trackpoint"
            }
        }else {
            return "Loading..."
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text(peripheralUUID)
                    .font(.largeTitle)
                
                Text(jsonString)
                    .font(.system(.body, design: .monospaced)) // Use a monospaced font
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                
                Button("Start tx notifications") {
                    startTxNotifications()
                }
                
                Button("Stop tx notifications") {
                    stopTxNotifications()
                }
                
                Button("Disconnect") {
                    disconnectAction()
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }
            .navigationTitle("Device Details")
        }
    }
    
    func stringifyTrackpoint(_ trackpoint: Trackpoint) -> String? {
        let encoder = JSONEncoder()
        // Configure the encoder for readable output
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            // 1. Encode the object to Data
            let jsonData = try encoder.encode(trackpoint)
            // 2. Convert the Data to a String
            return String(data: jsonData, encoding: .utf8)
        } catch {
            print("Failed to encode Trackpoint: \(error)")
            return nil
        }
    }
}
