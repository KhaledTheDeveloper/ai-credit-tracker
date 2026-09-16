// Sources/QuotaBarCore/ViewModels/QuotaViewModel.swift
import Foundation
import SwiftUI

public enum QuotaViewModel {

    public static func sortedUsages(
        _ usages: [AccountUsage],
        settings: AppSettings
    ) -> [AccountUsage] {
        let visible = usages.filter { !settings.hiddenAccounts.contains($0.email) }
        return SortingLogic.sorted(visible, mode: settings.sortMode, primaryPool: settings.primaryPool)
    }

    public static func orderedPools(
        for usage: AccountUsage,
        primaryPool: String
    ) -> [QuotaPool] {
        usage.pools.sorted { lhs, rhs in
            lhs.displayName == primaryPool && rhs.displayName != primaryPool
        }
    }

    public static func quotaColor(percent: Double) -> Color {
        if percent > 50 { return .green }
        if percent > 10 { return .orange }
        return .red
    }
}
