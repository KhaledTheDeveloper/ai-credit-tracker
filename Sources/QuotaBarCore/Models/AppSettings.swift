// Sources/QuotaBarCore/Models/AppSettings.swift
import Foundation

public enum SortMode: String, Codable, CaseIterable, Sendable {
    case remainingFirst
    case soonestReset
    case alphabetical

    public var displayName: String {
        switch self {
        case .soonestReset: return "Soonest Reset"
        case .remainingFirst: return "Most Remaining Quota"
        case .alphabetical: return "Alphabetical (Email)"
        }
    }
}

public struct AppSettings: Codable, Equatable, Sendable {
    public var pollIntervalSeconds: Int
    public var lowThresholdPercent: Double
    public var sortMode: SortMode = .soonestReset
    public var primaryPool: String
    public var launchAtLogin: Bool
    public var hiddenAccounts: [String]

    public init(
        pollIntervalSeconds: Int = 300,
        lowThresholdPercent: Double = 10.0,
        sortMode: SortMode = .soonestReset,
        primaryPool: String = "Claude and GPT models",
        launchAtLogin: Bool = false,
        hiddenAccounts: [String] = []
    ) {
        self.pollIntervalSeconds = pollIntervalSeconds
        self.lowThresholdPercent = lowThresholdPercent
        self.sortMode = sortMode
        self.primaryPool = primaryPool
        self.launchAtLogin = launchAtLogin
        self.hiddenAccounts = hiddenAccounts
    }
}
