import Foundation

enum AppLanguage: String, CaseIterable, Identifiable, Codable {
    case english = "en"
    case ukrainian = "uk"

    var id: String { rawValue }

    var locale: Locale {
        Locale(identifier: rawValue)
    }

    var localizationBundle: Bundle {
        guard
            let path = Bundle.main.path(forResource: rawValue, ofType: "lproj"),
            let bundle = Bundle(path: path)
        else {
            return .main
        }

        return bundle
    }

    static func resolveSystemLanguage(
        preferredLanguages: [String] = Locale.preferredLanguages
    ) -> AppLanguage {
        for identifier in preferredLanguages {
            let lowercased = identifier.lowercased()
            if lowercased.hasPrefix(AppLanguage.ukrainian.rawValue) {
                return .ukrainian
            }
            if lowercased.hasPrefix(AppLanguage.english.rawValue) {
                return .english
            }
        }

        return .english
    }
}
