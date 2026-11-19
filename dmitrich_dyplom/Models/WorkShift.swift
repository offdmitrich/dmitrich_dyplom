import Foundation
import SwiftData

@Model
final class WorkShift {
    var id: UUID
    var date: Date
    var startTime: Date
    var endTime: Date
    var shiftType: ShiftType
    var hourlyActivityTypeCode: String?
    var hourlyRate: Decimal
    var notes: String
    var isLateStorage: Bool?
    var isEarlyFinishedStorage: Bool?
    var hasAcceptableExplanationStorage: Bool?
    var explanationText: String?
    var createdAt: Date

    var employee: Employee?

    @Relationship(deleteRule: .cascade, inverse: \TaskRecord.shift)
    var tasks = [TaskRecord]()

    init(
        id: UUID = UUID(),
        date: Date,
        startTime: Date,
        endTime: Date,
        shiftType: ShiftType,
        hourlyActivityType: HourlyActivityType = .regular,
        hourlyRate: Decimal,
        notes: String = "",
        isLate: Bool = false,
        isEarlyFinished: Bool = false,
        hasAcceptableExplanation: Bool = false,
        explanationText: String? = nil,
        createdAt: Date = .now,
        employee: Employee? = nil,
        tasks: [TaskRecord] = []
    ) {
        self.id = id
        self.date = date
        self.startTime = startTime
        self.endTime = Self.normalizedEndTime(startTime: startTime, endTime: endTime)
        self.shiftType = shiftType
        self.hourlyActivityTypeCode = hourlyActivityType.rawValue
        self.hourlyRate = hourlyRate
        self.notes = notes
        self.isLateStorage = isLate
        self.isEarlyFinishedStorage = isEarlyFinished
        self.hasAcceptableExplanationStorage = hasAcceptableExplanation
        self.explanationText = explanationText
        self.createdAt = createdAt
        self.employee = employee
        self.tasks = tasks
    }

    var effectiveEndTime: Date {
        Self.normalizedEndTime(startTime: startTime, endTime: endTime)
    }

    var workedDurationSeconds: Int {
        max(0, Int(effectiveEndTime.timeIntervalSince(startTime)))
    }

    var crossesMidnight: Bool {
        !Calendar.current.isDate(startTime, inSameDayAs: effectiveEndTime)
    }

    var hasAttendanceIssue: Bool {
        isLate || isEarlyFinished
    }

    var isLate: Bool {
        get { isLateStorage ?? false }
        set { isLateStorage = newValue }
    }

    var isEarlyFinished: Bool {
        get { isEarlyFinishedStorage ?? false }
        set { isEarlyFinishedStorage = newValue }
    }

    var hasAcceptableExplanation: Bool {
        get { hasAcceptableExplanationStorage ?? false }
        set { hasAcceptableExplanationStorage = newValue }
    }

    var hasApprovedAttendanceExplanation: Bool {
        hasAcceptableExplanation &&
            !(explanationText ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var hourlyActivityType: HourlyActivityType {
        get { HourlyActivityType(storedValue: hourlyActivityTypeCode) }
        set { hourlyActivityTypeCode = newValue.rawValue }
    }

    var hourlyPayCoefficient: Decimal {
        hourlyActivityType.hourlyPayCoefficient
    }

    func applySchedule(
        date: Date,
        startTime: Date,
        endTime: Date,
        shiftType: ShiftType,
        hourlyActivityType: HourlyActivityType,
        hourlyRate: Decimal,
        notes: String,
        isLate: Bool,
        isEarlyFinished: Bool,
        hasAcceptableExplanation: Bool,
        explanationText: String?,
        employee: Employee?
    ) {
        self.date = date
        self.startTime = startTime
        self.endTime = Self.normalizedEndTime(startTime: startTime, endTime: endTime)
        self.shiftType = shiftType
        self.hourlyActivityType = hourlyActivityType
        self.hourlyRate = hourlyRate
        self.notes = notes
        self.isLate = isLate
        self.isEarlyFinished = isEarlyFinished
        self.hasAcceptableExplanation = hasAcceptableExplanation
        self.explanationText = explanationText
        self.employee = employee
    }

    private static func normalizedEndTime(startTime: Date, endTime: Date) -> Date {
        guard endTime < startTime else {
            return endTime
        }

        // у ночной смены время окончания может попасть на следующий день
        return Calendar.current.date(byAdding: .day, value: 1, to: endTime) ?? endTime
    }
}
