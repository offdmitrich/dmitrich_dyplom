import Foundation
import Observation
import SwiftData

fileprivate struct NormalizedEmployeeInput {
    let fullName: String
    let position: String
    let personnelNumber: String
}

fileprivate enum EmployeeValidationOutcome {
    case valid(NormalizedEmployeeInput)
    case invalid(LocalizedTextKey)
    case duplicate
}

fileprivate struct EmployeeValidationService {
    func validate(
        fullName: String,
        position: String,
        personnelNumber: String,
        currentEmployeeID: UUID?,
        in context: ModelContext
    ) throws -> EmployeeValidationOutcome {
        let normalizedFullName = normalizedValue(fullName)
        let normalizedPosition = normalizedValue(position)
        let normalizedPersonnelNumber = normalizedValue(personnelNumber)

        guard !normalizedFullName.isEmpty else {
            return .invalid(L.employeesValidationFullName)
        }

        guard !normalizedPosition.isEmpty else {
            return .invalid(L.employeesValidationPosition)
        }

        if !personnelNumber.isEmpty && normalizedPersonnelNumber.isEmpty {
            return .invalid(L.employeesValidationPersonnelNumberWhitespace)
        }

        let descriptor = FetchDescriptor<Employee>()
        let employees = try context.fetch(descriptor)
        let matchingEmployees = employees.filter { employee in
            employee.id != currentEmployeeID
        }

        let hasMatchingName = matchingEmployees.contains { employee in
            normalizedValue(employee.fullName).localizedCaseInsensitiveCompare(normalizedFullName) == .orderedSame
        }

        let hasMatchingPersonnelNumber = !normalizedPersonnelNumber.isEmpty && matchingEmployees.contains { employee in
            normalizedValue(employee.personnelNumber).localizedCaseInsensitiveCompare(normalizedPersonnelNumber) == .orderedSame
        }

        if hasMatchingName || hasMatchingPersonnelNumber {
            return .duplicate
        }

        return .valid(
            NormalizedEmployeeInput(
                fullName: normalizedFullName,
                position: normalizedPosition,
                personnelNumber: normalizedPersonnelNumber
            )
        )
    }

    private func normalizedValue(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

@Observable
final class EmployeeEditorViewModel {
    let employee: Employee?

    var fullName: String
    var position: String
    var personnelNumber: String
    var isActive: Bool
    var validationMessageKey: LocalizedTextKey?
    var isDuplicateAlertPresented = false

    private let validationService = EmployeeValidationService()

    init(employee: Employee? = nil) {
        self.employee = employee
        self.fullName = employee?.fullName ?? ""
        self.position = employee?.position ?? ""
        self.personnelNumber = employee?.personnelNumber ?? ""
        self.isActive = employee?.isActive ?? true
    }

    var titleKey: LocalizedTextKey {
        employee == nil ? L.employeesAddTitle : L.employeesEditTitle
    }

    @discardableResult
    func save(in context: ModelContext) throws -> Bool {
        switch try validationService.validate(
            fullName: fullName,
            position: position,
            personnelNumber: personnelNumber,
            currentEmployeeID: employee?.id,
            in: context
        ) {
        case let .invalid(messageKey):
            validationMessageKey = messageKey
            isDuplicateAlertPresented = false
            return false
        case .duplicate:
            validationMessageKey = nil
            isDuplicateAlertPresented = true
            return false
        case let .valid(input):
            validationMessageKey = nil
            isDuplicateAlertPresented = false

            if let employee {
                employee.fullName = input.fullName
                employee.position = input.position
                employee.personnelNumber = input.personnelNumber
                employee.isActive = isActive
            } else {
                context.insert(
                    Employee(
                        fullName: input.fullName,
                        position: input.position,
                        personnelNumber: input.personnelNumber,
                        isActive: isActive
                    )
                )
            }

            do {
                try context.save()
                return true
            } catch {
                validationMessageKey = L.employeesValidationSaveFailed
                throw error
            }
        }
    }
}
