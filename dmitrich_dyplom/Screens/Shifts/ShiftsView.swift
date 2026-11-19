import SwiftData
import SwiftUI

struct ShiftsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(LanguageManager.self) private var languageManager
    @Environment(ExchangeRateService.self) private var exchangeRateService
    @AppStorage(AppCurrency.preferenceKey) private var currency: AppCurrency = .usd
    @Environment(ToastManager.self) private var toastManager
    @Query(sort: [SortDescriptor(\WorkShift.date, order: .reverse), SortDescriptor(\WorkShift.createdAt, order: .reverse)])
    private var shifts: [WorkShift]
    @Query(sort: \Employee.fullName) private var employees: [Employee]

    @State private var selectedPeriod: PeriodFilter? = .lastMonth
    @State private var selectedEmployeeID: UUID?
    @State private var showNewShift = false
    @State private var showDeleteShift = false
    @State private var shiftToDelete: WorkShift?

    private let payroll = PayrollEngine()

    var body: some View {
        let filtered = filteredShifts
        let workedSeconds = filtered.reduce(0) { $0 + $1.workedDurationSeconds }

        NavigationStack {
            List {
                filters

                Section {
                    LabeledContent(languageManager.string(L.commonShifts), value: String(filtered.count))
                    LabeledContent(languageManager.string(L.shiftsMetricWorked), value: Formatters.duration(seconds: workedSeconds))
                }

                Section {
                    if filtered.isEmpty {
                        emptyMessage
                    }

                    ForEach(filtered) { shift in
                        NavigationLink {
                            ShiftDetailView(shift: shift)
                        } label: {
                            shiftRow(shift)
                        }
                        .swipeActions(allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                shiftToDelete = shift
                                showDeleteShift = true
                            } label: {
                                Label(languageManager.string(L.shiftsDeleteAction), systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .navigationTitle(languageManager.string(L.shiftsTitle))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showNewShift = true
                    } label: {
                        Label(languageManager.string(L.shiftsCreateButton), systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showNewShift) {
                NavigationStack {
                    ShiftEditorView()
                }
            }
            .alert(
                languageManager.string(L.shiftsDeleteTitle),
                isPresented: $showDeleteShift,
                presenting: shiftToDelete
            ) { shift in
                Button(languageManager.string(L.commonCancel), role: .cancel) {}
                Button(languageManager.string(L.shiftsDeleteConfirm), role: .destructive) {
                    deleteShift(shift)
                }
            } message: { _ in
                Text(languageManager.string(L.shiftsDeleteMessage))
            }
        }
    }

    private var filters: some View {
        Section {
            Picker(languageManager.string(L.reportsPeriod), selection: $selectedPeriod) {
                Text(languageManager.string(L.periodAllTime)).tag(PeriodFilter?.none)
                ForEach(PeriodFilter.allCases) { period in
                    Text(languageManager.string(period.titleKey)).tag(Optional(period))
                }
            }

            Picker(languageManager.string(L.commonEmployee), selection: $selectedEmployeeID) {
                Text(languageManager.string(L.commonAllEmployees)).tag(UUID?.none)
                ForEach(employees) { employee in
                    Text(employee.fullName).tag(Optional(employee.id))
                }
            }
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

    private var emptyMessage: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(languageManager.string(shifts.isEmpty ? L.shiftsEmptyTitle : L.shiftsNoResultsTitle))
                .font(.headline)
            Text(languageManager.string(shifts.isEmpty ? L.shiftsEmptyDescription : L.shiftsNoResultsDescription))
                .foregroundStyle(.secondary)
            if shifts.isEmpty {
                Button(languageManager.string(L.shiftsCreateButton)) {
                    showNewShift = true
                }
            }
        }
    }

    private func shiftRow(_ shift: WorkShift) -> some View {
        let breakdown = payroll.calculateBreakdown(for: shift)
        let taskCount = breakdown.addedTasksCount
        let pay = Formatters.convertedCurrencyFromUSD(
            breakdown.totalShiftPay,
            currency: currency,
            exchangeRates: exchangeRateService,
            locale: languageManager.locale
        )

        return VStack(alignment: .leading, spacing: 4) {
            Text(shift.employee?.fullName ?? languageManager.string(L.commonUnassigned))
                .font(.headline)
            Text(shift.date.formatted(date: .abbreviated, time: .omitted))
            Text(languageManager.string(shift.shiftType.localizationKey))
            LabeledContent(languageManager.string(L.commonTasks), value: String(taskCount))
            LabeledContent(languageManager.string(L.commonEarnings), value: pay)
        }
    }

    private func deleteShift(_ shift: WorkShift) {
        // задачи удаляются вместе со сменой по связи в SwiftData
        modelContext.delete(shift)

        do {
            try modelContext.save()
            toastManager.show(AppToast(message: languageManager.string(L.shiftsDeleteSuccess), kind: .success))
        } catch {
            modelContext.rollback()
            toastManager.show(AppToast(message: languageManager.string(L.shiftsDeleteFailure), kind: .error))
        }
    }
}

#Preview {
    let languageManager = LanguageManager()

    ShiftsView()
        .environment(languageManager)
        .environment(ToastManager())
        .environment(ExchangeRateService())
        .environment(\.locale, languageManager.locale)
        .modelContainer(AppModelContainer.makePreviewContainer())
}
