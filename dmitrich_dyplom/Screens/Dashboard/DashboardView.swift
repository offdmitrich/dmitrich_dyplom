import SwiftData
import SwiftUI

struct DashboardView: View {
    @Environment(LanguageManager.self) private var languageManager
    @Environment(ExchangeRateService.self) private var exchangeRateService
    @AppStorage(AppCurrency.preferenceKey) private var currency: AppCurrency = .usd

    @Query(sort: [SortDescriptor(\WorkShift.date, order: .reverse), SortDescriptor(\WorkShift.createdAt, order: .reverse)])
    private var shifts: [WorkShift]

    @Query(sort: [SortDescriptor(\Employee.fullName)])
    private var employees: [Employee]


    @State private var selectedPeriod: PeriodFilter? = .lastMonth
    @State private var selectedEmployeeID: UUID?

    private let dashboardService = DashboardService()

    var body: some View {
        let stats = dashboardService.makeStats(shifts: filteredShifts)

        NavigationStack {
            List {
                Section {
                    Picker(languageManager.string(L.reportsPeriod), selection: $selectedPeriod) {
                        Text(languageManager.string(L.periodAllTime)).tag(PeriodFilter?.none)
                        ForEach(PeriodFilter.allCases) { period in
                            Text(languageManager.string(period.titleKey)).tag(Optional(period))
                        }
                    }

                    Picker(languageManager.string(L.commonEmployee), selection: $selectedEmployeeID) {
                        Text(languageManager.string(L.commonOverallStatistics)).tag(UUID?.none)
                        ForEach(employees) { employee in
                            Text(employee.fullName).tag(Optional(employee.id))
                        }
                    }
                }

                Section {
                    LabeledContent(languageManager.string(L.dashboardPeriodEarnings), value: money(stats.totalEarningsUSD))
                    LabeledContent(languageManager.string(L.dashboardWorkedHours), value: hours(stats.workedSeconds))
                    LabeledContent(languageManager.string(L.dashboardShifts), value: "\(stats.shiftsCount)")
                    LabeledContent(languageManager.string(L.dashboardTotalTasks), value: "\(stats.totalTasksCount)")
                    LabeledContent(languageManager.string(L.dashboardPaidTasks), value: "\(stats.paidTasksCount)")
                    LabeledContent(languageManager.string(L.dashboardAveragePerShift), value: money(stats.averageEarningsUSDPerShift))
                }
            }
            .navigationTitle(languageManager.string(L.dashboardTitle))
        }
    }

    private var filteredShifts: [WorkShift] {
        shifts.filter { shift in
            if let selectedPeriod, !selectedPeriod.contains(shift.date) {
                return false
            }
            if let selectedEmployeeID {
                return shift.employee?.id == selectedEmployeeID
            }
            return true
        }
    }

    private func hours(_ seconds: Int) -> String {
        Formatters.decimal(Decimal(seconds) / 3600, locale: languageManager.locale)
    }

    private func money(_ value: Decimal) -> String {
        Formatters.convertedCurrencyFromUSD(
            value,
            currency: currency,
            exchangeRates: exchangeRateService,
            locale: languageManager.locale
        )
    }
}
