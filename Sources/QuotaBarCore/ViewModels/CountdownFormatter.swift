// Sources/QuotaBarCore/ViewModels/CountdownFormatter.swift
import Foundation

public enum CountdownFormatter: Sendable {

    public static func string(from resetTime: Date, relativeTo now: Date = Date()) -> String {
        let seconds = Int(resetTime.timeIntervalSince(now))

        if seconds <= 0 { return "now" }
        if seconds < 60 { return "<1m" }

        let days = seconds / 86400
        let hours = (seconds % 86400) / 3600
        let minutes = (seconds % 3600) / 60

        if days > 0 {
            return "\(days)d \(hours)h"
        } else if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}
