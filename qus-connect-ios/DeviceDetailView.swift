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

    var body: some View {
        VStack(spacing: 20) {
            Text(peripheralUUID)
                .font(.largeTitle)
            
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
