// Sources/QuotaBarCore/ViewModels/SortingLogic.swift
import Foundation

public enum SortingLogic: Sendable {

    public static func sorted(
        _ usages: [AccountUsage],
        mode: SortMode,
        primaryPool: String
    ) -> [AccountUsage] {
        switch mode {
        case .soonestReset:
            return usages.sorted { lhs, rhs in
                let aPool = lhs.pool(named: primaryPool)
                let bPool = rhs.pool(named: primaryPool)

                if (aPool == nil) != (bPool == nil) {
                    return aPool != nil
                }

                // 1. Weekly quota remaining: most weekly quota left comes first
                let aWeekly = aPool?.weekly?.remainingFraction ?? 0
                let bWeekly = bPool?.weekly?.remainingFraction ?? 0
                if abs(aWeekly - bWeekly) > 0.0001 {
                    return aWeekly > bWeekly
                }

                // If both weekly quotas are exhausted (0%), the true reset is the weekly reset
                if aWeekly <= 0.0001 && bWeekly <= 0.0001 {
                    let aWeeklyReset = aPool?.weekly?.resetTime ?? .distantFuture
                    let bWeeklyReset = bPool?.weekly?.resetTime ?? .distantFuture
                    if aWeeklyReset != bWeeklyReset {
                        return aWeeklyReset < bWeeklyReset
                    }
                }

                // 2. Tie-breaker: 5-hour quota that resets the soonest
                let a5hReset = aPool?.fiveHour?.resetTime ?? .distantFuture
                let b5hReset = bPool?.fiveHour?.resetTime ?? .distantFuture
                if a5hReset != b5hReset {
                    return a5hReset < b5hReset
                }

                return lhs.email < rhs.email
            }
        case .remainingFirst:
            return usages.sorted { lhs, rhs in
                let aPool = lhs.pool(named: primaryPool)
                let bPool = rhs.pool(named: primaryPool)

                if (aPool == nil) != (bPool == nil) {
                    return aPool != nil
                }

                // 1. Weekly quota remaining
                let aWeekly = aPool?.weekly?.remainingFraction ?? 0
                let bWeekly = bPool?.weekly?.remainingFraction ?? 0
                if abs(aWeekly - bWeekly) > 0.0001 {
                    return aWeekly > bWeekly
                }

                // If both weekly quotas are exhausted, rank by soonest weekly reset
                if aWeekly <= 0.0001 && bWeekly <= 0.0001 {
                    let aWeeklyReset = aPool?.weekly?.resetTime ?? .distantFuture
                    let bWeeklyReset = bPool?.weekly?.resetTime ?? .distantFuture
                    if aWeeklyReset != bWeeklyReset {
                        return aWeeklyReset < bWeeklyReset
                    }
                }

                // 2. 5-hour quota remaining
                let a5h = aPool?.fiveHour?.remainingFraction ?? 0
                let b5h = bPool?.fiveHour?.remainingFraction ?? 0
                if abs(a5h - b5h) > 0.0001 {
                    return a5h > b5h
                }

                // 3. Soonest 5-hour reset
                let aReset = aPool?.fiveHour?.resetTime ?? .distantFuture
                let bReset = bPool?.fiveHour?.resetTime ?? .distantFuture
                if aReset != bReset {
                    return aReset < bReset
                }

                return lhs.email < rhs.email
            }
        case .alphabetical:
            return usages.sorted { $0.email < $1.email }
        }
    }
}
