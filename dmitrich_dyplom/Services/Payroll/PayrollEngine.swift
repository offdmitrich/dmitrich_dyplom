import Foundation

struct PayrollEngine {
    static let includedEligibleTasksPerShift = 15
    static let defaultHourlyPayCoefficient = Decimal(string: "0.5") ?? Decimal(0.5)

    private let pricingEngine = PricingEngine()

    func calculateBreakdown(for shift: WorkShift) -> PayrollBreakdown {
        // ставка хранится в смене, поэтому смена не зависит от новых настроек
        let workedSeconds = shift.workedDurationSeconds
        let workedHours = Decimal(workedSeconds) / 3600
        let baseHourlyRate = shift.hourlyRate
        let hourlyPayCoefficient = Self.defaultHourlyPayCoefficient
        let effectiveHourlyRate = baseHourlyRate * hourlyPayCoefficient
        // при опоздании или раннем уходе без принятого объяснения часы не оплачиваются
        let isHourlyPaySuppressed = shift.hasAttendanceIssue && !shift.hasAcceptableExplanation
        let hourlyPay = isHourlyPaySuppressed ? .zero : workedHours * effectiveHourlyRate

        let sortedTasks = ManualTaskNumbering.manualTasks(for: shift)
        let eligibleTasks = eligibleTasks(in: sortedTasks, for: shift)
        var taskLines: [PaidTaskLine] = []
        var taskPay = Decimal.zero

        // первые 15 подходящих задач входят в почасовую оплату
        for (index, task) in eligibleTasks.enumerated() {
            let isExtra = index >= Self.includedEligibleTasksPerShift
            let price = isExtra
                ? pricingEngine.price(for: task.durationSeconds, shiftType: shift.shiftType)
                : .zero

            taskPay += price
            taskLines.append(
                PaidTaskLine(
                    id: task.id,
                    externalTaskID: task.externalTaskID,
                    durationSeconds: task.durationSeconds,
                    price: price,
                    isExtra: isExtra
                )
            )
        }

        let includedCount = min(eligibleTasks.count, Self.includedEligibleTasksPerShift)
        return PayrollBreakdown(
            workedSeconds: workedSeconds,
            hourlyPay: hourlyPay,
            isHourlyPaySuppressed: isHourlyPaySuppressed,
            addedTasksCount: sortedTasks.count,
            includedBaseTasksCount: includedCount,
            paidExtraTasksCount: eligibleTasks.count - includedCount,
            taskPay: taskPay,
            totalShiftPay: hourlyPay + taskPay,
            taskLines: taskLines
        )
    }

    private func eligibleTasks(in tasks: [TaskRecord], for shift: WorkShift) -> [TaskRecord] {
        var seenTaskIDs = Set<String>()
        var eligibleTasks: [TaskRecord] = []
        let endTime = shift.effectiveEndTime

        for task in tasks {
            guard task.isEligible,
                  let taskDate = task.taskDate,
                  taskDate >= shift.startTime,
                  taskDate <= endTime else {
                continue
            }

            // один и тот же номер учитываем только один раз за смену
            let taskID = TaskRecord.normalizedExternalTaskID(task.externalTaskID)
            if !taskID.isEmpty && seenTaskIDs.insert(taskID).inserted {
                eligibleTasks.append(task)
            }
        }

        return eligibleTasks
    }
}
