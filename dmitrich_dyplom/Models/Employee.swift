import Foundation
import SwiftData

@Model
final class Employee {
    var id: UUID
    var fullName: String
    var position: String
    var personnelNumber: String
    var isActive: Bool
    var createdAt: Date

    @Relationship(inverse: \WorkShift.employee)
    var shifts = [WorkShift]()

    init(
        id: UUID = UUID(),
        fullName: String,
        position: String,
        personnelNumber: String,
        isActive: Bool = true,
        createdAt: Date = .now,
        shifts: [WorkShift] = []
    ) {
        self.id = id
        self.fullName = fullName
        self.position = position
        self.personnelNumber = personnelNumber
        self.isActive = isActive
        self.createdAt = createdAt
        self.shifts = shifts
    }

    var hasHistoricalShifts: Bool {
        !shifts.isEmpty
    }

    var shiftCount: Int {
        shifts.count
    }
}
