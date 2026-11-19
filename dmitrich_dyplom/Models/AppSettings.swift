import Foundation
import SwiftData

@Model
final class AppSettings {
    var morningHourlyRate: Decimal
    var mainHourlyRate: Decimal
    var nightHourlyRate: Decimal

    init(
        morningHourlyRate: Decimal = 14,
        mainHourlyRate: Decimal = 15,
        nightHourlyRate: Decimal = 17
    ) {
        self.morningHourlyRate = morningHourlyRate
        self.mainHourlyRate = mainHourlyRate
        self.nightHourlyRate = nightHourlyRate
    }
}
