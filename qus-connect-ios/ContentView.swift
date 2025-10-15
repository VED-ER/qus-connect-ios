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

        var body: some View {
            NavigationView {
                VStack {
                    if let connectedPeripheral = bleManager.connectedPeripheral {
                        DeviceDetailView(
                            peripheralUUID: connectedPeripheral.identifier.uuidString,
                            disconnectAction: {
                                bleManager.disconnect()
                            }
                        )
                    } else {
                        List(bleManager.peripherals) { peripheral in
                            Button(action: {
                                bleManager.connect(to: peripheral)
                            }) {
                                HStack {
                                    Text(peripheral.id.uuidString).lineLimit(1)
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
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Scan") {
                            bleManager.startScanning()
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
