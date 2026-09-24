// Sources/QuotaBarCore/Services/NotificationService.swift
import Foundation
import UserNotifications

public enum NotificationKind: Equatable, Sendable {
    case lowThreshold
    case reset
}

public struct QuotaNotification: Equatable, Sendable {
    public let email: String
    public let pool: String
    public let kind: NotificationKind
    public let message: String

    public init(email: String, pool: String, kind: NotificationKind, message: String) {
        self.email = email
        self.pool = pool
        self.kind = kind
        self.message = message
    }
}

public enum NotificationService {

    public static func checkThresholds(
        previous: [AccountUsage],
        current: [AccountUsage],
        settings: AppSettings
    ) -> [QuotaNotification] {
        var notifications: [QuotaNotification] = []
        let threshold = settings.lowThresholdPercent / 100.0

        for curr in current {
            guard let prev = previous.first(where: { $0.email == curr.email }) else { continue }

            for currPool in curr.pools {
                guard let prevPool = prev.pool(named: currPool.displayName) else { continue }

                // Use 5-hour window fractions for comparison
                let prevFraction = prevPool.fiveHour?.remainingFraction ?? 0
                let currFraction = currPool.fiveHour?.remainingFraction ?? 0

                // Low threshold crossing
                if prevFraction > threshold && currFraction <= threshold && currFraction > 0 {
                    notifications.append(QuotaNotification(
                        email: curr.email,
                        pool: currPool.displayName,
                        kind: .lowThreshold,
                        message: "\(curr.email): \(currPool.displayName) below \(Int(settings.lowThresholdPercent))%"
                    ))
                }

                // Reset detection (was exhausted, now has headroom)
                if prevFraction <= 0.0 && currFraction > 0.5 {
                    notifications.append(QuotaNotification(
                        email: curr.email,
                        pool: currPool.displayName,
                        kind: .reset,
                        message: "\(curr.email): \(currPool.displayName) has reset"
                    ))
                }
            }
        }

        return notifications
    }

    public static func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    public static func send(_ notification: QuotaNotification) {
        let content = UNMutableNotificationContent()
        content.title = "QuotaBar"
        content.body = notification.message
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "\(notification.email)-\(notification.kind)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
}
