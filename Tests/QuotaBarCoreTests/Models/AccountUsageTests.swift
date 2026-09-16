// Tests/QuotaBarCoreTests/Models/AccountUsageTests.swift
import Foundation
import Testing
@testable import QuotaBarCore

@Suite struct AccountUsageTests {

    @Test func decodesFullAPIResponse() throws {
        let json = """
        {
          "email": "user1@gmail.com",
          "pools": [
            {
              "displayName": "Gemini Models",
              "buckets": [
                {"window":"weekly","remainingFraction":1.0,"resetTime":"2026-09-23T11:45:00Z"},
                {"window":"5h","remainingFraction":1.0,"resetTime":"2026-09-16T16:30:00Z"}
              ]
            },
            {
              "displayName": "Claude and GPT models",
              "buckets": [
                {"window":"weekly","remainingFraction":0.0,"resetTime":"2026-09-19T18:30:00Z"},
                {"window":"5h","remainingFraction":0.12,"resetTime":"2026-09-16T14:15:00Z"}
              ]
            }
          ],
          "fetchedAt": "2026-09-16T12:00:00Z",
          "isStale": false
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let usage = try decoder.decode(AccountUsage.self, from: json)

        #expect(usage.email == "user1@gmail.com")
        #expect(usage.id == "user1@gmail.com")
        #expect(usage.pools.count == 2)
        #expect(!usage.isStale)

        let claudePool = usage.pool(named: "Claude and GPT models")
        #expect(claudePool != nil)
        #expect(claudePool?.weeklySupersedes5h == true)
    }

    @Test func poolLookupByName() throws {
        let usage = AccountUsage.sample(
            email: "test@gmail.com",
            geminiRemaining: 1.0,
            claudeRemaining: 0.5
        )
        #expect(usage.pool(named: "Gemini Models") != nil)
        #expect(usage.pool(named: "Claude and GPT models") != nil)
        #expect(usage.pool(named: "Nonexistent") == nil)
    }
}
