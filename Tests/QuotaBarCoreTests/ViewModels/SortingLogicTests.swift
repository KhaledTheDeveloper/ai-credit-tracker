// Tests/QuotaBarCoreTests/ViewModels/SortingLogicTests.swift
import Foundation
import Testing
@testable import QuotaBarCore

@Suite struct SortingLogicTests {

    let primaryPool = "Claude and GPT models"

    @Test func remainingFirst_highestHeadroomOnTop() {
        let a = AccountUsage.sample(email: "low@g.com", geminiRemaining: 1.0, claudeRemaining: 0.1)
        let b = AccountUsage.sample(email: "high@g.com", geminiRemaining: 1.0, claudeRemaining: 0.9)
        let c = AccountUsage.sample(email: "mid@g.com", geminiRemaining: 1.0, claudeRemaining: 0.5)

        let sorted = SortingLogic.sorted([a, b, c], mode: .remainingFirst, primaryPool: primaryPool)

        #expect(sorted.map(\.email) == ["high@g.com", "mid@g.com", "low@g.com"])
    }

    @Test func remainingFirst_exhaustedSinkToBottom_sortedBySoonestReset() {
        let now = Date()
        let exhaustedSoon = AccountUsage(
            email: "soon@g.com",
            pools: [
                QuotaPool(displayName: "Claude and GPT models", buckets: [
                    QuotaWindow(remainingFraction: 0.0, resetTime: now.addingTimeInterval(600), window: "5h"),
                    QuotaWindow(remainingFraction: 0.0, resetTime: now.addingTimeInterval(3600), window: "weekly"),
                ]),
            ],
            fetchedAt: now, isStale: false
        )
        let exhaustedLater = AccountUsage(
            email: "later@g.com",
            pools: [
                QuotaPool(displayName: "Claude and GPT models", buckets: [
                    QuotaWindow(remainingFraction: 0.0, resetTime: now.addingTimeInterval(1800), window: "5h"),
                    QuotaWindow(remainingFraction: 0.0, resetTime: now.addingTimeInterval(7200), window: "weekly"),
                ]),
            ],
            fetchedAt: now, isStale: false
        )
        let hasHeadroom = AccountUsage.sample(email: "good@g.com", geminiRemaining: 1.0, claudeRemaining: 0.5)

        let sorted = SortingLogic.sorted(
            [exhaustedLater, hasHeadroom, exhaustedSoon],
            mode: .remainingFirst, primaryPool: primaryPool
        )

        #expect(sorted[0].email == "good@g.com")
        #expect(sorted[1].email == "soon@g.com")
        #expect(sorted[2].email == "later@g.com")
    }

    @Test func exhaustedWeekly_sortedBySoonestWeeklyReset_evenIf5hDiffers() {
        let now = Date()
        // Account A has 5h reset in 100s, but weekly reset in 5 days (432000s)
        let a = AccountUsage(
            email: "a_far_weekly@g.com",
            pools: [
                QuotaPool(displayName: "Claude and GPT models", buckets: [
                    QuotaWindow(remainingFraction: 0.0, resetTime: now.addingTimeInterval(100), window: "5h"),
                    QuotaWindow(remainingFraction: 0.0, resetTime: now.addingTimeInterval(432000), window: "weekly"),
                ]),
            ],
            fetchedAt: now, isStale: false
        )
        // Account B has 5h reset in 500s, but weekly reset in 1 day (86400s)
        let b = AccountUsage(
            email: "b_near_weekly@g.com",
            pools: [
                QuotaPool(displayName: "Claude and GPT models", buckets: [
                    QuotaWindow(remainingFraction: 0.0, resetTime: now.addingTimeInterval(500), window: "5h"),
                    QuotaWindow(remainingFraction: 0.0, resetTime: now.addingTimeInterval(86400), window: "weekly"),
                ]),
            ],
            fetchedAt: now, isStale: false
        )

        let sortedSoonest = SortingLogic.sorted([a, b], mode: .soonestReset, primaryPool: primaryPool)
        #expect(sortedSoonest.map(\.email) == ["b_near_weekly@g.com", "a_far_weekly@g.com"])

        let sortedRemaining = SortingLogic.sorted([a, b], mode: .remainingFirst, primaryPool: primaryPool)
        #expect(sortedRemaining.map(\.email) == ["b_near_weekly@g.com", "a_far_weekly@g.com"])
    }

    @Test func alphabetical() {
        let a = AccountUsage.sample(email: "charlie@g.com", geminiRemaining: 0.1, claudeRemaining: 0.1)
        let b = AccountUsage.sample(email: "alice@g.com", geminiRemaining: 0.9, claudeRemaining: 0.9)
        let c = AccountUsage.sample(email: "bob@g.com", geminiRemaining: 0.5, claudeRemaining: 0.5)

        let sorted = SortingLogic.sorted([a, b, c], mode: .alphabetical, primaryPool: primaryPool)

        #expect(sorted.map(\.email) == ["alice@g.com", "bob@g.com", "charlie@g.com"])
    }

    @Test func soonestReset() {
        let now = Date()
        let a = AccountUsage(
            email: "a@g.com",
            pools: [QuotaPool(displayName: "Claude and GPT models", buckets: [
                QuotaWindow(remainingFraction: 0.5, resetTime: now.addingTimeInterval(3600), window: "5h"),
                QuotaWindow(remainingFraction: 0.5, resetTime: now.addingTimeInterval(86400), window: "weekly"),
            ])],
            fetchedAt: now, isStale: false
        )
        let b = AccountUsage(
            email: "b@g.com",
            pools: [QuotaPool(displayName: "Claude and GPT models", buckets: [
                QuotaWindow(remainingFraction: 0.5, resetTime: now.addingTimeInterval(600), window: "5h"),
                QuotaWindow(remainingFraction: 0.5, resetTime: now.addingTimeInterval(86400), window: "weekly"),
            ])],
            fetchedAt: now, isStale: false
        )

        let sorted = SortingLogic.sorted([a, b], mode: .soonestReset, primaryPool: primaryPool)

        #expect(sorted[0].email == "b@g.com")
    }

    @Test func missingPrimaryPool_fallsToEnd() {
        let now = Date()
        let normal = AccountUsage(
            email: "normal@g.com",
            pools: [QuotaPool(displayName: "Claude and GPT models", buckets: [
                QuotaWindow(remainingFraction: 0.2, resetTime: now.addingTimeInterval(1200), window: "5h")
            ])],
            fetchedAt: now, isStale: false
        )
        let missingPool = AccountUsage(
            email: "missing@g.com",
            pools: [QuotaPool(displayName: "Other Pool", buckets: [
                QuotaWindow(remainingFraction: 0.9, resetTime: now.addingTimeInterval(300), window: "5h")
            ])],
            fetchedAt: now, isStale: false
        )

        let sortedRemaining = SortingLogic.sorted([missingPool, normal], mode: .remainingFirst, primaryPool: primaryPool)
        #expect(sortedRemaining.map(\.email) == ["normal@g.com", "missing@g.com"])

        let sortedReset = SortingLogic.sorted([missingPool, normal], mode: .soonestReset, primaryPool: primaryPool)
        #expect(sortedReset.map(\.email) == ["normal@g.com", "missing@g.com"])
    }
}
