// Sources/QuotaBar/QuotaBarApp.swift
import SwiftUI
import QuotaBarCore

@main
struct QuotaBarApp: App {
    @StateObject private var fetcher: UsageFetcher = {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let quotaBarDir = appSupport.appendingPathComponent("QuotaBar")
        let enginePath = Self.resolveEngineScript(appSupportDir: quotaBarDir)
        let engine = EngineBridge(enginePath: enginePath)
        let cache = UsageCache(directory: quotaBarDir.appendingPathComponent("cache"))
        let fetcher = UsageFetcher(engine: engine, cache: cache)
        fetcher.startPolling()
        return fetcher
    }()

    private static func resolveEngineScript(appSupportDir: URL) -> String {
        let fm = FileManager.default
        let targetEngineDir = appSupportDir.appendingPathComponent("engine")
        let targetEngineScript = targetEngineDir.appendingPathComponent("index.js")

        // 1. If running from repository or local directory has engine/index.js, ensure AppSupport is synced
        let localCandidate = URL(fileURLWithPath: fm.currentDirectoryPath).appendingPathComponent("engine/index.js")
        if fm.fileExists(atPath: localCandidate.path) {
            try? fm.createDirectory(at: targetEngineDir, withIntermediateDirectories: true)
            if fm.fileExists(atPath: targetEngineScript.path) {
                try? fm.removeItem(at: targetEngineScript)
            }
            try? fm.copyItem(at: localCandidate, to: targetEngineScript)
            return targetEngineScript.path
        }

        // 2. If App Support copy exists, use it
        if fm.fileExists(atPath: targetEngineScript.path) {
            return targetEngineScript.path
        }

        return targetEngineScript.path
    }

    @StateObject private var settingsStore = SettingsStore()

    var body: some Scene {
        MenuBarExtra {
            MenuBarContentView(fetcher: fetcher, settingsStore: settingsStore)
        } label: {
            Image(systemName: "bolt.circle")
        }
        .menuBarExtraStyle(.window)
    }
}
