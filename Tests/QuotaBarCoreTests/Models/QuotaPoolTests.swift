// Tests/QuotaBarCoreTests/Models/QuotaPoolTests.swift
import Foundation
import Testing
@testable import QuotaBarCore

@Suite struct QuotaPoolTests {

    @Test func decodesFromAPIJSON() throws {
        let json = """
        {
          "displayName": "Claude and GPT models",
          "buckets": [
            {"window":"weekly","remainingFraction":0.42,"resetTime":"2026-09-23T11:45:00Z"},
            {"window":"5h","remainingFraction":0.15,"resetTime":"2026-09-16T14:15:00Z"}
          ]
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let pool = try decoder.decode(QuotaPool.self, from: json)

        #expect(pool.displayName == "Claude and GPT models")
        #expect(pool.id == "Claude and GPT models")
        #expect(pool.fiveHour != nil)
        #expect(pool.weekly != nil)
        #expect(abs((pool.fiveHour?.remainingFraction ?? 0) - 0.15) < 0.001)
        #expect(abs((pool.weekly?.remainingFraction ?? 0) - 0.42) < 0.001)
    }

    @Test func weeklySupersedes5h_whenWeeklyExhausted() throws {
        let json = """
        {
          "displayName": "Claude and GPT models",
          "buckets": [
            {"window":"weekly","remainingFraction":0.0,"resetTime":"2026-09-19T18:30:00Z"},
            {"window":"5h","remainingFraction":0.12,"resetTime":"2026-09-16T16:10:00Z"}
          ]
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let pool = try decoder.decode(QuotaPool.self, from: json)

        #expect(pool.weeklySupersedes5h)
    }

    @Test func weeklyDoesNotSupersede_whenNotExhausted() throws {
        let json = """
        {
          "displayName": "Gemini Models",
          "buckets": [
            {"window":"weekly","remainingFraction":1.0,"resetTime":"2026-09-23T11:45:00Z"},
            {"window":"5h","remainingFraction":1.0,"resetTime":"2026-09-16T16:30:00Z"}
          ]
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let pool = try decoder.decode(QuotaPool.self, from: json)

        #expect(!pool.weeklySupersedes5h)
    }
}
