import Combine
import Foundation

@MainActor
final class SettingsStore: ObservableObject {
    @Published var globalKey: GlobalKeybindPreferences?
    @Published var isAutoStart: Bool
    @Published var isShowPreference: Bool
    @Published var isAutoHide: Bool
    @Published var autoHideDuration: Double
    @Published var areSeparatorsHidden: Bool
    @Published var alwaysHiddenSectionEnabled: Bool
    @Published var useFullStatusBarOnExpandEnabled: Bool

    private let userDefaults: UserDefaults
    private var cancellables = Set<AnyCancellable>()

    init(
        userDefaults: UserDefaults = .standard,
        persistentDomainName: String? = Bundle.main.bundleIdentifier
    ) {
        self.userDefaults = userDefaults

        Self.migrateLegacyKeys(in: userDefaults, persistentDomainName: persistentDomainName)

        userDefaults.register(defaults: [
            UserDefaults.Key.isAutoStart: false,
            UserDefaults.Key.isShowPreference: true,
            UserDefaults.Key.isAutoHide: true,
            UserDefaults.Key.numberOfSecondForAutoHide: 10.0,
            UserDefaults.Key.areSeparatorsHidden: false,
            UserDefaults.Key.alwaysHiddenSectionEnabled: false,
            UserDefaults.Key.useFullStatusBarOnExpandEnabled: false,
        ])

        globalKey = Self.decodeGlobalKey(from: userDefaults)
        isAutoStart = userDefaults.bool(forKey: UserDefaults.Key.isAutoStart)
        isShowPreference = userDefaults.bool(forKey: UserDefaults.Key.isShowPreference)
        isAutoHide = userDefaults.bool(forKey: UserDefaults.Key.isAutoHide)
        autoHideDuration = userDefaults.double(forKey: UserDefaults.Key.numberOfSecondForAutoHide)
        areSeparatorsHidden = userDefaults.bool(forKey: UserDefaults.Key.areSeparatorsHidden)
        alwaysHiddenSectionEnabled = userDefaults.bool(forKey: UserDefaults.Key.alwaysHiddenSectionEnabled)
        useFullStatusBarOnExpandEnabled = userDefaults.bool(forKey: UserDefaults.Key.useFullStatusBarOnExpandEnabled)

        bindPersistence()
    }

    /// Move values written under legacy keys to their current names. Runs once per launch;
    /// harmless no-op after the first run because the legacy key is removed.
    private static func migrateLegacyKeys(
        in userDefaults: UserDefaults,
        persistentDomainName: String?
    ) {
        let hasPersistedCurrentValue = persistentDomainName
            .flatMap { userDefaults.persistentDomain(forName: $0) }?[UserDefaults.Key.isShowPreference] != nil

        if !hasPersistedCurrentValue,
           let legacy = userDefaults.object(forKey: UserDefaults.Key.Legacy.isShowPreference) {
            userDefaults.set(legacy, forKey: UserDefaults.Key.isShowPreference)
        }
        userDefaults.removeObject(forKey: UserDefaults.Key.Legacy.isShowPreference)
    }

    private func bindPersistence() {
        $globalKey
            .dropFirst()
            .sink { [weak self] in self?.persistGlobalKey($0) }
            .store(in: &cancellables)

        persist($isAutoStart, to: UserDefaults.Key.isAutoStart)
        persist($isShowPreference, to: UserDefaults.Key.isShowPreference)
        persist($isAutoHide, to: UserDefaults.Key.isAutoHide)
        persist($autoHideDuration, to: UserDefaults.Key.numberOfSecondForAutoHide)
        persist($areSeparatorsHidden, to: UserDefaults.Key.areSeparatorsHidden)
        persist($alwaysHiddenSectionEnabled, to: UserDefaults.Key.alwaysHiddenSectionEnabled)
        persist($useFullStatusBarOnExpandEnabled, to: UserDefaults.Key.useFullStatusBarOnExpandEnabled)
    }

    private func persist<T: Equatable>(_ publisher: Published<T>.Publisher, to key: String) {
        publisher
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] in self?.userDefaults.set($0, forKey: key) }
            .store(in: &cancellables)
    }

    private func persistGlobalKey(_ shortcut: GlobalKeybindPreferences?) {
        guard let shortcut else {
            userDefaults.removeObject(forKey: UserDefaults.Key.globalKey)
            return
        }

        if let data = try? JSONEncoder().encode(shortcut) {
            userDefaults.set(data, forKey: UserDefaults.Key.globalKey)
        }
    }

    private static func decodeGlobalKey(from userDefaults: UserDefaults) -> GlobalKeybindPreferences? {
        guard let data = userDefaults.value(forKey: UserDefaults.Key.globalKey) as? Data else {
            return nil
        }

        return try? JSONDecoder().decode(GlobalKeybindPreferences.self, from: data)
    }
}
