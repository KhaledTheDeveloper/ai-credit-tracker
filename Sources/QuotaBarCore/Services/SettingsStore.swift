// Sources/QuotaBarCore/Services/SettingsStore.swift
import Foundation
import Combine

public final class SettingsStore: ObservableObject {

    private static let key = "QuotaBarSettings"
    private let defaults: UserDefaults

    @Published public var settings: AppSettings {
        didSet { save() }
    }

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: Self.key),
           let decoded = try? JSONDecoder().decode(AppSettings.self, from: data) {
            self.settings = decoded
        } else {
            self.settings = AppSettings()
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(settings) {
            defaults.set(data, forKey: Self.key)
        }
    }
}
