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

        // 1. Check inside the .app bundle (for distributed builds)
        if let bundledEngine = Bundle.main.path(forResource: "index", ofType: "js", inDirectory: "engine") {
            // Copy bundled engine to App Support so it's always up to date
            try? fm.createDirectory(at: targetEngineDir, withIntermediateDirectories: true)
            if fm.fileExists(atPath: targetEngineScript.path) {
                try? fm.removeItem(at: targetEngineScript)
            }
            try? fm.copyItem(atPath: bundledEngine, toPath: targetEngineScript.path)
            return targetEngineScript.path
        }

        // 2. If running from repository, sync local engine to App Support
        let localCandidate = URL(fileURLWithPath: fm.currentDirectoryPath).appendingPathComponent("engine/index.js")
        if fm.fileExists(atPath: localCandidate.path) {
            try? fm.createDirectory(at: targetEngineDir, withIntermediateDirectories: true)
            if fm.fileExists(atPath: targetEngineScript.path) {
                try? fm.removeItem(at: targetEngineScript)
            }
            try? fm.copyItem(at: localCandidate, to: targetEngineScript)
            return targetEngineScript.path
        }

        // 3. If App Support copy exists, use it
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
        .onChange(of: settingsStore.settings) { newSettings in
            fetcher.settings = newSettings
        }
    }

    init() {
        NotificationService.requestPermission()
    }
}
