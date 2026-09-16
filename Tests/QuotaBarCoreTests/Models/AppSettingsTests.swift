// Tests/QuotaBarCoreTests/Models/AppSettingsTests.swift
import Foundation
import Testing
@testable import QuotaBarCore

@Suite struct AppSettingsTests {

    @Test func defaultValues() {
        let settings = AppSettings()
        #expect(settings.pollIntervalSeconds == 300)
        #expect(settings.lowThresholdPercent == 10.0)
        #expect(settings.sortMode == .soonestReset)
        #expect(settings.primaryPool == "Claude and GPT models")
        #expect(!settings.launchAtLogin)
    }

    @Test func codableRoundTrip() throws {
        let original = AppSettings(
            pollIntervalSeconds: 600,
            lowThresholdPercent: 15.0,
            sortMode: .remainingFirst,
            primaryPool: "Gemini Models",
            launchAtLogin: true
        )
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(AppSettings.self, from: data)

        #expect(decoded == original)
    }

    @Test func sortModeCases() {
        #expect(SortMode.allCases.count == 3)
        #expect(SortMode.allCases.contains(.remainingFirst))
        #expect(SortMode.allCases.contains(.soonestReset))
        #expect(SortMode.allCases.contains(.alphabetical))
    }
}
