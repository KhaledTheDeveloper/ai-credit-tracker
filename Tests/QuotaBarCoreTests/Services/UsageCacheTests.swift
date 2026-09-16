// Tests/QuotaBarCoreTests/Services/UsageCacheTests.swift
import Foundation
import Testing
@testable import QuotaBarCore

@Suite final class UsageCacheTests {

    let cacheDir: URL
    let cache: UsageCache

    init() {
        cacheDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("QuotaBarCacheTests-\(UUID().uuidString)")
        cache = UsageCache(directory: cacheDir)
    }

    deinit {
        try? FileManager.default.removeItem(at: cacheDir)
    }

    @Test func saveAndLoad() throws {
        let usages = [
            AccountUsage.sample(email: "a@g.com", geminiRemaining: 1.0, claudeRemaining: 0.5),
            AccountUsage.sample(email: "b@g.com", geminiRemaining: 0.8, claudeRemaining: 0.3),
        ]
        try cache.save(usages)
        let loaded = try cache.load()

        #expect(loaded.count == 2)
        #expect(loaded[0].email == "a@g.com")
        #expect(loaded[1].email == "b@g.com")
    }

    @Test func loadReturnsEmptyWhenNoCacheExists() throws {
        let loaded = try cache.load()
        #expect(loaded.isEmpty)
    }

    @Test func markStale() throws {
        let usages = [
            AccountUsage.sample(email: "a@g.com", geminiRemaining: 1.0, claudeRemaining: 0.5),
        ]
        try cache.save(usages)
        let stale = try cache.markStale(email: "a@g.com")

        #expect(stale != nil)
        #expect(stale?.isStale == true)
        #expect(stale?.email == "a@g.com")
    }

    @Test func markStaleReturnsNilWhenAccountNotFound() throws {
        let usages = [
            AccountUsage.sample(email: "a@g.com", geminiRemaining: 1.0, claudeRemaining: 0.5),
        ]
        try cache.save(usages)
        let stale = try cache.markStale(email: "missing@g.com")

        #expect(stale == nil)
    }

    @Test func markStalePersistsStaleFlag() throws {
        let usages = [
            AccountUsage.sample(email: "a@g.com", geminiRemaining: 1.0, claudeRemaining: 0.5),
            AccountUsage.sample(email: "b@g.com", geminiRemaining: 0.8, claudeRemaining: 0.3),
        ]
        try cache.save(usages)
        _ = try cache.markStale(email: "a@g.com")

        let loaded = try cache.load()
        #expect(loaded.count == 2)
        let a = loaded.first { $0.email == "a@g.com" }
        let b = loaded.first { $0.email == "b@g.com" }
        #expect(a?.isStale == true)
        #expect(b?.isStale == false)
    }

    @Test func saveOverwritesPreviousCache() throws {
        let first = [
            AccountUsage.sample(email: "a@g.com", geminiRemaining: 1.0, claudeRemaining: 0.5),
        ]
        try cache.save(first)

        let second = [
            AccountUsage.sample(email: "c@g.com", geminiRemaining: 0.2, claudeRemaining: 0.1),
        ]
        try cache.save(second)

        let loaded = try cache.load()
        #expect(loaded.count == 1)
        #expect(loaded[0].email == "c@g.com")
    }
}
