// Sources/QuotaBar/Views/SettingsView.swift
import SwiftUI
import AppKit
import QuotaBarCore

struct SettingsView: View {
    @ObservedObject var store: SettingsStore
    var onBack: () -> Void
    var onManageAccounts: () -> Void

    private let pollIntervalOptions = [60, 120, 300, 600, 900]
    private let poolOptions = ["Claude and GPT models", "Gemini Models"]

    var body: some View {
        VStack(spacing: 0) {
            // Navigation Bar
            HStack {
                Button {
                    onBack()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                }
                .buttonStyle(.borderless)

                Spacer()

                Text("Settings")
                    .font(.headline)

                Spacer()

                // Balance spacer for visual centering
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
                .opacity(0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Accounts Shortcut
                    Button {
                        onManageAccounts()
                    } label: {
                        HStack {
                            Image(systemName: "person.2.fill")
                                .foregroundStyle(.blue)
                            Text("Manage Google Accounts")
                                .font(.subheadline.weight(.medium))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(12)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                    Divider()
                        .padding(.horizontal, 16)

                    // Polling Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("REFRESH & POLLING")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)

                        Picker("Refresh Interval", selection: $store.settings.pollIntervalSeconds) {
                            ForEach(pollIntervalOptions, id: \.self) { seconds in
                                Text(seconds < 60 ? "\(seconds) seconds" : "\(seconds / 60) minutes")
                                    .tag(seconds)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    .padding(.horizontal, 16)

                    Divider()
                        .padding(.horizontal, 16)

                    // Display Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("DISPLAY OPTIONS")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)

                        Picker("Primary Pool", selection: $store.settings.primaryPool) {
                            ForEach(poolOptions, id: \.self) { pool in
                                Text(pool).tag(pool)
                            }
                        }
                        .pickerStyle(.menu)

                        Picker("Sort Order", selection: $store.settings.sortMode) {
                            ForEach(SortMode.allCases, id: \.self) { mode in
                                Text(mode.displayName).tag(mode)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    .padding(.horizontal, 16)

                    Divider()
                        .padding(.horizontal, 16)

                    // Notifications Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("NOTIFICATIONS")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)

                        HStack {
                            Text("Alert when quota drops below")
                                .font(.subheadline)
                            Spacer()
                            TextField("", value: $store.settings.lowThresholdPercent, format: .number)
                                .frame(width: 45)
                                .textFieldStyle(.roundedBorder)
                            Text("%")
                                .font(.subheadline)
                        }
                    }
                    .padding(.horizontal, 16)

                    Divider()
                        .padding(.horizontal, 16)

                    // System Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("SYSTEM")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)

                        Toggle("Launch at login", isOn: $store.settings.launchAtLogin)
                            .font(.subheadline)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
            }
        }
        .frame(width: 380, height: 500)
    }
}
