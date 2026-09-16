// Tests/QuotaBarCoreTests/Services/NotificationServiceTests.swift
import Foundation
import Testing
@testable import QuotaBarCore

@Suite struct NotificationServiceTests {

    @Test func detectsThresholdCrossing() {
        let settings = AppSettings(lowThresholdPercent: 10.0, primaryPool: "Claude and GPT models")
        let prev = AccountUsage.sample(email: "a@g.com", geminiRemaining: 1.0, claudeRemaining: 0.15)
        let curr = AccountUsage.sample(email: "a@g.com", geminiRemaining: 1.0, claudeRemaining: 0.08)

        let notifications = NotificationService.checkThresholds(
            previous: [prev], current: [curr], settings: settings
        )

        #expect(notifications.count == 1)
        #expect(notifications[0].email == "a@g.com")
        #expect(notifications[0].kind == .lowThreshold)
    }

    @Test func detectsReset() {
        let settings = AppSettings(primaryPool: "Claude and GPT models")
        let prev = AccountUsage.sample(email: "a@g.com", geminiRemaining: 1.0, claudeRemaining: 0.0)
        let curr = AccountUsage.sample(email: "a@g.com", geminiRemaining: 1.0, claudeRemaining: 1.0)

        let notifications = NotificationService.checkThresholds(
            previous: [prev], current: [curr], settings: settings
        )

        #expect(notifications.count == 1)
        #expect(notifications[0].kind == .reset)
    }

    @Test func noNotificationWhenAboveThreshold() {
        let settings = AppSettings(lowThresholdPercent: 10.0, primaryPool: "Claude and GPT models")
        let prev = AccountUsage.sample(email: "a@g.com", geminiRemaining: 1.0, claudeRemaining: 0.50)
        let curr = AccountUsage.sample(email: "a@g.com", geminiRemaining: 1.0, claudeRemaining: 0.40)

        let notifications = NotificationService.checkThresholds(
            previous: [prev], current: [curr], settings: settings
        )

        #expect(notifications.isEmpty)
    }

    @Test func alreadyBelowThreshold_doesNotTriggerAgain() {
        let settings = AppSettings(lowThresholdPercent: 10.0, primaryPool: "Claude and GPT models")
        let prev = AccountUsage.sample(email: "a@g.com", geminiRemaining: 1.0, claudeRemaining: 0.08)
        let curr = AccountUsage.sample(email: "a@g.com", geminiRemaining: 1.0, claudeRemaining: 0.05)

        let notifications = NotificationService.checkThresholds(
            previous: [prev], current: [curr], settings: settings
        )

        #expect(notifications.isEmpty)
    }

    @Test func accountNotInPrevious_doesNotTrigger() {
        let settings = AppSettings(lowThresholdPercent: 10.0, primaryPool: "Claude and GPT models")
        let curr = AccountUsage.sample(email: "a@g.com", geminiRemaining: 1.0, claudeRemaining: 0.05)

        let notifications = NotificationService.checkThresholds(
            previous: [], current: [curr], settings: settings
        )

        #expect(notifications.isEmpty)
    }

    @Test func resetNotTriggeredIfPreviousWasNotExhausted() {
        let settings = AppSettings(primaryPool: "Claude and GPT models")
        let prev = AccountUsage.sample(email: "a@g.com", geminiRemaining: 1.0, claudeRemaining: 0.20)
        let curr = AccountUsage.sample(email: "a@g.com", geminiRemaining: 1.0, claudeRemaining: 0.80)

        let notifications = NotificationService.checkThresholds(
            previous: [prev], current: [curr], settings: settings
        )

        #expect(notifications.isEmpty)
    }
}
