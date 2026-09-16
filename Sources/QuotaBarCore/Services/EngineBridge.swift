import Foundation

public enum EngineBridgeError: Error, Equatable {
    case engineNotFound(path: String)
    case engineFailed(exitCode: Int32, stderr: String)
    case invalidJSON
}

public final class EngineBridge: Sendable {

    private let enginePath: String

    public init(enginePath: String) {
        self.enginePath = enginePath
    }

    /// Parses raw JSON data (stdout from engine) into AccountUsage array.
    /// This is a static method so it can be tested without a real engine process.
    public static func parseQuotaJSON(_ data: Data) throws -> [AccountUsage] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do {
            return try decoder.decode([AccountUsage].self, from: data)
        } catch {
            throw EngineBridgeError.invalidJSON
        }
    }

    /// Invokes the engine subprocess and returns parsed results.
    public func fetchAll() async throws -> [AccountUsage] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["node", enginePath, "quota", "--all", "--json"]

        var env = ProcessInfo.processInfo.environment
        let standardPaths = "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"
        env["PATH"] = standardPaths + ":" + (env["PATH"] ?? "")
        process.environment = env

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        guard FileManager.default.fileExists(atPath: enginePath) else {
            throw EngineBridgeError.engineNotFound(path: enginePath)
        }

        try process.run()
        process.waitUntilExit()

        let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
        let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()

        guard process.terminationStatus == 0 else {
            let stderr = String(data: stderrData, encoding: .utf8) ?? ""
            throw EngineBridgeError.engineFailed(
                exitCode: process.terminationStatus,
                stderr: stderr
            )
        }

        return try Self.parseQuotaJSON(stdoutData)
    }
}
