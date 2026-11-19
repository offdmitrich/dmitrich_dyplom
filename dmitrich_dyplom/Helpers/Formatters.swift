import Foundation

enum Formatters {
    static func currency(_ value: Decimal, currency: AppCurrency = .usd, locale: Locale) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = locale
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2

        let amount = formatter.string(from: NSDecimalNumber(decimal: value)) ?? "0.00"
        return "\(amount) \(currency.currencyCode)"
    }

    static func convertedCurrencyFromUSD(
        _ value: Decimal,
        currency: AppCurrency,
        exchangeRates: ExchangeRateService,
        locale: Locale
    ) -> String {
        let converted = exchangeRates.convertedFromUSD(value, to: currency)
        return Self.currency(converted, currency: currency, locale: locale)
    }

    static func decimal(_ value: Decimal, locale: Locale, maximumFractionDigits: Int = 2) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = locale
        formatter.maximumFractionDigits = maximumFractionDigits
        formatter.minimumFractionDigits = 0
        return formatter.string(from: NSDecimalNumber(decimal: value)) ?? "0"
    }

    static func duration(seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, remainingSeconds)
    }
}
