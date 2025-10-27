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
    let trackpoints: [Trackpoint]
    
    var latestTrackpoint: Trackpoint? {
        trackpoints.last
    }
    
    var latestHrVal: Int? {
        latestTrackpoint?.hrVal
    }
    
    var latestRrVal: Int? {
        latestTrackpoint?.rrVal
    }
    
    var hrAverage: Double {
        let hrValues = trackpoints.compactMap { $0.hrVal }
        guard !hrValues.isEmpty else { return 0 }
        let hrValuesTotal = hrValues.reduce(0, +)
        return Double(hrValuesTotal / hrValues.count)
    }
    
    var rrAverage: Double {
        let rrValues = trackpoints.compactMap { $0.rrVal }
        guard !rrValues.isEmpty else { return 0 }
        let rrValuesTotal = rrValues.reduce(0, +)
        return Double(rrValuesTotal / rrValues.count)
    }
    
    var latestTempCore: Double? {
        latestTrackpoint?.tempCore
    }
    
    var latestTempSkin: Double? {
        latestTrackpoint?.tempSkin
    }
    
    var coreTempAverage: Double {
        let coreTempValues = trackpoints.compactMap { $0.tempCore }
        guard !coreTempValues.isEmpty else { return 0 }
        let coreTempValuesTotal = coreTempValues.reduce(0, +)
        return coreTempValuesTotal / Double(coreTempValues.count)
    }
    
    var skinTempAverage: Double {
        let skinTempValues = trackpoints.compactMap { $0.tempSkin }
        guard !skinTempValues.isEmpty else { return 0 }
        let skinTempValuesTotal = skinTempValues.reduce(0, +)
        return skinTempValuesTotal / Double(skinTempValues.count)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                Text(peripheralUUID)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top)
                
                // --- Check for data ---
                if trackpoints.isEmpty {
                    ContentUnavailableView(
                        "No Data",
                        systemImage: "chart.bar.xaxis.ascending",
                        description: Text("Start TX notifications to see live data.")
                    )
                } else {
                    MetricDisplayView(
                        title: "Vital Data",
                        metric1Title: "HR",
                        metric1Value: latestHrVal == nil ? "-" : "\(latestHrVal!)",
                        metric1Average: String(format: "%.1f", hrAverage),
                        metric1Color: .red,
                        metric2Title: "RR",
                        metric2Value: latestRrVal == nil ? "-" : "\(latestRrVal!)",
                        metric2Average: String(format: "%.1f", rrAverage),
                        metric2Color: .blue,
                    )
                    
                    MetricDisplayView(
                        title: "Temperature",
                        metric1Title: "Core",
                        metric1Value: String(format: "%.1f", latestTempCore ?? "-"),
                        metric1Average: String(format: "%.1f", coreTempAverage),
                        metric1Color: .orange,
                        metric2Title: "Skin",
                        metric2Value: String(format: "%.1f", latestTempSkin ?? "-"),
                        metric2Average: String(format: "%.1f", skinTempAverage),
                        metric2Color: .green,
                    )
                }
                
                // --- Control Buttons ---
                VStack(spacing: 15) {
                    Button("Start tx notifications") {
                        startTxNotifications()
                    }
                    .buttonStyle(.bordered)
                    .tint(.green)
                    
                    Button("Stop tx notifications") {
                        stopTxNotifications()
                    }
                    .buttonStyle(.bordered)
                    .tint(.yellow)
                    
                    Button("Disconnect") {
                        disconnectAction()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                }
                .padding(.top)
                
            }
            .padding(.horizontal)
            .navigationTitle("Device Details")
        }
    }
}

struct MetricDisplayView: View {
    let title: String
    let metric1Title: String
    let metric1Value: String
    let metric1Average: String
    let metric1Color: Color
    let metric2Title: String
    let metric2Value: String
    let metric2Average: String
    let metric2Color: Color
    
    var body: some View {
        VStack(alignment: .center, spacing: 10) {
            Text(title)
                .font(.title)
                .foregroundStyle(.secondary)
                .padding(.bottom, 10)
            
            HStack(spacing: 20) {
                MetricBlock(title: metric1Title, value: metric1Value, color: metric1Color, avgVal: metric1Average)
                MetricBlock(title: metric2Title, value: metric2Value, color: metric2Color, avgVal: metric2Average)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

/// A single block for showing a title and a large value
struct MetricBlock: View {
    let title: String
    let value: String
    let color: Color
    let avgVal: String
    
    var body: some View {
        VStack(alignment: .center) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.white)
            Text(value)
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(avgVal)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}
