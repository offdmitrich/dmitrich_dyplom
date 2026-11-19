import Foundation

enum ShiftType: String, Codable, CaseIterable, Identifiable {
    case morning = "morning"
    case main = "main"
    case night = "night"

    var id: String { rawValue }

    var localizationKey: LocalizedTextKey {
        switch self {
        case .morning:
            return L.shiftTypeMorning
        case .main:
            return L.shiftTypeMain
        case .night:
            return L.shiftTypeNight
        }
    }
}
