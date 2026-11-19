import SwiftData
import SwiftUI

struct EmployeeEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(LanguageManager.self) private var languageManager
    @Environment(ToastManager.self) private var toastManager

    @State private var viewModel: EmployeeEditorViewModel
    @State private var isActionAlertPresented = false

    init(employee: Employee? = nil) {
        _viewModel = State(initialValue: EmployeeEditorViewModel(employee: employee))
    }

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: AppUI.sectionSpacing) {
                    if let messageKey = viewModel.validationMessageKey {
                        GlassSurface {
                            Label(languageManager.string(messageKey), systemImage: "exclamationmark.triangle.fill")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.red)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    GlassSurface {
                        VStack(alignment: .leading, spacing: AppUI.contentSpacing) {
                            SectionHeader(title: languageManager.string(L.employeesSectionIdentity))

                            employeeField(
                                titleKey: L.employeesFieldFullName,
                                text: $viewModel.fullName,
                                textInputAutocapitalization: .words
                            )

                            employeeField(
                                titleKey: L.employeesFieldPosition,
                                text: $viewModel.position,
                                textInputAutocapitalization: .words
                            )

                            employeeField(
                                titleKey: L.employeesFieldPersonnelNumber,
                                text: $viewModel.personnelNumber,
                                textInputAutocapitalization: .characters
                            )
                        }
                    }

                    GlassSurface {
                        VStack(alignment: .leading, spacing: AppUI.contentSpacing) {
                            SectionHeader(title: languageManager.string(L.employeesSectionEmployment))

                            Toggle(isOn: $viewModel.isActive) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(languageManager.string(L.employeesFieldStatus))
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(AppUI.Colors.primaryText)
                                    Text(
                                        languageManager.string(
                                            viewModel.isActive
                                            ? L.employeesStatusActive
                                            : L.employeesStatusInactive
                                        )
                                    )
                                    .font(.caption)
                                    .foregroundStyle(AppUI.Colors.secondaryText)
                                }
                            }
                            .tint(AppUI.Colors.accent)
                        }
                    }

                    if let employee = viewModel.employee {
                        GlassSurface {
                            VStack(alignment: .leading, spacing: AppUI.contentSpacing) {
                                SectionHeader(title: languageManager.string(L.employeesSectionManagement))

                                Text(
                                    languageManager.string(
                                        employee.hasHistoricalShifts
                                        ? (employee.isActive ? L.employeesHistoricalNotice : L.employeesHistoricalInactiveNotice)
                                        : L.employeesDeleteMessage
                                    )
                                )
                                .font(.subheadline)
                                .foregroundStyle(AppUI.Colors.secondaryText)
                                .fixedSize(horizontal: false, vertical: true)

                                if employee.hasHistoricalShifts {
                                    SecondaryActionButton(
                                        title: languageManager.string(destructiveButtonTitleKey(for: employee)),
                                        systemImage: "person.crop.circle.badge.xmark",
                                        isDisabled: !employee.isActive
                                    ) {
                                        isActionAlertPresented = true
                                    }
                                } else {
                                    DestructiveActionButton(
                                        title: languageManager.string(destructiveButtonTitleKey(for: employee)),
                                        systemImage: "trash"
                                    ) {
                                        isActionAlertPresented = true
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, AppUI.pagePadding)
                .padding(.top, AppUI.Spacing.xLarge)
                .padding(.bottom, AppUI.bottomPadding)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .dismissKeyboardOnTap()
        .navigationTitle(languageManager.string(viewModel.titleKey))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(languageManager.string(L.commonClose)) {
                    dismiss()
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button(languageManager.string(L.commonSave)) {
                    saveEmployee()
                }
                .fontWeight(.semibold)
            }
        }
        .alert(
            languageManager.string(destructiveAlertTitleKey),
            isPresented: $isActionAlertPresented,
            presenting: viewModel.employee
        ) { employee in
            Button(languageManager.string(L.commonClose), role: .cancel) {}
            Button(
                languageManager.string(destructiveConfirmTitleKey(for: employee)),
                role: employee.hasHistoricalShifts ? nil : .destructive
            ) {
                performDestructiveAction(for: employee)
            }
        } message: { employee in
            Text(languageManager.string(destructiveMessageKey(for: employee)))
        }
        .alert(
            languageManager.string(L.employeesDuplicateTitle),
            isPresented: duplicateAlertIsPresented
        ) {
            Button(languageManager.string(L.commonClose), role: .cancel) {}
        } message: {
            Text(languageManager.string(L.employeesDuplicateMessage))
        }
    }

    private func employeeField(
        titleKey: LocalizedTextKey,
        text: Binding<String>,
        textInputAutocapitalization: TextInputAutocapitalization
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(languageManager.string(titleKey))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppUI.Colors.primaryText)

            TextField("", text: text)
                .textInputAutocapitalization(textInputAutocapitalization)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .onSubmit {
                    UIApplication.shared.dismissKeyboard()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .premiumControlBackground()
        }
    }

    private func saveEmployee() {
        do {
            let didSave = try viewModel.save(in: modelContext)
            if didSave {
                showSuccessToast(L.employeesSaved)
                dismiss()
            }
        } catch {
            if viewModel.validationMessageKey == nil {
                viewModel.validationMessageKey = L.employeesValidationSaveFailed
            }
        }
    }

    private var duplicateAlertIsPresented: Binding<Bool> {
        Binding(
            get: { viewModel.isDuplicateAlertPresented },
            set: { viewModel.isDuplicateAlertPresented = $0 }
        )
    }

    private func destructiveButtonTitleKey(for employee: Employee) -> LocalizedTextKey {
        employee.hasHistoricalShifts ? L.employeesActionDeactivateEmployee : L.employeesActionDeleteEmployee
    }

    private var destructiveAlertTitleKey: LocalizedTextKey {
        guard let employee = viewModel.employee else {
            return L.employeesDeleteTitle
        }

        return employee.hasHistoricalShifts ? L.employeesDeactivateTitle : L.employeesDeleteTitle
    }

    private func destructiveConfirmTitleKey(for employee: Employee) -> LocalizedTextKey {
        employee.hasHistoricalShifts ? L.employeesDeactivateConfirm : L.employeesDeleteConfirm
    }

    private func destructiveMessageKey(for employee: Employee) -> LocalizedTextKey {
        employee.hasHistoricalShifts ? L.employeesDeactivateMessage : L.employeesDeleteMessage
    }

    private func performDestructiveAction(for employee: Employee) {
        if employee.hasHistoricalShifts {
            employee.isActive = false
        } else {
            modelContext.delete(employee)
        }

        try? modelContext.save()
        showSuccessToast(L.employeesSaved)
        dismiss()
    }

    private func showSuccessToast(_ messageKey: LocalizedTextKey) {
        toastManager.show(AppToast(message: languageManager.string(messageKey), kind: .success))
    }

}
