import Foundation
import Observation

@Observable
final class LanguageManager {
    private enum StorageKeys {
        static let selectedLanguageCode = "selected_language_code"
    }

    @ObservationIgnored private let userDefaults: UserDefaults

    private(set) var currentLanguage: AppLanguage
    private(set) var selectedLanguageCode: String?

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults

        let storedCode = userDefaults.string(forKey: StorageKeys.selectedLanguageCode)
        self.selectedLanguageCode = storedCode
        self.currentLanguage = AppLanguage(rawValue: storedCode ?? "") ?? AppLanguage.resolveSystemLanguage()
    }

    var locale: Locale {
        currentLanguage.locale
    }

    var followsSystemLanguage: Bool {
        selectedLanguageCode == nil
    }

    func setLanguage(_ language: AppLanguage) {
        selectedLanguageCode = language.rawValue
        currentLanguage = language
        userDefaults.set(language.rawValue, forKey: StorageKeys.selectedLanguageCode)
    }

    func useSystemLanguage() {
        selectedLanguageCode = nil
        currentLanguage = AppLanguage.resolveSystemLanguage()
        userDefaults.removeObject(forKey: StorageKeys.selectedLanguageCode)
    }

    func string(_ key: LocalizedTextKey, _ arguments: CVarArg...) -> String {
        let format = currentLanguage.localizationBundle.localizedString(
            forKey: key.rawValue,
            value: key.rawValue,
            table: "Localizable"
        )

        guard !arguments.isEmpty else {
            return format
        }

        return String(format: format, locale: locale, arguments: arguments)
    }
}
