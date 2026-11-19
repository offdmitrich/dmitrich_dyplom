import Foundation

enum HourlyActivityType: String, Codable, CaseIterable, Identifiable {
    case regular = "regular"
    case meeting = "meeting"
    case mentoring = "mentoring"
    case training = "training"
    case customerServiceTraining = "customer_service_training"
    case english = "english"
    case editorTesting = "editor_testing"
    case telephonySiteIssues = "telephony_site_issues"

    var id: String { rawValue }

    init(storedValue: String?) {
        self = storedValue.flatMap(Self.init(rawValue:)) ?? .regular
    }

    var localizationKey: LocalizedTextKey {
        switch self {
        case .regular:
            return L.hourlyActivityRegular
        case .meeting:
            return L.hourlyActivityMeeting
        case .mentoring:
            return L.hourlyActivityMentoring
        case .training:
            return L.hourlyActivityTraining
        case .customerServiceTraining:
            return L.hourlyActivityCustomerServiceTraining
        case .english:
            return L.hourlyActivityEnglish
        case .editorTesting:
            return L.hourlyActivityEditorTesting
        case .telephonySiteIssues:
            return L.hourlyActivityTelephonySiteIssues
        }
    }

    var hourlyPayCoefficient: Decimal {
        switch self {
        case .editorTesting:
            return Decimal(string: "0.75") ?? Decimal(75) / 100
        case .regular,
             .meeting,
             .mentoring,
             .training,
             .customerServiceTraining,
             .english,
             .telephonySiteIssues:
            return Decimal(string: "0.50") ?? Decimal(50) / 100
        }
    }
}
