import Foundation
import SwiftData

@Model
final class TaskRecord {
    static let manualEntryRawBlock = "Manual task entry"

    var id: UUID
    var externalTaskID: String
    var createdAt: Date
    var taskDate: Date?
    var taskType: String
    var status: String
    var durationSeconds: Int
    var salesTimeSeconds: Int?
    var agentName: String?
    var rawBlock: String?

    var shift: WorkShift?

    init(
        id: UUID = UUID(),
        externalTaskID: String,
        createdAt: Date = .now,
        taskDate: Date? = nil,
        taskType: String,
        status: String,
        durationSeconds: Int,
        salesTimeSeconds: Int? = nil,
        agentName: String? = nil,
        rawBlock: String? = nil,
        shift: WorkShift? = nil
    ) {
        self.id = id
        self.externalTaskID = Self.normalizedExternalTaskID(externalTaskID)
        self.createdAt = createdAt
        self.taskDate = taskDate
        self.taskType = Self.normalizedTaskType(taskType)
        self.status = Self.normalizedStatus(status)
        self.durationSeconds = durationSeconds
        self.salesTimeSeconds = salesTimeSeconds
        self.agentName = agentName
        self.rawBlock = rawBlock
        self.shift = shift
    }

    var isEligible: Bool {
        Self.isEligible(taskType: taskType, status: status, salesTimeSeconds: salesTimeSeconds)
    }

    var isManualEntry: Bool {
        rawBlock == Self.manualEntryRawBlock
    }

    static func isEligible(taskType: String, status: String, salesTimeSeconds: Int? = nil) -> Bool {
        guard let knownTaskType = KnownTaskType(storedValue: normalizedTaskType(taskType)) else {
            return false
        }

        guard knownTaskType.isPayrollEligibleType else {
            return false
        }

        switch KnownTaskStatus(importedValue: normalizedStatus(status)) {
        case .completed:
            return true
        case .cancelled:
            guard knownTaskType == .logEditing, let salesTimeSeconds else {
                return false
            }

            return salesTimeSeconds > 1
        default:
            return false
        }
    }

    static func normalizedExternalTaskID(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func normalizedTaskType(_ value: String) -> String {
        KnownTaskType(importedValue: value)?.rawValue ?? value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func normalizedStatus(_ value: String) -> String {
        KnownTaskStatus(importedValue: value)?.rawValue ?? value.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

enum ManualTaskNumbering {
    static func manualTasks(for shift: WorkShift) -> [TaskRecord] {
        shift.tasks
            .filter(\.isManualEntry)
            .sorted(by: manualTaskSort)
    }

    static func renumberManualTasks(for shift: WorkShift) {
        for (index, task) in manualTasks(for: shift).enumerated() {
            task.externalTaskID = "\(index + 1)"
        }
    }

    static func nextManualTaskNumber(for shift: WorkShift) -> Int {
        manualTasks(for: shift).count + 1
    }

    nonisolated private static func manualTaskSort(lhs: TaskRecord, rhs: TaskRecord) -> Bool {
        let leftNumber = Int(lhs.externalTaskID)
        let rightNumber = Int(rhs.externalTaskID)

        switch (leftNumber, rightNumber) {
        case let (left?, right?) where left != right:
            return left < right
        case (_?, nil):
            return true
        case (nil, _?):
            return false
        default:
            if lhs.createdAt != rhs.createdAt {
                return lhs.createdAt < rhs.createdAt
            }

            return lhs.externalTaskID < rhs.externalTaskID
        }
    }
}
