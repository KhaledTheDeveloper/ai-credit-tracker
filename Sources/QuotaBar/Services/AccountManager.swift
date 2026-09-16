import Foundation
import AppKit

public enum AccountManager {
    private static var engineScriptPath: String {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let quotaBarDir = appSupport.appendingPathComponent("QuotaBar")
        let targetScript = quotaBarDir.appendingPathComponent("engine/index.js")
        if FileManager.default.fileExists(atPath: targetScript.path) {
            return targetScript.path
        }
        let localCandidate = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("engine/index.js")
        if FileManager.default.fileExists(atPath: localCandidate.path) {
            return localCandidate.path
        }
        return targetScript.path
    }

    /// Launches Google OAuth login flow in background (which opens the default browser)
    public static func startBrowserOAuthLogin(completion: @escaping (Bool) -> Void) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["node", engineScriptPath, "login"]
        
        var env = ProcessInfo.processInfo.environment
        let standardPaths = "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"
        env["PATH"] = standardPaths + ":" + (env["PATH"] ?? "")
        process.environment = env

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try process.run()
                process.waitUntilExit()
                DispatchQueue.main.async {
                    completion(process.terminationStatus == 0)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(false)
                }
            }
        }
    }

    /// Opens macOS Terminal app running the login command for users who prefer visible terminal output
    public static func openTerminalLogin() {
        let script = """
        tell application "Terminal"
            activate
            do script "node \\\"\(engineScriptPath)\\\" login"
        end tell
        """
        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            appleScript.executeAndReturnError(&error)
        }
    }

    /// Removes stored credentials for an account from disk
    public static func removeAccount(email: String) {
        let fm = FileManager.default
        let home = fm.homeDirectoryForCurrentUser

        let pathsToCheck = [
            home.appendingPathComponent("Library/Application Support/antigravity-usage/accounts/\(email)"),
            home.appendingPathComponent("Library/Application Support/QuotaBar/accounts/\(email)")
        ]

        for dir in pathsToCheck {
            if fm.fileExists(atPath: dir.path) {
                try? fm.removeItem(at: dir)
            }
        }
    }
}
