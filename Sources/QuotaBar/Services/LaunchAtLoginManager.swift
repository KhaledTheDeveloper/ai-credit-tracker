// Sources/QuotaBar/Services/LaunchAtLoginManager.swift
import Foundation
import ServiceManagement

/// Manages registering/unregistering the app as a macOS login item
/// using SMAppService (macOS 13+).
enum LaunchAtLoginManager {

    /// Whether the app is currently registered as a login item.
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    /// Register or unregister the app as a login item.
    static func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("LaunchAtLoginManager: failed to \(enabled ? "register" : "unregister") login item: \(error)")
        }
    }
}
