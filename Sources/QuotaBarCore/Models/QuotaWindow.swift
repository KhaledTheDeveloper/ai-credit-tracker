// Sources/QuotaBarCore/Models/QuotaWindow.swift
import Foundation

public struct QuotaWindow: Codable, Equatable, Sendable {
    public let remainingFraction: Double
    public let resetTime: Date
    public let window: String

    public var remainingPercent: Double { remainingFraction * 100.0 }
    public var isExhausted: Bool { remainingFraction <= 0.0 }

    public var formattedResetTime: String {
        let interval = resetTime.timeIntervalSinceNow
        guard interval > 0 else { return "soon" }
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        if hours >= 24 {
            let days = hours / 24
            let remainingHours = hours % 24
            return "\(days)d \(remainingHours)h"
        }
        return "\(hours)h \(minutes)m"
    }

    public init(remainingFraction: Double, resetTime: Date, window: String) {
        self.remainingFraction = remainingFraction
        self.resetTime = resetTime
        self.window = window
    }
}
