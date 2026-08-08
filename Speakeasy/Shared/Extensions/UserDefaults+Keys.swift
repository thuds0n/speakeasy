import Foundation

extension UserDefaults {
    enum Key {
        static let globalKey = "globalKey"
        static let numberOfSecondForAutoHide = "numberOfSecondForAutoHide"
        static let isAutoHide = "isAutoHide"
        static let isShowPreference = "isShowPreference"
        static let areSeparatorsHidden = "areSeparatorsHidden"
        static let alwaysHiddenSectionEnabled = "alwaysHiddenSectionEnabled"
        static let useFullStatusBarOnExpandEnabled = "useFullStatusBarOnExpandEnabled"

        // Legacy keys retained for one-time migration on read.
        enum Legacy {
            static let isShowPreference = "isShowPreferences"
        }
    }
}
