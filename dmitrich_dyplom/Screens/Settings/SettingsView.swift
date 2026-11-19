import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(LanguageManager.self) private var languageManager
    @Environment(ToastManager.self) private var toastManager
    @Environment(ExchangeRateService.self) private var exchangeRateService
    @AppStorage(AppCurrency.preferenceKey) private var currency: AppCurrency = .usd
    @Query private var settings: [AppSettings]

    @State private var morningRate = ""
    @State private var mainRate = ""
    @State private var nightRate = ""
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section(languageManager.string(L.settingsRatesTitle)) {
                    rateField(L.settingsRateMorning, text: $morningRate)
                    rateField(L.settingsRateMain, text: $mainRate)
                    rateField(L.settingsRateNight, text: $nightRate)

                    Button(languageManager.string(L.commonSave)) {
                        saveRates()
                    }
                    .disabled(settings.isEmpty)

                    if let errorMessage {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }

                currencySection

                Section {
                    NavigationLink(languageManager.string(L.securityTitle)) {
                        SecuritySettingsView()
                    }
                }

                Section(languageManager.string(L.settingsLanguageTitle)) {
                    ForEach(AppLanguage.allCases) { language in
                        Button(languageManager.string(language == .english ? L.settingsLanguageEnglish : L.settingsLanguageUkrainian)) {
                            languageManager.setLanguage(language)
                        }
                    }
                    Button(languageManager.string(L.settingsLanguageUseSystem)) {
                        languageManager.useSystemLanguage()
                    }
                }
            }
            .navigationTitle(languageManager.string(L.settingsTitle))
            .onChange(of: settings.first?.persistentModelID, initial: true) {
                loadRates()
            }
            .task {
                await exchangeRateService.refreshIfNeeded()
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }

    private var currencySection: some View {
        Section(languageManager.string(L.settingsExchangeRateTitle)) {
            Picker(languageManager.string(L.settingsCurrencyTitle), selection: $currency) {
                ForEach(AppCurrency.allCases) { option in
                    Text(languageManager.string(option.localizationKey)).tag(option)
                }
            }

            exchangeRateRow(L.settingsUSDExchangeRate, exchangeRateService.rates.usdToUahRate)
            exchangeRateRow(L.settingsEURExchangeRate, exchangeRateService.rates.eurToUahRate)
            if let date = exchangeRateService.rates.exchangeRateDate {
                LabeledContent(languageManager.string(L.settingsExchangeRateDate), value: date)
            }

            if exchangeRateService.isLoading {
                ProgressView()
            }

            if exchangeRateService.lastError != nil {
                Text(languageManager.string(L.settingsExchangeRateFailure))
                    .foregroundStyle(.orange)
            }

            switch exchangeRateService.rates.source {
            case .api:
                EmptyView()
            case .cache:
                Text(languageManager.string(L.settingsExchangeRateUsingSaved))
                    .foregroundStyle(.secondary)
            case .fallback:
                Text(languageManager.string(L.settingsExchangeRateUsingDefault))
                    .foregroundStyle(.secondary)
            }

            Button(languageManager.string(L.settingsRefreshExchangeRate)) {
                Task {
                    await exchangeRateService.refresh()
                }
            }
            .disabled(exchangeRateService.isLoading)
        }
    }

    private func exchangeRateRow(_ title: LocalizedTextKey, _ amount: Decimal) -> some View {
        LabeledContent(
            languageManager.string(title),
            value: Formatters.currency(amount, currency: .uah, locale: languageManager.locale)
        )
    }

    private func rateField(_ title: LocalizedTextKey, text: Binding<String>) -> some View {
        TextField(languageManager.string(title), text: text)
            .keyboardType(.decimalPad)
    }

    private func loadRates() {
        guard let value = settings.first else { return }
        morningRate = value.morningHourlyRate.description
        mainRate = value.mainHourlyRate.description
        nightRate = value.nightHourlyRate.description
    }

    private func saveRates() {
        guard let value = settings.first,
              let morning = parseRate(morningRate),
              let main = parseRate(mainRate),
              let night = parseRate(nightRate) else {
            errorMessage = languageManager.string(L.settingsSaveFailure)
            return
        }

        value.morningHourlyRate = morning
        value.mainHourlyRate = main
        value.nightHourlyRate = night

        do {
            try modelContext.save()
            errorMessage = nil
            toastManager.show(AppToast(message: languageManager.string(L.settingsSaveSuccess), kind: .success))
        } catch {
            modelContext.rollback()
            errorMessage = languageManager.string(L.settingsSaveFailure)
        }
    }

    private func parseRate(_ text: String) -> Decimal? {
        let input = text.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ",", with: ".")
        guard input.range(of: #"^[0-9]+(?:\.[0-9]+)?$"#, options: .regularExpression) != nil else { return nil }
        return Decimal(string: input, locale: Locale(identifier: "en_US_POSIX"))
    }
}
