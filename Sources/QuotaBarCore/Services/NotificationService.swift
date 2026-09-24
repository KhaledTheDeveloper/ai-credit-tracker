// Sources/QuotaBarCore/Services/NotificationService.swift
import Foundation
import UserNotifications

public enum NotificationKind: Equatable, Sendable {
    case lowThreshold
    case reset
    case fiveHourExhausted
    case weeklyExhausted
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

    private static let claudePoolName = "Claude and GPT models"

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

                // --- Configurable low threshold crossing (all pools) ---
                let prevFraction = prevPool.fiveHour?.remainingFraction ?? 0
                let currFraction = currPool.fiveHour?.remainingFraction ?? 0

                if prevFraction > threshold && currFraction <= threshold && currFraction > 0 {
                    notifications.append(QuotaNotification(
                        email: curr.email,
                        pool: currPool.displayName,
                        kind: .lowThreshold,
                        message: "\(curr.email): \(currPool.displayName) below \(Int(settings.lowThresholdPercent))%"
                    ))
                }

                // --- Reset detection (was exhausted, now has headroom) ---
                if prevFraction <= 0.0 && currFraction > 0.5 {
                    notifications.append(QuotaNotification(
                        email: curr.email,
                        pool: currPool.displayName,
                        kind: .reset,
                        message: "\(curr.email): \(currPool.displayName) has reset"
                    ))
                }

                // --- Claude-specific: 5-hour quota exhausted ---
                if currPool.displayName == claudePoolName {
                    let prev5h = prevPool.fiveHour?.remainingFraction ?? 0
                    let curr5h = currPool.fiveHour?.remainingFraction ?? 0

                    if prev5h > 0 && curr5h <= 0 {
                        notifications.append(QuotaNotification(
                            email: curr.email,
                            pool: currPool.displayName,
                            kind: .fiveHourExhausted,
                            message: "⚠️ \(curr.email): Claude 5-hour quota exhausted! Resets in \(currPool.fiveHour?.formattedResetTime ?? "~5h")"
                        ))
                    }

                    // --- Claude-specific: Weekly quota exhausted ---
                    let prevWeekly = prevPool.weekly?.remainingFraction ?? 0
                    let currWeekly = currPool.weekly?.remainingFraction ?? 0

                    if prevWeekly > 0 && currWeekly <= 0 {
                        notifications.append(QuotaNotification(
                            email: curr.email,
                            pool: currPool.displayName,
                            kind: .weeklyExhausted,
                            message: "🚨 \(curr.email): Claude weekly quota exhausted! Resets in \(currPool.weekly?.formattedResetTime ?? "~7d")"
                        ))
                    }
                }
            }
        }

        return notifications
    }

    public static func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    public static func send(_ notification: QuotaNotification) {
        let content = UNMutableNotificationContent()
        content.title = "AI Credit Tracker"
        content.body = notification.message
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "\(notification.email)-\(notification.pool)-\(notification.kind)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
}
