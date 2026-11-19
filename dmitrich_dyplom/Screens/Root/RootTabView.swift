import SwiftData
import SwiftUI

struct RootTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(LanguageManager.self) private var languageManager

    private let bootstrapService = SettingsBootstrapService()
    private let isRunningInPreview = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"

    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label(languageManager.string(L.tabDashboard), systemImage: "square.grid.2x2")
                }

            EmployeesView()
                .tabItem {
                    Label(languageManager.string(L.tabEmployees), systemImage: "person.2")
                }

            ShiftsView()
                .tabItem {
                    Label(languageManager.string(L.tabShifts), systemImage: "clock")
                }

            SettingsView()
                .tabItem {
                    Label(languageManager.string(L.tabSettings), systemImage: "gearshape")
                }
        }
        .tint(AppUI.Colors.accent)
        .dismissKeyboardOnTap()
        .task {
            guard !isRunningInPreview else { return }
            try? bootstrapService.bootstrapIfNeeded(in: modelContext)
        }
    }
}
