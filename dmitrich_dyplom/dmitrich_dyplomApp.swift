import SwiftUI
import SwiftData

@main
struct dmitrich_dyplomApp: App {
    private let modelContainer = AppModelContainer.makeContainer()
    @State private var languageManager = LanguageManager()
    @State private var exchangeRateService = ExchangeRateService()
    @State private var securityManager = SecurityManager()
    @State private var toastManager = ToastManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(languageManager)
                .environment(exchangeRateService)
                .environment(securityManager)
                .environment(toastManager)
                .environment(\.locale, languageManager.locale)
                .task {
                    await exchangeRateService.refreshIfNeeded()
                }
        }
        .modelContainer(modelContainer)
    }
}
