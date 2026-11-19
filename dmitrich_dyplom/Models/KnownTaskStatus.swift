import Foundation

enum KnownTaskStatus: String, CaseIterable, Identifiable {
    case completed = "completed"
    case inProgress = "in_progress"
    case pending = "pending"
    case cancelled = "cancelled"

    var id: String { rawValue }

    var localizationKey: LocalizedTextKey {
        switch self {
        case .completed:
            return L.taskStatusCompleted
        case .inProgress:
            return L.taskStatusInProgress
        case .pending:
            return L.taskStatusPending
        case .cancelled:
            return L.taskStatusCancelled
        }
    }

    init?(importedValue: String) {
        let normalized = importedValue
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        switch normalized {
        case Self.completed.rawValue:
            self = .completed
        case Self.inProgress.rawValue:
            self = .inProgress
        case Self.pending.rawValue:
            self = .pending
        case Self.cancelled.rawValue:
            self = .cancelled
        case "completed":
            self = .completed
        case "in progress":
            self = .inProgress
        case "pending":
            self = .pending
        case "cancelled":
            self = .cancelled
        default:
            return nil
        }
    }
}
