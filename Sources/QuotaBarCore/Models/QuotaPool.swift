// Sources/QuotaBarCore/Models/QuotaPool.swift
import Foundation

public struct QuotaPool: Codable, Identifiable, Equatable, Sendable {
    public var id: String { displayName }
    public let displayName: String
    public let buckets: [QuotaWindow]

    public var fiveHour: QuotaWindow? { buckets.first { $0.window == "5h" } }
    public var weekly: QuotaWindow? { buckets.first { $0.window == "weekly" } }
    public var weeklySupersedes5h: Bool { weekly?.isExhausted == true }

    public init(displayName: String, buckets: [QuotaWindow]) {
        self.displayName = displayName
        self.buckets = buckets
    }
}
