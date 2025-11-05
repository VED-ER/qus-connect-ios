//
//  ContentView.swift
//  qus-connect-ios
//
//  Created by Vedran Erak on 15. 10. 2025..
//

import SwiftUI
import SwiftData
import CoreBluetooth

struct ContentView: View {
    @StateObject private var bleManager = BLEManager()
    
    @State private var trackpoints: [Trackpoint] = []
    
    private var connectedOBU: BluetoothDeviceWrapper? {
        bleManager.connectedDevices.first(where: { $0.sensorType == .obu })
    }
    
    private var connectedCORE: BluetoothDeviceWrapper? {
        bleManager.connectedDevices.first(where: { $0.sensorType == .core })
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if let connectedOBU = connectedOBU {
                    DeviceDetailView(
                        peripheralUUID: connectedOBU.peripheral.identifier.uuidString,
                        disconnectAction: {
                            bleManager.disconnectFromDevice(device: connectedOBU)
                        },
                        startTxNotifications: {
                            bleManager.startDeviceNotifications(for: connectedOBU.peripheral)
                        },
                        stopTxNotifications: {
                            bleManager.stopDeviceNotifications(for: connectedOBU.peripheral)
                        },
                        startSession: bleManager.startSession,
                        startSessionWithoutGNSS: bleManager.startSessionWithoutGNSS,
                        pauseSession: bleManager.pauseSession,
                        resumeSession: bleManager.resumeSession,
                        stopSession: bleManager.stopSession,
                        trackpoints: trackpoints,
                        elapsedTime: bleManager.stopwatchTime
                    )
                } else {
                    List(bleManager.scannedDevices, id: \.peripheral.identifier.uuidString) { device in
                        Button(action: {
                            bleManager.connect(to: device)
                        }) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(device.peripheral.name ?? "Unnamed device")
                                        .font(.headline)
                                    Text(device.peripheral.identifier.uuidString)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                        }
                        .foregroundColor(.primary)
                    }
                    .navigationTitle("BLE Devices")
                }
            }
            .toolbar {
                if #available(iOS 26.0, *) {
                    ToolbarItem(placement: .topBarLeading) {
                        Text(bleManager.isBluetoothOn ? "Bluetooth is ON" : "Bluetooth is OFF")
                            .fixedSize()
                        
                    }.sharedBackgroundVisibility(.hidden)
                } else {
                    ToolbarItem(placement: .topBarLeading) {
                        Text(bleManager.isBluetoothOn ? "Bluetooth is ON" : "Bluetooth is OFF")
                    }
                }
                if connectedOBU == nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(bleManager.isScanning ? "Scanning..." : "Scan") {
                            if bleManager.isScanning {
                                bleManager.stopScanning()
                            } else {
                                bleManager.startScanning()
                            }
                        }
                        .disabled(!bleManager.isBluetoothOn)
                    }
                }
            }
        }
        .onReceive(bleManager.$trackpoint) { newTrackpoint in
//            var currentTimestampTrackpoint = newTrackpoint
//            currentTimestampTrackpoint.timestamp = Date()
//            trackpoints.append(currentTimestampTrackpoint)
        }
        .onReceive(bleManager.$connectedDevices, perform: {(connectedDevices: [BluetoothDeviceWrapper]) -> Void in
            if connectedDevices.count == 0 {
                trackpoints.removeAll()
            }
        }
        )
    }
}

#Preview {
    ContentView()
}
