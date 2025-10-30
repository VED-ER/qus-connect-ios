//
//  DeviceDetailView.swift
//  qus-connect-ios
//
//  Created by Vedran Erak on 15. 10. 2025..
//
import SwiftUI
import Charts

struct DeviceDetailView: View {
    let peripheralUUID: String
    let disconnectAction: () -> Void
    let startTxNotifications: () -> Void
    let stopTxNotifications: () -> Void
    let startSession: (_ deviceId: String) -> Void
    let startSessionWithoutGNSS: (_ deviceId: String) -> Void
    let pauseSession: (_ deviceId: String) -> Void
    let resumeSession: (_ deviceId: String) -> Void
    let stopSession: (_ deviceId: String) -> Void
    let trackpoints: [Trackpoint]
    let elapsedTime: Int?
    
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
    
    var hrChartData: [VitalChartData] {
        trackpoints.compactMap { tp in
            guard let timestamp = tp.timestamp else { return nil }
            return VitalChartData(type: "Heart rate", value: tp.hrVal ?? 0, timestamp: timestamp)
        }
    }
    
    var rrChartData: [VitalChartData] {
        trackpoints.compactMap { tp in
            guard let timestamp = tp.timestamp else { return nil }
            return VitalChartData(type: "Respiratory rate", value: tp.rrVal ?? 0, timestamp: timestamp)
        }
    }
    
    var skinTempChartData: [TempChartData] {
        trackpoints.compactMap { tp in
            guard let timestamp = tp.timestamp else { return nil }
            return TempChartData(type: "Skin temperature", value: tp.tempSkin ?? 0, timestamp: timestamp)
        }
    }
    
    var coreTempChartData: [TempChartData] {
        trackpoints.compactMap { tp in
            guard let timestamp = tp.timestamp else { return nil }
            return TempChartData(type: "Core temperature", value: tp.tempCore ?? 0, timestamp: timestamp)
        }
    }
    
    func formatElapsedTime(seconds: Int?) -> String {
        guard let totalSeconds = seconds, totalSeconds > 0 else {
            return "00"
        }
        
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let remainingSeconds = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, remainingSeconds)
        } else if minutes > 0 {
            return String(format: "%02d:%02d", minutes, remainingSeconds)
        } else {
            return String(format: "%02d", remainingSeconds)
        }
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
                    if let elapsedTime = elapsedTime {
                        Text(formatElapsedTime(seconds: elapsedTime))
                            .font(.system(size: 60, weight: .bold, design: .monospaced))
                            .padding()
                    }
                    MetricDisplayView(
                        title: "Vital Data",
                        metric1Title: "HR",
                        metric1Value: latestHrVal.map { String($0) } ?? "--",
                        metric1Average: hrAverage == 0.0 ? "--" : String(format: "%.1f", hrAverage),
                        metric1Color: .red,
                        metric2Title: "RR",
                        metric2Value: latestRrVal.map { String($0) } ?? "--",
                        metric2Average: rrAverage == 0.0 ? "--" : String(format: "%.1f", rrAverage),
                        metric2Color: .blue,
                    )
                    
                    MetricDisplayView(
                        title: "Temperature",
                        metric1Title: "Core",
                        metric1Value: latestTempCore.map {String(format: "%.1f", $0) } ?? "--",
                        metric1Average: coreTempAverage == 0.0 ? "--" : String(format: "%.1f", coreTempAverage),
                        metric1Color: .orange,
                        metric2Title: "Skin",
                        metric2Value: latestTempSkin.map { String(format: "%.1f", $0) } ?? "--",
                        metric2Average: skinTempAverage == 0.0 ? "--" : String(format: "%.1f", skinTempAverage),
                        metric2Color: .green,
                    )
                    
                    VitalDataChart(hrData: hrChartData, rrData: rrChartData)
                    TempDataChart(skinData: skinTempChartData, coreData: coreTempChartData)
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
                    
                    Text("Session commands").font(.headline)
                    
                    Button("Start session") {
                        startSession(peripheralUUID)
                    }
                    
                    Button("Start session without GNSS") {
                        startSessionWithoutGNSS(peripheralUUID)
                    }
                    
                    Button("Pause session") {
                        pauseSession(peripheralUUID)
                    }
                    
                    Button("Resume session") {
                        resumeSession(peripheralUUID)
                    }
                    
                    Button("Stop session") {
                        stopSession(peripheralUUID)
                    }
                    
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

struct VitalChartData: Identifiable {
    var id = UUID()
    var type: String
    var value: Int
    var timestamp: Date
}

struct VitalDataChart: View {
    let hrData: [VitalChartData]
    let rrData: [VitalChartData]
    
    var combinedData: [VitalChartData] { hrData + rrData }
    
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            Text("Vital (Heart & Respiration Rate)")
                .font(.headline)
                .padding(.horizontal)
                .padding(.bottom, 10)
            
            Chart(combinedData) { item in
                LineMark(
                    x: .value("Time", item.timestamp),
                    y: .value("Value", item.value)
                )
                .foregroundStyle(by: .value("Type", item.type))
            }
            .chartForegroundStyleScale([
                "Heart rate": .red,
                "Respiratory rate": .blue,
            ])
            .chartLegend(.visible)
            .frame(height: 220)
        }
    }
}

struct TempChartData: Identifiable {
    var id = UUID()
    var type: String
    var value: Double
    var timestamp: Date
}

struct TempDataChart: View {
    let skinData: [TempChartData]
    let coreData: [TempChartData]
    
    var combinedData: [TempChartData] { skinData + coreData }
    
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            Text("Temperature (Skin & Core)")
                .font(.headline)
                .padding(.horizontal)
                .padding(.bottom, 10)
            
            Chart(combinedData) { item in
                LineMark(
                    x: .value("Time", item.timestamp),
                    y: .value("Value", item.value)
                )
                .foregroundStyle(by: .value("Type", item.type))
            }
            .chartForegroundStyleScale([
                "Skin temperature": .yellow,
                "Core temperature": .green
            ])
            .chartLegend(.visible)
            .frame(height: 220)
            .chartYScale(domain: 0...100)
        }
    }
}
