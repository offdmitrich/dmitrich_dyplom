import Foundation

enum AppCurrency: String, CaseIterable, Identifiable, Codable {
    case usd = "usd"
    case uah = "uah"
    case eur = "eur"

    var id: String { rawValue }

    static let preferenceKey = "display_currency"

    var currencyCode: String { rawValue.uppercased() }

    var localizationKey: LocalizedTextKey {
        switch self {
        case .usd:
            return L.settingsCurrencyUSD
        case .uah:
            return L.settingsCurrencyUAH
        case .eur:
            return L.settingsCurrencyEUR
        }
    }
}
