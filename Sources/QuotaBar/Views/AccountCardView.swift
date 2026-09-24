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

    private var isActiveInAntigravity: Bool {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let jetskiPath = home.appendingPathComponent(".gemini/jetski-standalone-oauth-token")
        guard let data = try? Data(contentsOf: jetskiPath),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let idToken = json["id_token"] as? String else {
            return false
        }
        // Decode JWT payload (second segment)
        let parts = idToken.split(separator: ".")
        guard parts.count >= 2 else { return false }
        var base64 = String(parts[1])
        // Pad for base64url
        while base64.count % 4 != 0 { base64.append("=") }
        base64 = base64.replacingOccurrences(of: "-", with: "+")
                       .replacingOccurrences(of: "_", with: "/")
        guard let payloadData = Data(base64Encoded: base64),
              let payload = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any],
              let email = payload["email"] as? String else {
            return false
        }
        return email == usage.email
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
                    if isActiveInAntigravity {
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
                            switchStatus = .switching
                            AccountSwitcher.switchAccount(email: usage.email) { success, message in
                                switchStatus = success ? .success : .failed(message)
                                if success {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
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
                                    Text("Switched! Restart Antigravity to apply.")
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
