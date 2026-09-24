// Sources/QuotaBarCore/Services/UsageFetcher.swift
import Foundation
import Combine

@MainActor
public final class UsageFetcher: ObservableObject {

    @Published public private(set) var usages: [AccountUsage] = []
    @Published public private(set) var isFetching: Bool = false
    @Published public private(set) var lastError: String?

    public private(set) var pollInterval: TimeInterval
    public var isPolling: Bool { pollTimer?.isValid == true }

    private let engine: EngineBridge
    private let cache: UsageCache
    private let maxJitterSeconds: Double
    private var pollTimer: Timer?

    /// Retained so we can compare old vs new for threshold notifications
    private var previousUsages: [AccountUsage] = []

    /// Settings accessor — set by the app after init
    public var settings: AppSettings = AppSettings()

    public init(
        engine: EngineBridge,
        cache: UsageCache,
        pollInterval: TimeInterval = 300,
        maxJitterSeconds: Double = 3.0
    ) {
        self.engine = engine
        self.cache = cache
        self.pollInterval = pollInterval
        self.maxJitterSeconds = maxJitterSeconds

        // Load cached data on init, marked as stale
        self.usages = Self.loadStaleCachedUsages(from: cache)
    }

    public func startPolling() {
        pollTimer?.invalidate()
        let timer = Timer(timeInterval: pollInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.fetchAll()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        pollTimer = timer
        Task { [weak self] in
            await self?.fetchAll()
        }
    }

    public func stopPolling() {
        pollTimer?.invalidate()
        pollTimer = nil
    }

    deinit {
        pollTimer?.invalidate()
    }

    public func updatePollInterval(_ seconds: TimeInterval) {
        pollInterval = seconds
        if pollTimer != nil {
            startPolling()
        }
    }

    public func fetchAll(isManual: Bool = false) async {
        isFetching = true
        lastError = nil
        defer { isFetching = false }

        // Add jitter before fetching for automated background polling only
        if !isManual {
            let jitter = Self.randomJitter(maxSeconds: maxJitterSeconds)
            if jitter > 0 {
                try? await Task.sleep(nanoseconds: UInt64(jitter * 1_000_000_000))
            }
        }

        do {
            let fresh = try await engine.fetchAll()
            try? cache.save(fresh)

            // Check for threshold crossings and send notifications
            if !previousUsages.isEmpty {
                let alerts = NotificationService.checkThresholds(
                    previous: previousUsages,
                    current: fresh,
                    settings: settings
                )
                for alert in alerts {
                    NotificationService.send(alert)
                }
            }

            previousUsages = fresh
            usages = fresh
        } catch {
            lastError = error.localizedDescription
            // Fall back to cached data marked as stale
            usages = Self.loadStaleCachedUsages(from: cache)
        }
    }

    // MARK: - Private helpers

    private static func loadStaleCachedUsages(from cache: UsageCache) -> [AccountUsage] {
        guard let cached = try? cache.load() else { return [] }
        return cached.map { usage in
            AccountUsage(
                email: usage.email,
                pools: usage.pools,
                fetchedAt: usage.fetchedAt,
                isStale: true
            )
        }
    }

    // MARK: - Static helpers (testable)

    nonisolated public static func randomJitter(maxSeconds: Double) -> Double {
        guard maxSeconds > 0 else { return 0.0 }
        return Double.random(in: 0...maxSeconds)
    }

    nonisolated public static func backoffDelay(attempt: Int, baseSeconds: Double) -> Double {
        let capped = min(max(attempt, 0), 2)
        return baseSeconds * pow(2.0, Double(capped))
    }
}
