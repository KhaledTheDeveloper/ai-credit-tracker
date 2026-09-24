// Sources/QuotaBar/Views/AccountCardView.swift
import SwiftUI
import QuotaBarCore

private enum SwitchStatus: Equatable {
    case idle
    case switching
    case success
    case failed(String)
}

struct AccountCardView: View {
    let rank: Int
    let usage: AccountUsage
    let primaryPool: String
    let isExpanded: Bool
    let onToggle: () -> Void
    @State private var switchStatus: SwitchStatus = .idle

    private var orderedPools: [QuotaPool] {
        QuotaViewModel.orderedPools(for: usage, primaryPool: primaryPool)
    }

    private var primaryWeeklyRemaining: Double? {
        usage.pool(named: primaryPool)?.weekly?.remainingPercent
    }

    private var primary5hRemaining: Double? {
        usage.pool(named: primaryPool)?.fiveHour?.remainingPercent
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header Row (Clickable Accordion Bar)
            Button {
                withAnimation(.easeInOut(duration: 0.22)) {
                    onToggle()
                }
            } label: {
                HStack(spacing: 8) {
                    // Serial / Number Badge
                    Text("#\(rank)")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(rank == 1 ? Color.blue : Color.secondary.opacity(0.6), in: Capsule())

                    // Email address
                    Text(usage.email)
                        .font(.system(.subheadline, weight: .medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .truncationMode(.middle)

                    Spacer()

                    // Quick Quota Pill (Shown when collapsed)
                    if let weekly = primaryWeeklyRemaining {
                        HStack(spacing: 4) {
                            Text("Claude:")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.secondary)
                            Text("\(Int(weekly))%")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundStyle(QuotaViewModel.quotaColor(percent: weekly))
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 4))
                    }

                    if usage.isStale {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                            .font(.caption2)
                    }

                    // Dropdown Arrow
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Expanded Details
            if isExpanded {
                Divider()
                    .padding(.horizontal, 12)

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(orderedPools) { pool in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(pool.displayName)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)

                            if let weekly = pool.weekly {
                                QuotaBarRow(
                                    label: "Weekly",
                                    window: weekly,
                                    isSuppressed: false
                                )
                            }

                            if let fiveHour = pool.fiveHour {
                                QuotaBarRow(
                                    label: "5-hour",
                                    window: fiveHour,
                                    isSuppressed: pool.weeklySupersedes5h
                                )
                            }
                        }
                    }

                    HStack {
                        Text("Updated \(usage.fetchedAt.formatted(.relative(presentation: .named)))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(.top, 2)

                    // Switch Antigravity button
                    Button {
                        switchStatus = .switching
                        AccountSwitcher.switchAccount(email: usage.email) { success, message in
                            switchStatus = success ? .success : .failed(message)
                            if success {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                    switchStatus = .idle
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            switch switchStatus {
                            case .idle:
                                Image(systemName: "arrow.triangle.2.circlepath")
                                Text("Switch Antigravity to this account")
                            case .switching:
                                ProgressView()
                                    .controlSize(.mini)
                                Text("Switching…")
                            case .success:
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                Text("Switched!")
                            case .failed(let msg):
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.red)
                                Text(msg)
                                    .lineLimit(1)
                            }
                        }
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .disabled(switchStatus == .switching)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isExpanded ? Color.blue.opacity(0.3) : Color.primary.opacity(0.06), lineWidth: 1)
        )
    }
}
