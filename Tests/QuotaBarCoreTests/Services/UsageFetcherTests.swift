// Tests/QuotaBarCoreTests/Services/UsageFetcherTests.swift
import Foundation
import Testing
@testable import QuotaBarCore

@Suite final class UsageFetcherTests {

    let tempDir: URL

    init() {
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("UsageFetcherTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    deinit {
        try? FileManager.default.removeItem(at: tempDir)
    }

    @Test func jitterIsWithinRange() {
        for _ in 0..<100 {
            let jitter = UsageFetcher.randomJitter(maxSeconds: 3.0)
            #expect(jitter >= 0.0)
            #expect(jitter <= 3.0)
        }
    }

    @Test func backoffDelayDoublesWithRetries() {
        #expect(UsageFetcher.backoffDelay(attempt: 0, baseSeconds: 5.0) == 5.0)
        #expect(UsageFetcher.backoffDelay(attempt: 1, baseSeconds: 5.0) == 10.0)
        #expect(UsageFetcher.backoffDelay(attempt: 2, baseSeconds: 5.0) == 20.0)
    }

    @Test func backoffDelayIsCappedAt3Retries() {
        let delay2 = UsageFetcher.backoffDelay(attempt: 2, baseSeconds: 5.0)
        let delay3 = UsageFetcher.backoffDelay(attempt: 3, baseSeconds: 5.0)
        #expect(delay2 == delay3)
    }

    @Test @MainActor func initLoadsCachedUsagesMarkedAsStale() throws {
        let cache = UsageCache(directory: tempDir)
        let sample = AccountUsage.sample(email: "cached@example.com", geminiRemaining: 0.9, claudeRemaining: 0.8, isStale: false)
        try cache.save([sample])

        let engine = EngineBridge(enginePath: "/nonexistent/engine.js")
        let fetcher = UsageFetcher(engine: engine, cache: cache, pollInterval: 300, maxJitterSeconds: 0)

        #expect(fetcher.usages.count == 1)
        #expect(fetcher.usages.first?.email == "cached@example.com")
        #expect(fetcher.usages.first?.isStale == true)
        #expect(!fetcher.isFetching)
        #expect(fetcher.lastError == nil)
    }

    @Test @MainActor func startAndStopPolling() {
        let cache = UsageCache(directory: tempDir)
        let engine = EngineBridge(enginePath: "/nonexistent/engine.js")
        let fetcher = UsageFetcher(engine: engine, cache: cache, pollInterval: 60, maxJitterSeconds: 0)

        #expect(!fetcher.isPolling)

        fetcher.startPolling()
        #expect(fetcher.isPolling)

        fetcher.stopPolling()
        #expect(!fetcher.isPolling)
    }

    @Test @MainActor func updatePollInterval() {
        let cache = UsageCache(directory: tempDir)
        let engine = EngineBridge(enginePath: "/nonexistent/engine.js")
        let fetcher = UsageFetcher(engine: engine, cache: cache, pollInterval: 60, maxJitterSeconds: 0)

        fetcher.updatePollInterval(120)
        #expect(fetcher.pollInterval == 120)

        fetcher.startPolling()
        #expect(fetcher.isPolling)

        fetcher.updatePollInterval(30)
        #expect(fetcher.pollInterval == 30)
        #expect(fetcher.isPolling)

        fetcher.stopPolling()
    }

    @Test @MainActor func fetchAllFailure_setsLastErrorAndFallsBackToStaleCache() async throws {
        let cache = UsageCache(directory: tempDir)
        let sample = AccountUsage.sample(email: "fallback@example.com", geminiRemaining: 0.5, claudeRemaining: 0.5, isStale: false)
        try cache.save([sample])

        let engine = EngineBridge(enginePath: "/nonexistent/engine.js")
        let fetcher = UsageFetcher(engine: engine, cache: cache, pollInterval: 300, maxJitterSeconds: 0)

        await fetcher.fetchAll()

        #expect(fetcher.lastError != nil)
        #expect(!fetcher.isFetching)
        #expect(fetcher.usages.count == 1)
        #expect(fetcher.usages.first?.email == "fallback@example.com")
        #expect(fetcher.usages.first?.isStale == true)
    }

    @Test @MainActor func fetchAllSuccess_updatesUsagesAndSavesCache() async throws {
        let cache = UsageCache(directory: tempDir)
        let mockScript = tempDir.appendingPathComponent("mock_engine.js")
        let jsonOutput = """
        console.log(JSON.stringify([{
            email: "fresh@example.com",
            pools: [],
            fetchedAt: "2026-09-16T12:00:00Z",
            isStale: false
        }]));
        """
        try jsonOutput.write(to: mockScript, atomically: true, encoding: .utf8)

        let engine = EngineBridge(enginePath: mockScript.path)
        let fetcher = UsageFetcher(engine: engine, cache: cache, pollInterval: 300, maxJitterSeconds: 0)

        await fetcher.fetchAll()

        #expect(fetcher.lastError == nil)
        #expect(!fetcher.isFetching)
        #expect(fetcher.usages.count == 1)
        #expect(fetcher.usages.first?.email == "fresh@example.com")
        #expect(fetcher.usages.first?.isStale == false)

        let saved = try cache.load()
        #expect(saved.count == 1)
        #expect(saved.first?.email == "fresh@example.com")
    }
}
