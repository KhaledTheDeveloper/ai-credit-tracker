// Tests/QuotaBarCoreTests/ViewModels/QuotaViewModelTests.swift
import Foundation
import SwiftUI
import Testing
@testable import QuotaBarCore

@Suite struct QuotaViewModelTests {

    @Test func sortedUsages_defaultsToSoonestReset() {
        let now = Date()
        let a = AccountUsage(
            email: "later@g.com",
            pools: [QuotaPool(displayName: "Claude and GPT models", buckets: [
                QuotaWindow(remainingFraction: 0.5, resetTime: now.addingTimeInterval(3600), window: "5h"),
                QuotaWindow(remainingFraction: 0.5, resetTime: now.addingTimeInterval(86400), window: "weekly"),
            ])],
            fetchedAt: now, isStale: false
        )
        let b = AccountUsage(
            email: "sooner@g.com",
            pools: [QuotaPool(displayName: "Claude and GPT models", buckets: [
                QuotaWindow(remainingFraction: 0.9, resetTime: now.addingTimeInterval(600), window: "5h"),
                QuotaWindow(remainingFraction: 0.9, resetTime: now.addingTimeInterval(86400), window: "weekly"),
            ])],
            fetchedAt: now, isStale: false
        )
        let settings = AppSettings()

        let sorted = QuotaViewModel.sortedUsages([a, b], settings: settings)

        #expect(sorted[0].email == "sooner@g.com")
        #expect(sorted[1].email == "later@g.com")
    }

    @Test func orderedPools_primaryPoolFirst() {
        let usage = AccountUsage.sample(email: "test@g.com", geminiRemaining: 1.0, claudeRemaining: 0.5)
        let ordered = QuotaViewModel.orderedPools(
            for: usage,
            primaryPool: "Claude and GPT models"
        )

        #expect(ordered.first?.displayName == "Claude and GPT models")
    }

    @Test func colorForPercent() {
        #expect(QuotaViewModel.quotaColor(percent: 75) == .green)
        #expect(QuotaViewModel.quotaColor(percent: 30) == .orange)
        #expect(QuotaViewModel.quotaColor(percent: 5) == .red)
        #expect(QuotaViewModel.quotaColor(percent: 0) == .red)
    }
}
