// Sources/QuotaBarCore/Models/AccountUsage.swift
import Foundation

public struct AccountUsage: Codable, Identifiable, Equatable, Sendable {
    public var id: String { email }
    public let email: String
    public let pools: [QuotaPool]
    public let fetchedAt: Date
    public let isStale: Bool

    public func pool(named name: String) -> QuotaPool? {
        pools.first { $0.displayName == name }
    }

    public init(email: String, pools: [QuotaPool], fetchedAt: Date, isStale: Bool) {
        self.email = email
        self.pools = pools
        self.fetchedAt = fetchedAt
        self.isStale = isStale
    }

    /// Test helper — creates an AccountUsage with standard pool structure.
    public static func sample(
        email: String,
        geminiRemaining: Double,
        claudeRemaining: Double,
        isStale: Bool = false,
        fetchedAt: Date = Date()
    ) -> AccountUsage {
        let now = Date()
        let fiveHourReset = now.addingTimeInterval(3600)
        let weeklyReset = now.addingTimeInterval(86400 * 3)
        return AccountUsage(
            email: email,
            pools: [
                QuotaPool(displayName: "Gemini Models", buckets: [
                    QuotaWindow(remainingFraction: geminiRemaining, resetTime: weeklyReset, window: "weekly"),
                    QuotaWindow(remainingFraction: geminiRemaining, resetTime: fiveHourReset, window: "5h"),
                ]),
                QuotaPool(displayName: "Claude and GPT models", buckets: [
                    QuotaWindow(remainingFraction: claudeRemaining, resetTime: weeklyReset, window: "weekly"),
                    QuotaWindow(remainingFraction: claudeRemaining, resetTime: fiveHourReset, window: "5h"),
                ]),
            ],
            fetchedAt: fetchedAt,
            isStale: isStale
        )
    }
}
