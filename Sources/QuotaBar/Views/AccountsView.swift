// Sources/QuotaBar/Views/AccountsView.swift
import SwiftUI
import AppKit
import QuotaBarCore

struct AccountsView: View {
    @ObservedObject var fetcher: UsageFetcher
    @ObservedObject var store: SettingsStore
    var onBack: () -> Void

    @State private var isLoggingIn = false
    @State private var loginMessage: String?

    private var visibleAccounts: [AccountUsage] {
        fetcher.usages.filter { !store.settings.hiddenAccounts.contains($0.email) }
    }

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

                Text("Google Accounts")
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
                    VStack(alignment: .leading, spacing: 8) {
                        Text("CONNECTED ACCOUNTS")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)

                        if visibleAccounts.isEmpty {
                            HStack {
                                Text("No accounts found.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Spacer()
                            }
                            .padding(12)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                        } else {
                            VStack(spacing: 6) {
                                ForEach(visibleAccounts) { usage in
                                    HStack(spacing: 8) {
                                        Image(systemName: "person.crop.circle.fill")
                                            .font(.title3)
                                            .foregroundStyle(.blue)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(usage.email)
                                                .font(.system(.subheadline, weight: .medium))
                                                .lineLimit(1)
                                                .truncationMode(.middle)
                                            Text("Last updated \(usage.fetchedAt.formatted(.relative(presentation: .named)))")
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }

                                        Spacer()

                                        if usage.isStale {
                                            Text("Offline")
                                                .font(.caption2.bold())
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color.orange.opacity(0.2), in: Capsule())
                                                .foregroundStyle(.orange)
                                        } else {
                                            Text("Active")
                                                .font(.caption2.bold())
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color.green.opacity(0.2), in: Capsule())
                                                .foregroundStyle(.green)
                                        }

                                        // Remove Account Button
                                        Button {
                                            removeAccount(usage.email)
                                        } label: {
                                            Image(systemName: "trash")
                                                .font(.system(size: 12))
                                                .foregroundStyle(.red.opacity(0.8))
                                        }
                                        .buttonStyle(.borderless)
                                        .help("Remove account from QuotaBar")
                                    }
                                    .padding(10)
                                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                                }
                            }
                        }

                        // Restore button if any accounts are hidden
                        if !store.settings.hiddenAccounts.isEmpty {
                            Button {
                                store.settings.hiddenAccounts.removeAll()
                                Task { await fetcher.fetchAll(isManual: true) }
                            } label: {
                                Text("Restore Hidden Accounts (\(store.settings.hiddenAccounts.count))")
                                    .font(.caption)
                                    .foregroundStyle(.blue)
                            }
                            .buttonStyle(.borderless)
                            .padding(.top, 2)
                        }

                        // Add account buttons
                        HStack(spacing: 10) {
                            Button {
                                startLoginFlow()
                            } label: {
                                HStack(spacing: 6) {
                                    if isLoggingIn {
                                        ProgressView()
                                            .controlSize(.small)
                                    } else {
                                        Image(systemName: "plus.circle.fill")
                                    }
                                    Text(isLoggingIn ? "Authenticating..." : "Add Account (Browser)")
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(isLoggingIn)

                            Button {
                                AccountManager.openTerminalLogin()
                            } label: {
                                Image(systemName: "terminal")
                                Text("Terminal")
                            }
                            .buttonStyle(.bordered)
                            .help("Open Terminal to add account via CLI")
                        }
                        .padding(.top, 8)

                        if let msg = loginMessage {
                            Text(msg)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .padding(.top, 2)
                        }

                        Text("Adds any Google account via OAuth. QuotaBar queries Google Cloud Code in the background even if the account is not logged into Antigravity locally.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .padding(.top, 4)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                }
            }
        }
        .frame(width: 380, height: 500)
    }

    private func removeAccount(_ email: String) {
        AccountManager.removeAccount(email: email)
        if !store.settings.hiddenAccounts.contains(email) {
            store.settings.hiddenAccounts.append(email)
        }
        Task {
            await fetcher.fetchAll(isManual: true)
        }
    }

    private func startLoginFlow() {
        isLoggingIn = true
        loginMessage = "Opening Google sign-in in browser..."
        AccountManager.startBrowserOAuthLogin { success in
            isLoggingIn = false
            if success {
                loginMessage = "Account added successfully! Refreshing..."
            } else {
                loginMessage = "Auth completed. Refreshing accounts..."
            }
            Task {
                await fetcher.fetchAll(isManual: true)
            }
        }
    }
}
