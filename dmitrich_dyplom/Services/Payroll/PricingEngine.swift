import Foundation

struct PricingEngine {
    static func priceLimits(for shiftType: ShiftType) -> (minimum: Decimal, maximum: Decimal) {
        switch shiftType {
        case .morning, .main:
            return (decimal("1.10"), decimal("1.70"))
        case .night:
            return (decimal("1.15"), decimal("2.10"))
        }
    }

    func price(for durationSeconds: Int, shiftType: ShiftType) -> Decimal {
        guard durationSeconds > 0 else { return .zero }

        // считаем цену по времени и ограничиваем её минимумом и максимумом смены
        let rawPrice = Decimal(durationSeconds) / 240
        let roundedPrice = rounded(rawPrice, scale: 2)
        let limits = Self.priceLimits(for: shiftType)
        return min(max(roundedPrice, limits.minimum), limits.maximum)
    }

    private func rounded(_ value: Decimal, scale: Int) -> Decimal {
        var value = value
        var result = Decimal()
        NSDecimalRound(&result, &value, scale, .plain)
        return result
    }

    private static func decimal(_ value: String) -> Decimal {
        Decimal(string: value) ?? .zero
    }
}
