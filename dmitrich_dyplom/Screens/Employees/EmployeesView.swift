import SwiftData
import SwiftUI
import UIKit

private enum EmployeeListFilter: String, CaseIterable, Identifiable {
    case all
    case active
    case inactive

    var id: String { rawValue }

    var titleKey: LocalizedTextKey {
        switch self {
        case .all:
            return L.employeesFilterAll
        case .active:
            return L.employeesFilterActive
        case .inactive:
            return L.employeesFilterInactive
        }
    }
}

struct EmployeesView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(LanguageManager.self) private var languageManager
    @Query(sort: [SortDescriptor(\Employee.fullName), SortDescriptor(\Employee.createdAt, order: .reverse)])
    private var employees: [Employee]

    @State private var searchText = ""
    @State private var selectedFilter: EmployeeListFilter = .all
    @State private var isAddSheetPresented = false
    @State private var employeePendingAction: Employee?

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: AppUI.groupSpacing) {
                        filterCard

                        if filteredEmployees.isEmpty {
                            emptyStateCard
                        } else {
                            employeeList
                        }
                    }
                    .padding(.horizontal, AppUI.pagePadding)
                    .padding(.top, AppUI.Spacing.large)
                    .padding(.bottom, AppUI.bottomPadding)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isAddSheetPresented = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.headline.weight(.semibold))
                    }
                    .accessibilityLabel(languageManager.string(L.employeesAddButton))
                }
            }
            .sheet(isPresented: $isAddSheetPresented) {
                NavigationStack {
                    EmployeeEditorView()
                }
            }
            .alert(
                languageManager.string(alertTitleKey),
                isPresented: destructiveAlertIsPresented,
                presenting: employeePendingAction
            ) { employee in
                Button(languageManager.string(L.commonClose), role: .cancel) {
                    employeePendingAction = nil
                }
                Button(
                    languageManager.string(confirmTitleKey(for: employee)),
                    role: employee.hasHistoricalShifts ? nil : .destructive
                ) {
                    performDestructiveAction(for: employee)
                }
            } message: { employee in
                Text(languageManager.string(messageTitleKey(for: employee)))
            }
        }
    }

    private var employeeList: some View {
        VStack(alignment: .leading, spacing: AppUI.groupSpacing) {
            VStack(spacing: AppUI.groupSpacing) {
                ForEach(filteredEmployees) { employee in
                    NavigationLink {
                        EmployeeEditorView(employee: employee)
                    } label: {
                        EmployeeRowView(employee: employee)
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        if shouldShowDestructiveAction(for: employee) {
                            Button(role: employee.hasHistoricalShifts ? nil : .destructive) {
                                employeePendingAction = employee
                            } label: {
                                Label(
                                    languageManager.string(actionTitleKey(for: employee)),
                                    systemImage: employee.hasHistoricalShifts ? "person.crop.circle.badge.xmark" : "trash"
                                )
                            }
                            .tint(employee.hasHistoricalShifts ? .orange : .red)
                        }
                    }
                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                        Button {
                            toggleEmployeeStatus(employee)
                        } label: {
                            Label(
                                languageManager.string(
                                    employee.isActive
                                    ? L.employeesActionDeactivate
                                    : L.employeesActionActivate
                                ),
                                systemImage: employee.isActive ? "pause.circle" : "checkmark.circle"
                            )
                        }
                        .tint(employee.isActive ? .orange : .green)
                    }
                }
            }
        }
    }

    private var filterCard: some View {
        GlassSurface(isElevated: false) {
            VStack(alignment: .leading, spacing: AppUI.Spacing.medium) {
                HStack(spacing: AppUI.Spacing.small) {
                    Image(systemName: "magnifyingglass")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppUI.Colors.secondaryText)

                    TextField(languageManager.string(L.employeesSearchPlaceholder), text: $searchText)
                        .font(.subheadline)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .submitLabel(.search)
                        .onSubmit {
                            UIApplication.shared.dismissKeyboard()
                        }
                }
                .padding(.horizontal, AppUI.Spacing.medium)
                .padding(.vertical, AppUI.Spacing.small)
                .premiumControlBackground()

                HStack(spacing: AppUI.Spacing.medium) {
                    HStack(spacing: AppUI.Spacing.small) {
                        ForEach(EmployeeListFilter.allCases) { filter in
                            filterChip(filter)
                        }
                    }

                    InfoBadge(
                        title: "\(filteredEmployees.count)/\(employees.count)",
                        tint: AppUI.Colors.accent,
                        systemImage: "person.2"
                    )
                }
            }
        }
    }

    private func filterChip(_ filter: EmployeeListFilter) -> some View {
        Button {
            selectedFilter = filter
        } label: {
            Text(languageManager.string(filter.titleKey))
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.82)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, AppUI.Spacing.medium)
                .padding(.vertical, AppUI.Spacing.small)
                .background(filter == selectedFilter ? AppUI.Colors.accent : AppUI.Colors.controlSurface, in: Capsule())
                .overlay {
                    Capsule()
                        .strokeBorder(filter == selectedFilter ? AppUI.Colors.accent.opacity(0.18) : AppUI.Colors.separator.opacity(0.35), lineWidth: 0.5)
                }
                .foregroundStyle(filter == selectedFilter ? .white : AppUI.Colors.primaryText)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(filter == selectedFilter ? .isSelected : [])
    }

    private var emptyStateCard: some View {
        EmptyStateView(
            title: languageManager.string(
                searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && selectedFilter == .all
                ? L.employeesEmptyTitle
                : L.employeesNoResultsTitle
            ),
            message: languageManager.string(
                searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && selectedFilter == .all
                ? L.employeesEmptyDescription
                : L.employeesNoResultsDescription
            ),
            systemImage: "person.2.slash",
            actionTitle: searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && selectedFilter == .all
                ? languageManager.string(L.employeesAddButton)
                : nil,
            action: searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && selectedFilter == .all
                ? { isAddSheetPresented = true }
                : nil
        )
    }

    private var filteredEmployees: [Employee] {
        employees.filter { employee in
            matchesFilter(employee) && matchesSearch(employee)
        }
    }

    private var destructiveAlertIsPresented: Binding<Bool> {
        Binding(
            get: { employeePendingAction != nil },
            set: { isPresented in
                if !isPresented {
                    employeePendingAction = nil
                }
            }
        )
    }

    private var alertTitleKey: LocalizedTextKey {
        guard let employeePendingAction else {
            return L.employeesDeleteTitle
        }

        return employeePendingAction.hasHistoricalShifts ? L.employeesDeactivateTitle : L.employeesDeleteTitle
    }

    private func matchesFilter(_ employee: Employee) -> Bool {
        switch selectedFilter {
        case .all:
            return true
        case .active:
            return employee.isActive
        case .inactive:
            return !employee.isActive
        }
    }

    private func matchesSearch(_ employee: Employee) -> Bool {
        let normalizedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedSearch.isEmpty else { return true }

        return employee.fullName.localizedCaseInsensitiveContains(normalizedSearch)
    }

    private func toggleEmployeeStatus(_ employee: Employee) {
        employee.isActive.toggle()
        try? modelContext.save()
    }

    private func performDestructiveAction(for employee: Employee) {
        if employee.hasHistoricalShifts {
            employee.isActive = false
        } else {
            modelContext.delete(employee)
        }

        try? modelContext.save()
        employeePendingAction = nil
    }

    private func shouldShowDestructiveAction(for employee: Employee) -> Bool {
        employee.isActive || !employee.hasHistoricalShifts
    }

    private func actionTitleKey(for employee: Employee) -> LocalizedTextKey {
        employee.hasHistoricalShifts ? L.employeesActionDeactivate : L.employeesActionDelete
    }

    private func confirmTitleKey(for employee: Employee) -> LocalizedTextKey {
        employee.hasHistoricalShifts ? L.employeesDeactivateConfirm : L.employeesDeleteConfirm
    }

    private func messageTitleKey(for employee: Employee) -> LocalizedTextKey {
        employee.hasHistoricalShifts ? L.employeesDeactivateMessage : L.employeesDeleteMessage
    }

}

