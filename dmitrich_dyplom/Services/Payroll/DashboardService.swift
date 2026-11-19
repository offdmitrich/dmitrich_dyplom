import Foundation

struct DashboardStats: Sendable {
    let totalEarningsUSD: Decimal
    let workedSeconds: Int
    let shiftsCount: Int
    let totalTasksCount: Int
    let paidTasksCount: Int
    let averageEarningsUSDPerShift: Decimal

    static let zero = DashboardStats(
        totalEarningsUSD: .zero,
        workedSeconds: 0,
        shiftsCount: 0,
        totalTasksCount: 0,
        paidTasksCount: 0,
        averageEarningsUSDPerShift: .zero
    )
}

struct DashboardService {
    private let payrollEngine = PayrollEngine()

    func makeStats(shifts: [WorkShift]) -> DashboardStats {
        guard !shifts.isEmpty else {
            return .zero
        }

        var totalEarningsUSD: Decimal = .zero
        var workedSeconds = 0
        var totalTasksCount = 0
        var paidTasksCount = 0

        for shift in shifts {
            workedSeconds += shift.workedDurationSeconds

            let breakdown = payrollEngine.calculateBreakdown(for: shift)
            totalEarningsUSD += breakdown.totalShiftPay
            totalTasksCount += breakdown.addedTasksCount
            paidTasksCount += breakdown.paidExtraTasksCount
        }

        let averageEarningsUSDPerShift = totalEarningsUSD / Decimal(shifts.count)

        return DashboardStats(
            totalEarningsUSD: totalEarningsUSD,
            workedSeconds: workedSeconds,
            shiftsCount: shifts.count,
            totalTasksCount: totalTasksCount,
            paidTasksCount: paidTasksCount,
            averageEarningsUSDPerShift: averageEarningsUSDPerShift
        )
    }
}
