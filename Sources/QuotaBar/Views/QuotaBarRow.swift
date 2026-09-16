// Sources/QuotaBar/Views/QuotaBarRow.swift
import SwiftUI
import QuotaBarCore

struct QuotaBarRow: View {
    let label: String
    let window: QuotaWindow
    let isSuppressed: Bool

    var body: some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 50, alignment: .leading)

            if isSuppressed {
                Text("Weekly limit hit")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                ProgressView(value: window.remainingFraction)
                    .tint(QuotaViewModel.quotaColor(percent: window.remainingPercent))
                    .frame(maxWidth: .infinity)

                Text("\(Int(window.remainingPercent))%")
                    .font(.caption.monospacedDigit())
                    .frame(width: 36, alignment: .trailing)

                Text("resets \(CountdownFormatter.string(from: window.resetTime))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(width: 70, alignment: .trailing)
            }
        }
    }
}
