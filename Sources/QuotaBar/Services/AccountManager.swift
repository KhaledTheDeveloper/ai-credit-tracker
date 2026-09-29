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

    /// Removes only credentials created by QuotaBar. Credentials owned by
    /// Antigravity or other account managers are intentionally left untouched.
    @discardableResult
    public static func removeAccount(email: String) -> Bool {
        let fm = FileManager.default
        let home = fm.homeDirectoryForCurrentUser
        let accountsDirectory = home.appendingPathComponent("Library/Application Support/QuotaBar/accounts")
        let accountDirectory = accountsDirectory.appendingPathComponent(email)

        // Refuse malformed identifiers that could escape the accounts directory.
        guard !email.isEmpty,
              email != ".",
              email != "..",
              !email.contains("/"),
              !email.contains("\\"),
              accountDirectory.deletingLastPathComponent().standardizedFileURL == accountsDirectory.standardizedFileURL else {
            return false
        }

        guard fm.fileExists(atPath: accountDirectory.path) else {
            return true
        }

        do {
            try fm.removeItem(at: accountDirectory)
            return true
        } catch {
            return false
        }
    }
}
