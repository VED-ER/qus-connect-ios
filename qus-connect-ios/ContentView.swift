//
//  ContentView.swift
//  qus-connect-ios
//
//  Created by Vedran Erak on 15. 10. 2025..
//

import SwiftUI
import SwiftData
import CoreBluetooth

struct Device: Identifiable {
    let id: String
    let name: String
}

struct ContentView: View {
    @StateObject private var bleManager = BLEManager()
    
    private var parsedDevices: [Device] {
        bleManager.scannedDevices.map { device in
            Device(id: device.identifier.uuidString, name: device.name ?? "Unnamed")
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if let connectedPeripheral = bleManager.connectedDevice {
                    DeviceDetailView(
                        peripheralUUID: connectedPeripheral.identifier.uuidString,
                        disconnectAction: {
                            bleManager.disconnect()
                        }
                    )
                } else {
                    List(parsedDevices) { device in
                        Button(action: {
                            if let peripheralToConnect = bleManager.scannedDevices.first(where: { $0.identifier.uuidString == device.id }) {
                                bleManager.connect(to: peripheralToConnect)
                            }
                        }) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(device.name)
                                        .font(.headline)
                                    Text(device.id)
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
                ToolbarItem(placement: .topBarLeading) {
                    Text(bleManager.isBluetoothOn ? "Bluetooth is ON" : "Bluetooth is OFF")
                }
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
}

#Preview {
    ContentView()
}
