// Sources/QuotaBarCore/Services/UsageCache.swift
import Foundation

public final class UsageCache: Sendable {

    private let directory: URL
    private var cacheFile: URL { directory.appendingPathComponent("quota_cache.json") }

    public init(directory: URL) {
        self.directory = directory
    }

    public func save(_ usages: [AccountUsage]) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(usages)
        try data.write(to: cacheFile, options: .atomic)
    }

    public func load() throws -> [AccountUsage] {
        guard FileManager.default.fileExists(atPath: cacheFile.path) else {
            return []
        }
        let data = try Data(contentsOf: cacheFile)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([AccountUsage].self, from: data)
    }

    public func markStale(email: String) throws -> AccountUsage? {
        var usages = try load()
        guard let index = usages.firstIndex(where: { $0.email == email }) else {
            return nil
        }
        let original = usages[index]
        let stale = AccountUsage(
            email: original.email,
            pools: original.pools,
            fetchedAt: original.fetchedAt,
            isStale: true
        )
        usages[index] = stale
        try save(usages)
        return stale
    }
}
