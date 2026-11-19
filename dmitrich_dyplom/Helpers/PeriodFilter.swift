import Foundation

enum PeriodFilter: String, CaseIterable, Identifiable {
    case last7Days
    case lastMonth
    case last3Months
    case lastYear

    var id: String { rawValue }

    var titleKey: LocalizedTextKey {
        switch self {
        case .last7Days:
            return L.periodLast7Days
        case .lastMonth:
            return L.periodLastMonth
        case .last3Months:
            return L.periodLast3Months
        case .lastYear:
            return L.periodLastYear
        }
    }

    func contains(_ date: Date, calendar: Calendar = .current) -> Bool {
        let now = Date()
        let start: Date?

        switch self {
        case .last7Days:
            start = calendar.date(byAdding: .day, value: -7, to: now)
        case .lastMonth:
            start = calendar.date(byAdding: .month, value: -1, to: now)
        case .last3Months:
            start = calendar.date(byAdding: .month, value: -3, to: now)
        case .lastYear:
            start = calendar.date(byAdding: .year, value: -1, to: now)
        }

        guard let start else { return true }
        return date >= start && date <= now
    }
}
