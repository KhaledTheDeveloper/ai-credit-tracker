// Sources/QuotaBar/Views/MenuBarContentView.swift
import SwiftUI
import AppKit
import QuotaBarCore

enum ActiveScreen {
    case cards
    case accounts
    case settings
}

struct MenuBarContentView: View {
    @ObservedObject var fetcher: UsageFetcher
    @ObservedObject var settingsStore: SettingsStore
    @State private var activeScreen: ActiveScreen = .cards
    @State private var expandedEmail: String? = nil

    private var sortedUsages: [AccountUsage] {
        QuotaViewModel.sortedUsages(fetcher.usages, settings: settingsStore.settings)
    }

    var body: some View {
        Group {
            switch activeScreen {
            case .accounts:
                AccountsView(
                    fetcher: fetcher,
                    store: settingsStore,
                    onBack: { activeScreen = .cards }
                )
            case .settings:
                SettingsView(
                    store: settingsStore,
                    onBack: { activeScreen = .cards },
                    onManageAccounts: { activeScreen = .accounts }
                )
            case .cards:
                mainContentView
            }
        }
        .frame(width: 380, height: 500)
    }

    private var mainContentView: some View {
        VStack(spacing: 8) {
            // Top Bar
            HStack(spacing: 12) {
                Text("QuotaBar")
                    .font(.headline)
                
                Spacer()

                Button {
                    activeScreen = .accounts
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .semibold))
                }
                .buttonStyle(.borderless)
                .help("Add or manage Google Accounts")

                Button {
                    Task { await fetcher.fetchAll(isManual: true) }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .rotationEffect(.degrees(fetcher.isFetching ? 360 : 0))
                        .animation(fetcher.isFetching ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: fetcher.isFetching)
                }
                .buttonStyle(.borderless)
                .disabled(fetcher.isFetching)
                .help("Refresh Quota Status")
            }
            .padding(.horizontal, 14)
            .padding(.top, 10)

            // Content Area
            if sortedUsages.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                    
                    Text("No Google accounts connected")
                        .font(.subheadline.weight(.medium))

                    Text("Click below to connect your Google accounts and track your quota live.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)

                    Button("Add Google Account") {
                        activeScreen = .accounts
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(Array(sortedUsages.enumerated()), id: \.element.id) { index, usage in
                            AccountCardView(
                                rank: index + 1,
                                usage: usage,
                                primaryPool: settingsStore.settings.primaryPool,
                                isExpanded: expandedEmail == usage.email,
                                onToggle: {
                                    if expandedEmail == usage.email {
                                        expandedEmail = nil
                                    } else {
                                        expandedEmail = usage.email
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.top, 4)
                }
            }

            if let error = fetcher.lastError {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    Text(error)
                        .font(.caption2)
                        .foregroundStyle(.red)
                        .lineLimit(2)
                    Spacer()
                }
                .padding(.horizontal, 12)
            }

            Divider()

            // Footer
            HStack {
                Button("Settings…") {
                    activeScreen = .settings
                }
                .buttonStyle(.borderless)

                Spacer()

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.borderless)
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 10)
        }
    }
}