private struct EmployeeRowView: View {
    @Environment(LanguageManager.self) private var languageManager

    let employee: Employee

    var body: some View {
        GlassSurface(contentPadding: AppUI.Spacing.large) {
            VStack(alignment: .leading, spacing: AppUI.Spacing.medium) {
                HStack(alignment: .center, spacing: AppUI.Spacing.medium) {
                    ZStack {
                        Circle()
                            .fill((employee.isActive ? Color.green : Color.orange).opacity(0.14))

                        Text(initials)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(employee.isActive ? .green : .orange)
                    }
                    .frame(width: 38, height: 38)

                    VStack(alignment: .leading, spacing: AppUI.Spacing.xSmall) {
                        Text(employee.fullName)
                            .font(AppUI.Typography.cardTitle)
                            .foregroundStyle(AppUI.Colors.primaryText)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(employee.position)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(AppUI.Colors.secondaryText)
                            .lineLimit(1)
                            .minimumScaleFactor(0.84)
                    }

                    Spacer()

                    statusBadge
                }

                HStack(spacing: AppUI.Spacing.small) {
                    infoPill(
                        title: languageManager.string(L.employeesFieldPersonnelNumber),
                        value: employee.personnelNumber
                    )

                    infoPill(
                        title: languageManager.string(L.employeesFieldStatus),
                        value: languageManager.string(employee.isActive ? L.employeesStatusActive : L.employeesStatusInactive)
                    )
                }
            }
        }
    }

    private var statusBadge: some View {
        InfoBadge(
            title: languageManager.string(employee.isActive ? L.employeesStatusActive : L.employeesStatusInactive),
            tint: employee.isActive ? .green : .orange
        )
    }

    private var initials: String {
        let parts = employee.fullName
            .split(separator: " ")
            .prefix(2)
            .compactMap { $0.first }

        let value = String(parts).uppercased()
        return value.isEmpty ? "#" : value
    }

    private func infoPill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: AppUI.Spacing.xSmall) {
            Text(title.uppercased())
                .font(.caption2.weight(.bold))
                .foregroundStyle(AppUI.Colors.secondaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.78)

            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppUI.Colors.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        }
        .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
        .padding(.horizontal, AppUI.Spacing.medium)
        .padding(.vertical, AppUI.Spacing.small)
        .premiumControlBackground()
    }
}
