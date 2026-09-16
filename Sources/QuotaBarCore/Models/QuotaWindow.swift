// Sources/QuotaBarCore/Models/QuotaWindow.swift
import Foundation

public struct QuotaWindow: Codable, Equatable, Sendable {
    public let remainingFraction: Double
    public let resetTime: Date
    public let window: String

    public var remainingPercent: Double { remainingFraction * 100.0 }
    public var isExhausted: Bool { remainingFraction <= 0.0 }

    public init(remainingFraction: Double, resetTime: Date, window: String) {
        self.remainingFraction = remainingFraction
        self.resetTime = resetTime
        self.window = window
    }
}
