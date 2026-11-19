import Foundation
import Observation

struct NBUExchangeRate: Decodable {
    let r030: Int
    let txt: String
    let rate: Decimal
    let cc: String
    let exchangedate: String
}

struct ExchangeRates: Codable, Equatable {
    static let fallback = ExchangeRates(
        usdToUahRate: Decimal(string: "40.0") ?? 40,
        eurToUahRate: Decimal(string: "43.5") ?? 43.5,
        exchangeRateDate: nil,
        lastUpdatedAt: nil,
        source: .fallback
    )

    enum Source: String, Codable {
        case api
        case cache
        case fallback
    }

    var usdToUahRate: Decimal
    var eurToUahRate: Decimal
    var exchangeRateDate: String?
    var lastUpdatedAt: Date?
    var source: Source
}

enum ExchangeRateServiceError: Error {
    case missingRates
}

@Observable
final class ExchangeRateService {
    private enum StorageKeys {
        static let exchangeRates = "exchange_rates_cache"
    }

    @ObservationIgnored private let userDefaults: UserDefaults
    @ObservationIgnored private let session: URLSession
    @ObservationIgnored private let cacheFreshInterval: TimeInterval = 4 * 60 * 60
    @ObservationIgnored private let endpoint = URL(string: "https://bank.gov.ua/NBUStatService/v1/statdirectory/exchange?json")

    private(set) var rates: ExchangeRates
    private(set) var isLoading = false
    private(set) var lastError: String?

    init(userDefaults: UserDefaults = .standard, session: URLSession = .shared) {
        self.userDefaults = userDefaults
        self.session = session
        self.rates = Self.loadCachedRates(from: userDefaults) ?? .fallback
    }

    func refreshIfNeeded() async {
        guard shouldRefresh else { return }
        await refresh()
    }

    func refresh() async {
        guard !isLoading else { return }

        isLoading = true
        lastError = nil
        defer { isLoading = false }

        do {
            guard let endpoint else {
                throw ExchangeRateServiceError.missingRates
            }

            let (data, response) = try await session.data(from: endpoint)
            if let httpResponse = response as? HTTPURLResponse,
               !(200...299).contains(httpResponse.statusCode) {
                throw URLError(.badServerResponse)
            }

            let nbuRates = try JSONDecoder().decode([NBUExchangeRate].self, from: data)
            guard let usd = nbuRates.first(where: { $0.cc.uppercased() == AppCurrency.usd.currencyCode }),
                  let eur = nbuRates.first(where: { $0.cc.uppercased() == AppCurrency.eur.currencyCode }) else {
                throw ExchangeRateServiceError.missingRates
            }

            rates = ExchangeRates(
                usdToUahRate: usd.rate,
                eurToUahRate: eur.rate,
                exchangeRateDate: usd.exchangedate,
                lastUpdatedAt: .now,
                source: .api
            )
            saveRatesToCache()
        } catch {
            // если банк не ответил, берём последний сохранённый курс
            lastError = error.localizedDescription
            rates = Self.loadCachedRates(from: userDefaults) ?? .fallback
        }
    }

    func convertedFromUSD(_ amount: Decimal, to currency: AppCurrency) -> Decimal {
        switch currency {
        case .usd:
            return amount
        case .uah:
            return amount * rates.usdToUahRate
        case .eur:
            guard rates.eurToUahRate > .zero else { return amount * (Decimal(string: "0.92") ?? 0.92) }
            return amount * rates.usdToUahRate / rates.eurToUahRate
        }
    }

    private var shouldRefresh: Bool {
        guard !isLoading else { return false }
        guard let lastUpdatedAt = rates.lastUpdatedAt else { return true }
        return Date().timeIntervalSince(lastUpdatedAt) > cacheFreshInterval
    }

    private func saveRatesToCache() {
        guard let data = try? JSONEncoder().encode(rates) else { return }
        userDefaults.set(data, forKey: StorageKeys.exchangeRates)
    }

    private static func loadCachedRates(from userDefaults: UserDefaults) -> ExchangeRates? {
        guard let data = userDefaults.data(forKey: StorageKeys.exchangeRates),
              var cachedRates = try? JSONDecoder().decode(ExchangeRates.self, from: data) else {
            return nil
        }

        cachedRates.source = .cache
        return cachedRates
    }
}
