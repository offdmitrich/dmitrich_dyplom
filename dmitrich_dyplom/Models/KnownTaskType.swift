import Foundation

enum KnownTaskType: String, CaseIterable, Identifiable {
    case logEditing = "log_editing"
    case oneTimeHelp = "one_time_help"
    case oneTimeHelpPriority = "one_time_help_priority"
    case personal = "personal"
    case gap = "gap"

    var id: String { rawValue }

    var localizationKey: LocalizedTextKey {
        switch self {
        case .logEditing:
            return L.taskTypeLogEditing
        case .oneTimeHelp:
            return L.taskTypeOneTimeHelp
        case .oneTimeHelpPriority:
            return L.taskTypeOneTimeHelpPriority
        case .personal:
            return L.taskTypePersonal
        case .gap:
            return L.taskTypeGap
        }
    }

    var isPayrollEligibleType: Bool {
        switch self {
        case .logEditing, .oneTimeHelp, .oneTimeHelpPriority, .personal, .gap:
            return true
        }
    }

    init?(importedValue: String) {
        let normalized = importedValue
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "/", with: " ")
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
            .lowercased()

        switch normalized {
        case "log editing":
            self = .logEditing
        case "one time help":
            self = .oneTimeHelp
        case "one time help priority":
            self = .oneTimeHelpPriority
        case "personal":
            self = .personal
        case "gap":
            self = .gap
        default:
            return nil
        }
    }

    init?(storedValue: String) {
        switch storedValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case Self.logEditing.rawValue:
            self = .logEditing
        case Self.oneTimeHelp.rawValue:
            self = .oneTimeHelp
        case Self.oneTimeHelpPriority.rawValue:
            self = .oneTimeHelpPriority
        case Self.personal.rawValue:
            self = .personal
        case Self.gap.rawValue:
            self = .gap
        default:
            self.init(importedValue: storedValue)
        }
    }
}
