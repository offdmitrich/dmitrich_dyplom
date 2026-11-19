import SwiftData
import SwiftUI

struct ShiftDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(LanguageManager.self) private var languageManager
    @Environment(ExchangeRateService.self) private var exchangeRateService
    @AppStorage(AppCurrency.preferenceKey) private var currency: AppCurrency = .usd
    @Environment(ToastManager.self) private var toastManager

    @State private var showEditor = false
    @State private var showTaskForm = false
    @State private var showDeleteShift = false
    @State private var showDeleteTask = false
    @State private var taskToDelete: PaidTaskLine?

    private let payroll = PayrollEngine()

    let shift: WorkShift

    var body: some View {
        let breakdown = payroll.calculateBreakdown(for: shift)

        List {
            shiftSection

            if shift.hasAttendanceIssue {
                attendanceSection
            }

            paySection(breakdown)
            tasksSection(breakdown.taskLines)
        }
        .navigationTitle(languageManager.string(L.shiftDetailsTitle))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    showEditor = true
                } label: {
                    Label(languageManager.string(L.shiftsEditButton), systemImage: "pencil")
                }

                Button {
                    showTaskForm = true
                } label: {
                    Label(languageManager.string(L.shiftDetailsAddTask), systemImage: "plus")
                }

                Button(role: .destructive) {
                    showDeleteShift = true
                } label: {
                    Label(languageManager.string(L.shiftsDeleteAction), systemImage: "trash")
                }
            }
        }
        .sheet(isPresented: $showEditor) {
            NavigationStack {
                ShiftEditorView(shift: shift)
            }
        }
        .sheet(isPresented: $showTaskForm) {
            NavigationStack {
                ManualTaskEntryView(shift: shift)
            }
        }
        .alert(
            languageManager.string(L.shiftsDeleteTitle),
            isPresented: $showDeleteShift
        ) {
            Button(languageManager.string(L.commonCancel), role: .cancel) {}
            Button(languageManager.string(L.shiftsDeleteConfirm), role: .destructive) {
                deleteShift()
            }
        } message: {
            Text(languageManager.string(L.shiftsDeleteMessage))
        }
        .alert(
            languageManager.string(L.shiftDetailsDeleteTaskTitle, taskToDelete?.externalTaskID ?? ""),
            isPresented: $showDeleteTask,
            presenting: taskToDelete
        ) { task in
            Button(languageManager.string(L.commonCancel), role: .cancel) {}
            Button(languageManager.string(L.commonDelete), role: .destructive) {
                deleteTask(task)
            }
        } message: { _ in
            Text(languageManager.string(L.shiftDetailsDeleteTaskMessage))
        }
    }

    private var shiftSection: some View {
        Section(languageManager.string(L.shiftDetailsBasicInfoTitle)) {
            row(L.shiftsFieldEmployee, shift.employee?.fullName ?? languageManager.string(L.commonUnassigned))
            row(L.shiftsFieldDate, shift.date.formatted(date: .abbreviated, time: .omitted))
            row(L.shiftsFieldType, languageManager.string(shift.shiftType.localizationKey))
            row(L.shiftDetailsStart, shift.startTime.formatted(date: .omitted, time: .shortened))
            row(L.shiftDetailsEnd, shift.effectiveEndTime.formatted(date: .omitted, time: .shortened))
            row(L.shiftsFieldWorkedDuration, Formatters.duration(seconds: shift.workedDurationSeconds))
        }
    }

    private var attendanceSection: some View {
        var issues: [String] = []
        if shift.isLate {
            issues.append(languageManager.string(L.shiftsFieldLate))
        }
        if shift.isEarlyFinished {
            issues.append(languageManager.string(L.shiftsFieldEarlyFinished))
        }

        return Section(languageManager.string(L.shiftDetailsAttendanceTitle)) {
            row(L.shiftDetailsAttendanceIssue, issues.joined(separator: ", "))
            row(L.shiftDetailsAttendanceApproved, languageManager.string(shift.hasApprovedAttendanceExplanation ? L.commonYes : L.commonNo))
            if let explanation = shift.explanationText, !explanation.isEmpty {
                row(L.shiftDetailsAttendanceExplanation, explanation)
            }
        }
    }

    private func paySection(_ breakdown: PayrollBreakdown) -> some View {
        Section(languageManager.string(L.shiftDetailsPayrollTitle)) {
            row(L.metricHourlyPay, Formatters.currency(breakdown.hourlyPay, locale: languageManager.locale))
            row(L.shiftDetailsAddedTasks, String(breakdown.addedTasksCount))
            row(L.shiftDetailsIncludedTasks, String(breakdown.includedBaseTasksCount))
            row(L.shiftDetailsPaidExtraTasks, String(breakdown.paidExtraTasksCount))
            row(L.payrollMetricTaskPay, Formatters.currency(breakdown.taskPay, locale: languageManager.locale))
            row(L.metricShiftTotal, Formatters.convertedCurrencyFromUSD(
                breakdown.totalShiftPay,
                currency: currency,
                exchangeRates: exchangeRateService,
                locale: languageManager.locale
            ))

            if breakdown.isHourlyPaySuppressed {
                Text(languageManager.string(L.payrollHourlyPaySuppressed))
                    .foregroundStyle(.orange)
            }
        }
    }

    private func tasksSection(_ tasks: [PaidTaskLine]) -> some View {
        Section(languageManager.string(L.shiftDetailsAddedTasksTitle)) {
            if tasks.isEmpty {
                Text(languageManager.string(L.shiftDetailsNoTasks))
                    .foregroundStyle(.secondary)
            }

            ForEach(tasks) { task in
                VStack(alignment: .leading, spacing: 4) {
                    Text(languageManager.string(L.shiftDetailsTaskNumberValue, task.externalTaskID))
                    Text(Formatters.duration(seconds: task.durationSeconds))
                    Text(task.isExtra
                         ? languageManager.string(L.shiftDetailsTaskPrice, Formatters.currency(task.price, locale: languageManager.locale))
                         : languageManager.string(L.shiftDetailsTaskPriceIncluded))
                }
                .swipeActions(allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        taskToDelete = task
                        showDeleteTask = true
                    } label: {
                        Label(languageManager.string(L.shiftDetailsDeleteTask), systemImage: "trash")
                    }
                }
            }
        }
    }

    private func row(_ title: LocalizedTextKey, _ value: String) -> some View {
        LabeledContent(languageManager.string(title), value: value)
    }

    private func deleteTask(_ line: PaidTaskLine) {
        guard let task = shift.tasks.first(where: { $0.id == line.id && $0.isManualEntry }) else { return }

        shift.tasks.removeAll { $0.id == task.id }
        modelContext.delete(task)
        ManualTaskNumbering.renumberManualTasks(for: shift)

        do {
            try modelContext.save()
            toastManager.show(AppToast(message: languageManager.string(L.shiftDetailsTaskDeleted), kind: .success))
        } catch {
            modelContext.rollback()
            toastManager.show(AppToast(message: error.localizedDescription, kind: .error))
        }
    }

    private func deleteShift() {
        // swiftdata удаляет задачи вместе со сменой
        modelContext.delete(shift)

        do {
            try modelContext.save()
            toastManager.show(AppToast(message: languageManager.string(L.shiftsDeleteSuccess), kind: .success))
            dismiss()
        } catch {
            modelContext.rollback()
            toastManager.show(AppToast(message: languageManager.string(L.shiftsDeleteFailure), kind: .error))
        }
    }
}
