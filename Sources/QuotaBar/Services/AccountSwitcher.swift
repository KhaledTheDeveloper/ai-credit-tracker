// Sources/QuotaBar/Services/AccountSwitcher.swift
import Foundation
import AppKit

public enum AccountSwitcher {
    private static var engineScriptPath: String {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let quotaBarDir = appSupport.appendingPathComponent("QuotaBar")
        let targetScript = quotaBarDir.appendingPathComponent("engine/index.js")
        if FileManager.default.fileExists(atPath: targetScript.path) {
            return targetScript.path
        }
        let localCandidate = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("engine/index.js")
        if FileManager.default.fileExists(atPath: localCandidate.path) {
            return localCandidate.path
        }
        return targetScript.path
    }

    /// Switches Antigravity's active session to the given account email.
    /// Calls `node engine/index.js switch <email>`, writes the jetski token file.
    public static func switchAccount(email: String, completion: @escaping (Bool, String) -> Void) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["node", engineScriptPath, "switch", email]

        var env = ProcessInfo.processInfo.environment
        let standardPaths = "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"
        env["PATH"] = standardPaths + ":" + (env["PATH"] ?? "")
        process.environment = env

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try process.run()
                process.waitUntilExit()

                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8) ?? ""

                let success = process.terminationStatus == 0
                let message: String
                if let jsonData = output.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                   let msg = json["message"] as? String {
                    message = msg
                } else {
                    message = success ? "Switched to \(email)" : "Switch failed"
                }

                DispatchQueue.main.async {
                    completion(success, message)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(false, "Failed to run switch command: \(error.localizedDescription)")
                }
            }
        }
    }
}
