import Foundation

struct PaidTaskLine: Identifiable, Sendable {
    let id: UUID
    let externalTaskID: String
    let durationSeconds: Int
    let price: Decimal
    let isExtra: Bool
}

struct PayrollBreakdown: Sendable {
    let workedSeconds: Int
    let hourlyPay: Decimal
    let isHourlyPaySuppressed: Bool
    let addedTasksCount: Int
    let includedBaseTasksCount: Int
    let paidExtraTasksCount: Int
    let taskPay: Decimal
    let totalShiftPay: Decimal
    let taskLines: [PaidTaskLine]
}
