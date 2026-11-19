import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(SecurityManager.self) private var securityManager
    @Environment(ToastManager.self) private var toastManager

    var body: some View {
        ZStack {
            RootTabView()
                .allowsHitTesting(!securityManager.requiresUnlock)
                .accessibilityHidden(securityManager.requiresUnlock)

            // пока приложение заблокировано, показываем экран ввода пин-кода
            if securityManager.requiresUnlock {
                LockScreenView()
                    .transition(.opacity)
            }

            AppToastOverlay(toast: toastManager.toast)
                .allowsHitTesting(false)
                .zIndex(999)
        }
        .animation(.easeInOut(duration: 0.2), value: securityManager.requiresUnlock)
        .task {
            securityManager.lockIfNeededOnLaunch()
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .background:
                securityManager.sceneDidEnterBackground()
            case .active:
                securityManager.sceneDidBecomeActive()
            default:
                break
            }
        }
    }
}

#Preview {
    let languageManager = LanguageManager()
    let exchangeRateService = ExchangeRateService()
    let securityManager = SecurityManager()
    let toastManager = ToastManager()

    ContentView()
        .environment(languageManager)
        .environment(exchangeRateService)
        .environment(securityManager)
        .environment(toastManager)
        .environment(\.locale, languageManager.locale)
        .modelContainer(AppModelContainer.makePreviewContainer())
}
