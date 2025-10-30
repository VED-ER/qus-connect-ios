//
//  Stopwatch.swift
//  qus-connect-ios
//
//  Created by Vedran Erak on 30. 10. 2025..
//

import Foundation
import Combine

class Stopwatch {
    private var timer: Cancellable?
    private var startTime: Date?
    private var accumulatedTime: TimeInterval = 0
    @Published private(set) var elapsedTime: Int = 0
    private var isRunning: Bool = false
    
    func start() {
        isRunning = true
        startTime = Date()
        timer?.cancel()
        timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect().sink { _ in
            self.elapsedTime = Int(self.getElapsedTime().rounded())
        }
    }
    
    func pause() {
        accumulatedTime = getElapsedTime()
        timer?.cancel()
        timer = nil
        startTime = nil
    }
    
    func resume() {
        start()
    }
    
    func stop() {
        timer?.cancel()
        timer = nil
        accumulatedTime = 0
        startTime = nil
        elapsedTime = 0
        isRunning = false
    }
    
    private func getElapsedTime() -> TimeInterval {
        return -(self.startTime?.timeIntervalSinceNow ?? 0) + self.accumulatedTime
    }
}
