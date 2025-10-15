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

    var body: some View {
        VStack(spacing: 20) {
            Text(peripheralUUID)
                .font(.largeTitle)
            
            Button("Disconnect") {
                disconnectAction()
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
        }
        .navigationTitle("Device Details")
    }
}
