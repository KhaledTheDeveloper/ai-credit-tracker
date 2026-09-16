// Tests/QuotaBarCoreTests/ViewModels/CountdownFormatterTests.swift
import Foundation
import Testing
@testable import QuotaBarCore

@Suite struct CountdownFormatterTests {

    @Test func minutesCountdown() {
        let now = Date()
        let reset = now.addingTimeInterval(38 * 60) // 38 minutes
        let result = CountdownFormatter.string(from: reset, relativeTo: now)
        #expect(result == "38m")
    }

    @Test func hoursAndMinutesCountdown() {
        let now = Date()
        let reset = now.addingTimeInterval(2 * 3600 + 15 * 60) // 2h 15m
        let result = CountdownFormatter.string(from: reset, relativeTo: now)
        #expect(result == "2h 15m")
    }

    @Test func daysCountdown() {
        let now = Date()
        let reset = now.addingTimeInterval(3 * 86400 + 4 * 3600) // 3d 4h
        let result = CountdownFormatter.string(from: reset, relativeTo: now)
        #expect(result == "3d 4h")
    }

    @Test func alreadyPast_returnsNow() {
        let now = Date()
        let reset = now.addingTimeInterval(-60) // 1 minute ago
        let result = CountdownFormatter.string(from: reset, relativeTo: now)
        #expect(result == "now")
    }

    @Test func lessThanOneMinute_returnsLessThan1m() {
        let now = Date()
        let reset = now.addingTimeInterval(30) // 30 seconds
        let result = CountdownFormatter.string(from: reset, relativeTo: now)
        #expect(result == "<1m")
    }

    @Test func boundaryExactZero_returnsNow() {
        let now = Date()
        let result = CountdownFormatter.string(from: now, relativeTo: now)
        #expect(result == "now")
    }

    @Test func boundaryExactSixtySeconds_returns1m() {
        let now = Date()
        let reset = now.addingTimeInterval(60)
        let result = CountdownFormatter.string(from: reset, relativeTo: now)
        #expect(result == "1m")
    }

    @Test func boundaryExactOneHour_returns1h0m() {
        let now = Date()
        let reset = now.addingTimeInterval(3600)
        let result = CountdownFormatter.string(from: reset, relativeTo: now)
        #expect(result == "1h 0m")
    }

    @Test func boundaryExactOneDay_returns1d0h() {
        let now = Date()
        let reset = now.addingTimeInterval(86400)
        let result = CountdownFormatter.string(from: reset, relativeTo: now)
        #expect(result == "1d 0h")
    }
}
