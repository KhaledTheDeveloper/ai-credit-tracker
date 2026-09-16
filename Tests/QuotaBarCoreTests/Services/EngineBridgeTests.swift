import Foundation
import Testing
@testable import QuotaBarCore

@Suite struct EngineBridgeTests {

    @Test func parsesMultiAccountJSON() throws {
        let fixtureURL = try #require(Bundle.module.url(forResource: "sample_quota_response", withExtension: "json", subdirectory: "Fixtures") ?? Bundle.module.url(forResource: "sample_quota_response", withExtension: "json"))
        let data = try Data(contentsOf: fixtureURL)

        let usages = try EngineBridge.parseQuotaJSON(data)

        #expect(usages.count == 2)
        #expect(usages[0].email == "user1@gmail.com")
        #expect(usages[1].email == "user2@gmail.com")
        #expect(usages[0].pools.count == 2)
        #expect(usages[0].pools[0].displayName == "Gemini Models")
        #expect(usages[0].pools[1].displayName == "Claude and GPT models")
        #expect(usages[0].pools[1].weeklySupersedes5h == true)
        #expect(!usages[0].isStale)
    }

    @Test func parsesEmptyArray() throws {
        let data = "[]".data(using: .utf8)!
        let usages = try EngineBridge.parseQuotaJSON(data)
        #expect(usages.isEmpty)
    }

    @Test func throwsOnMalformedJSON() {
        let data = "not json".data(using: .utf8)!
        #expect(throws: EngineBridgeError.invalidJSON) {
            try EngineBridge.parseQuotaJSON(data)
        }
    }

    @Test func throwsOnWrongShape() {
        let data = """
        {"unexpected": "shape"}
        """.data(using: .utf8)!
        #expect(throws: EngineBridgeError.invalidJSON) {
            try EngineBridge.parseQuotaJSON(data)
        }
    }

    @Test func fetchAllThrowsWhenEngineNotFound() async {
        let bridge = EngineBridge(enginePath: "/nonexistent/path/to/engine.js")
        await #expect(throws: EngineBridgeError.engineNotFound(path: "/nonexistent/path/to/engine.js")) {
            try await bridge.fetchAll()
        }
    }

    @Test func liveEngineFetchIntegration() async throws {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let enginePath = home.appendingPathComponent("Library/Application Support/QuotaBar/engine/index.js").path
        guard FileManager.default.fileExists(atPath: enginePath) else { return }

        let bridge = EngineBridge(enginePath: enginePath)
        let usages = try await bridge.fetchAll()
        
        #expect(!usages.isEmpty)
        if let account = usages.first(where: { !$0.pools.isEmpty }) ?? usages.first {
            #expect(account.email.contains("@"))
            print("LIVE TEST SUCCESS! Fetched for account: \(account.email)")
            for pool in account.pools {
                print("  Pool: \(pool.displayName)")
                if let weekly = pool.weekly {
                    print("    Weekly: \(Int(weekly.remainingPercent))%, resets \(weekly.resetTime)")
                }
                if let fiveHour = pool.fiveHour {
                    print("    5-hour: \(Int(fiveHour.remainingPercent))%, resets \(fiveHour.resetTime) (superseded: \(pool.weeklySupersedes5h))")
                }
            }
        }
    }
}
