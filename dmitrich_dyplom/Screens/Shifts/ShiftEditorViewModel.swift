import Foundation
import Observation
import SwiftData

@Observable
final class ShiftEditorViewModel {
    let shift: WorkShift?

    var selectedEmployeeID: UUID?
    var shiftType: ShiftType
    var hourlyActivityType: HourlyActivityType
    var shiftDate: Date
    var startTime: Date
    var endTime: Date
    var hourlyRate: Decimal
    var isLate: Bool
    var isEarlyFinished: Bool
    var hasAcceptableExplanation: Bool
    var explanationText: String
    var validationMessageKey: LocalizedTextKey?

    init(shift: WorkShift? = nil) {
        let initialShiftType = shift?.shiftType ?? .main
        let templateTimeRange = Self.templateTimeRange(for: initialShiftType)

        self.shift = shift
        self.selectedEmployeeID = shift?.employee?.id
        self.shiftType = initialShiftType
        self.hourlyActivityType = shift?.hourlyActivityType ?? .regular
        self.shiftDate = shift?.date ?? Calendar.current.startOfDay(for: .now)
        self.startTime = shift?.startTime ?? templateTimeRange.start
        self.endTime = shift?.effectiveEndTime ?? templateTimeRange.end
        self.hourlyRate = shift?.hourlyRate ?? .zero
        self.isLate = shift?.isLate ?? false
        self.isEarlyFinished = shift?.isEarlyFinished ?? false
        self.hasAcceptableExplanation = shift?.hasAcceptableExplanation ?? false
        self.explanationText = shift?.explanationText ?? ""
    }

    var titleKey: LocalizedTextKey {
        shift == nil ? L.shiftsCreateTitle : L.shiftsEditTitle
    }

    var workedDurationSeconds: Int {
        let startDate = combinedDate(date: shiftDate, time: startTime)
        let endDate = normalizedEndDate(
            startDate: startDate,
            endDate: combinedDate(date: shiftDate, time: endTime)
        )

        return max(0, Int(endDate.timeIntervalSince(startDate)))
    }

    var endsNextDay: Bool {
        let startDate = combinedDate(date: shiftDate, time: startTime)
        let endDate = normalizedEndDate(
            startDate: startDate,
            endDate: combinedDate(date: shiftDate, time: endTime)
        )

        return !Calendar.current.isDate(startDate, inSameDayAs: endDate)
    }

    var shouldAutofillRateOnAppear: Bool {
        shift == nil
    }

    func applyHourlyRate(using settings: AppSettings?) {
        hourlyRate = hourlyRateForCurrentShiftType(using: settings)
    }

    func applyShiftTemplate(for shiftType: ShiftType) {
        let timeRange = Self.templateTimeRange(for: shiftType)
        startTime = timeRange.start
        endTime = timeRange.end
    }

    var shiftTemplateKey: LocalizedTextKey {
        switch shiftType {
        case .morning:
            return L.shiftsTemplateMorning
        case .main:
            return L.shiftsTemplateMain
        case .night:
            return L.shiftsTemplateNight
        }
    }

    func save(
        in context: ModelContext,
        selectedEmployee: Employee?,
        settings: AppSettings?
    ) throws {
        validationMessageKey = nil

        let startDate = combinedDate(date: shiftDate, time: startTime)
        let endDate = combinedDate(date: shiftDate, time: endTime)
        let rate = hourlyRate == .zero ? hourlyRateForCurrentShiftType(using: settings) : hourlyRate

        if let shift {
            shift.applySchedule(
                date: Calendar.current.startOfDay(for: shiftDate),
                startTime: startDate,
                endTime: endDate,
                shiftType: shiftType,
                hourlyActivityType: hourlyActivityType,
                hourlyRate: rate,
                notes: shift.notes,
                isLate: isLate,
                isEarlyFinished: isEarlyFinished,
                hasAcceptableExplanation: hasAcceptableExplanation,
                explanationText: normalizedExplanationText,
                employee: selectedEmployee
            )
        } else {
            context.insert(
                WorkShift(
                    date: Calendar.current.startOfDay(for: shiftDate),
                    startTime: startDate,
                    endTime: endDate,
                    shiftType: shiftType,
                    hourlyActivityType: hourlyActivityType,
                    hourlyRate: rate,
                    isLate: isLate,
                    isEarlyFinished: isEarlyFinished,
                    hasAcceptableExplanation: hasAcceptableExplanation,
                    explanationText: normalizedExplanationText,
                    employee: selectedEmployee
                )
            )
        }

        do {
            try context.save()
        } catch {
            validationMessageKey = L.shiftsValidationSaveFailed
            throw error
        }
    }

    private var normalizedExplanationText: String? {
        let trimmedText = explanationText.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedText.isEmpty ? nil : trimmedText
    }

    var hourlyPayCoefficient: Decimal {
        hourlyActivityType.hourlyPayCoefficient
    }

    private func hourlyRateForCurrentShiftType(using settings: AppSettings?) -> Decimal {
        if let settings {
            switch shiftType {
            case .morning:
                return settings.morningHourlyRate
            case .main:
                return settings.mainHourlyRate
            case .night:
                return settings.nightHourlyRate
            }
        }

        switch shiftType {
        case .morning:
            return Decimal(string: "14.00") ?? 14
        case .main:
            return Decimal(string: "15.00") ?? 15
        case .night:
            return Decimal(string: "17.00") ?? 17
        }
    }

    private func combinedDate(date: Date, time: Date) -> Date {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: time)

        return calendar.date(
            from: DateComponents(
                year: dateComponents.year,
                month: dateComponents.month,
                day: dateComponents.day,
                hour: timeComponents.hour,
                minute: timeComponents.minute,
                second: timeComponents.second
            )
        ) ?? date
    }

    private func normalizedEndDate(startDate: Date, endDate: Date) -> Date {
        guard endDate < startDate else {
            return endDate
        }

        return Calendar.current.date(byAdding: .day, value: 1, to: endDate) ?? endDate
    }

    private static func defaultTime(hour: Int, minute: Int) -> Date {
        Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: .now) ?? .now
    }

    private static func templateTimeRange(for shiftType: ShiftType) -> (start: Date, end: Date) {
        switch shiftType {
        case .morning:
            return (
                start: defaultTime(hour: 7, minute: 30),
                end: defaultTime(hour: 15, minute: 0)
            )
        case .main:
            return (
                start: defaultTime(hour: 15, minute: 0),
                end: defaultTime(hour: 23, minute: 30)
            )
        case .night:
            return (
                start: defaultTime(hour: 23, minute: 30),
                end: defaultTime(hour: 7, minute: 30)
            )
        }
    }
}
