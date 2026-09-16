// Tests/QuotaBarCoreTests/Models/QuotaWindowTests.swift
import Foundation
import Testing
@testable import QuotaBarCore

@Suite struct QuotaWindowTests {

    @Test func decodesFromAPIJSON() throws {
        let json = """
        {"window":"5h","remainingFraction":0.85,"resetTime":"2026-09-16T16:30:00Z"}
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let window = try decoder.decode(QuotaWindow.self, from: json)

        #expect(window.window == "5h")
        #expect(abs(window.remainingFraction - 0.85) < 0.001)
        #expect(abs(window.remainingPercent - 85.0) < 0.1)
        #expect(!window.isExhausted)
    }

    @Test func exhaustedWhenZero() throws {
        let json = """
        {"window":"weekly","remainingFraction":0.0,"resetTime":"2026-09-19T18:30:00Z"}
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let window = try decoder.decode(QuotaWindow.self, from: json)

        #expect(window.isExhausted)
        #expect(window.remainingPercent == 0.0)
    }
}
