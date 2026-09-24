// Sources/QuotaBar/Views/AccountCardView.swift
import SwiftUI
import QuotaBarCore

struct AccountCardView: View {
    let rank: Int
    let usage: AccountUsage
    let primaryPool: String
    let isExpanded: Bool
    let onToggle: () -> Void

    /// Persisted active account email — shared across all cards via @AppStorage
    @AppStorage("activeAntigravityEmail") private var activeEmail: String = ""

    private var orderedPools: [QuotaPool] {
        QuotaViewModel.orderedPools(for: usage, primaryPool: primaryPool)
    }

    private var primaryWeeklyRemaining: Double? {
        usage.pool(named: primaryPool)?.weekly?.remainingPercent
    }

    private var primary5hRemaining: Double? {
        usage.pool(named: primaryPool)?.fiveHour?.remainingPercent
    }

    private var isActive: Bool {
        activeEmail == usage.email
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

                    // Green dot for active account
                    if isActive {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                    }

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

                    // Mark as Active / Active badge
                    if isActive {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(.green)
                            Text("Active in Antigravity")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.green)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(Color.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
                    } else {
                        Button {
                            activeEmail = usage.email
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                Text("Mark as Active in Antigravity")
                            }
                            .font(.caption)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isActive && isExpanded ? Color.green.opacity(0.4) : (isExpanded ? Color.blue.opacity(0.3) : Color.primary.opacity(0.06)), lineWidth: 1)
        )
    }
}
