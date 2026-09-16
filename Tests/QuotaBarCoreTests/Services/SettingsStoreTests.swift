// Tests/QuotaBarCoreTests/Services/SettingsStoreTests.swift
import Foundation
import Testing
@testable import QuotaBarCore

@Suite final class SettingsStoreTests {

    let suiteName: String
    let defaults: UserDefaults

    init() {
        suiteName = "test-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)!
    }

    deinit {
        defaults.removePersistentDomain(forName: suiteName)
    }

    @Test func defaultSettings() {
        let store = SettingsStore(defaults: defaults)
        #expect(store.settings.pollIntervalSeconds == 300)
        #expect(store.settings.primaryPool == "Claude and GPT models")
        #expect(store.settings.sortMode == .soonestReset)
        #expect(store.settings.lowThresholdPercent == 10.0)
        #expect(!store.settings.launchAtLogin)
    }

    @Test func persistsChanges() {
        let store1 = SettingsStore(defaults: defaults)
        var modified = store1.settings
        modified.pollIntervalSeconds = 120
        modified.primaryPool = "Gemini Models"
        modified.sortMode = .remainingFirst
        modified.lowThresholdPercent = 25.0
        modified.launchAtLogin = true
        store1.settings = modified

        let store2 = SettingsStore(defaults: defaults)
        #expect(store2.settings.pollIntervalSeconds == 120)
        #expect(store2.settings.primaryPool == "Gemini Models")
        #expect(store2.settings.sortMode == .remainingFirst)
        #expect(store2.settings.lowThresholdPercent == 25.0)
        #expect(store2.settings.launchAtLogin == true)
    }

    @Test func corruptDataFallsBackToDefaults() {
        defaults.set(Data("corrupted json data".utf8), forKey: "QuotaBarSettings")
        let store = SettingsStore(defaults: defaults)
        #expect(store.settings == AppSettings())
    }
}
