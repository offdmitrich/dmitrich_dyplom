import SwiftData
import SwiftUI

struct ShiftEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(LanguageManager.self) private var languageManager
    @Environment(ToastManager.self) private var toastManager

    @Query(sort: [SortDescriptor(\Employee.fullName)])
    private var employees: [Employee]

    @Query private var settings: [AppSettings]

    @State private var viewModel: ShiftEditorViewModel

    init(shift: WorkShift? = nil) {
        _viewModel = State(initialValue: ShiftEditorViewModel(shift: shift))
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
                            SectionHeader(title: languageManager.string(L.shiftsSectionAssignment))

                            VStack(alignment: .leading, spacing: 8) {
                                Text(languageManager.string(L.shiftsFieldEmployee))
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(AppUI.Colors.primaryText)

                                Picker("", selection: $viewModel.selectedEmployeeID) {
                                    Text(languageManager.string(L.shiftsUnassignedOption))
                                        .tag(UUID?.none)

                                    ForEach(availableEmployees) { employee in
                                        Text(
                                            languageManager.string(
                                                L.shiftsEmployeeOption,
                                                employee.fullName,
                                                employee.personnelNumber
                                            )
                                        )
                                            .tag(Optional(employee.id))
                                    }
                                }
                                .pickerStyle(.menu)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .premiumControlBackground()
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text(languageManager.string(L.shiftsFieldType))
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(AppUI.Colors.primaryText)

                                Picker("", selection: $viewModel.shiftType) {
                                    ForEach(ShiftType.allCases) { type in
                                        Text(languageManager.string(type.localizationKey))
                                            .tag(type)
                                    }
                                }
                                .pickerStyle(.segmented)

                                VStack(alignment: .leading, spacing: AppUI.Spacing.xSmall) {
                                    Text(languageManager.string(L.shiftsTemplateTitle))
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(AppUI.Colors.secondaryText)

                                    Text(languageManager.string(viewModel.shiftTemplateKey))
                                        .font(.footnote.weight(.semibold))
                                        .foregroundStyle(AppUI.Colors.primaryText)

                                    Text(languageManager.string(L.shiftsTemplateEditableHint))
                                        .font(.caption)
                                        .foregroundStyle(AppUI.Colors.secondaryText)
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .premiumControlBackground()
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text(languageManager.string(L.shiftsFieldHourlyActivity))
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(AppUI.Colors.primaryText)

                                Picker("", selection: $viewModel.hourlyActivityType) {
                                    ForEach(HourlyActivityType.allCases) { activityType in
                                        Text(languageManager.string(activityType.localizationKey))
                                            .tag(activityType)
                                    }
                                }
                                .pickerStyle(.menu)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .premiumControlBackground()
                            }
                        }
                    }

                    GlassSurface {
                        VStack(alignment: .leading, spacing: AppUI.contentSpacing) {
                            SectionHeader(title: languageManager.string(L.shiftsSectionSchedule))

                            pickerRow(titleKey: L.shiftsFieldDate) {
                                DatePicker(
                                    "",
                                    selection: $viewModel.shiftDate,
                                    displayedComponents: [.date]
                                )
                                .labelsHidden()
                            }

                            pickerRow(titleKey: L.shiftsFieldStartTime) {
                                DatePicker(
                                    "",
                                    selection: $viewModel.startTime,
                                    displayedComponents: [.hourAndMinute]
                                )
                                .labelsHidden()
                            }

                            pickerRow(titleKey: L.shiftsFieldEndTime) {
                                DatePicker(
                                    "",
                                    selection: $viewModel.endTime,
                                    displayedComponents: [.hourAndMinute]
                                )
                                .labelsHidden()
                            }

                            if viewModel.endsNextDay {
                                Label(languageManager.string(L.shiftsCrossesMidnight), systemImage: "moon.stars")
                                    .font(.footnote.weight(.medium))
                                    .foregroundStyle(.indigo)
                                    .padding(.horizontal, AppUI.Spacing.medium)
                                    .padding(.vertical, AppUI.Spacing.small)
                                    .background(Color.indigo.opacity(0.12), in: Capsule())
                            }
                        }
                    }

                    GlassSurface {
                        VStack(alignment: .leading, spacing: AppUI.contentSpacing) {
                            SectionHeader(title: languageManager.string(L.shiftsSectionAttendance))

                            Toggle(languageManager.string(L.shiftsFieldLate), isOn: $viewModel.isLate)
                                .font(.subheadline.weight(.semibold))

                            Toggle(languageManager.string(L.shiftsFieldEarlyFinished), isOn: $viewModel.isEarlyFinished)
                                .font(.subheadline.weight(.semibold))

                            Toggle(languageManager.string(L.shiftsFieldAcceptableExplanation), isOn: $viewModel.hasAcceptableExplanation)
                                .font(.subheadline.weight(.semibold))

                            TextField(
                                languageManager.string(L.shiftsFieldExplanationText),
                                text: $viewModel.explanationText,
                                axis: .vertical
                            )
                            .lineLimit(2...4)
                            .textInputAutocapitalization(.sentences)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .premiumControlBackground()
                        }
                    }

                    GlassSurface {
                        VStack(alignment: .leading, spacing: AppUI.contentSpacing) {
                            SectionHeader(title: languageManager.string(L.shiftsSectionCompensation))

                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: AppUI.groupSpacing)], spacing: AppUI.groupSpacing) {
                                MetricTile(
                                    title: languageManager.string(L.shiftsFieldHourlyRate),
                                    value: Formatters.currency(viewModel.hourlyRate, locale: languageManager.locale),
                                    detail: languageManager.string(
                                        L.shiftsRateCoefficient,
                                        Formatters.decimal(viewModel.hourlyPayCoefficient, locale: languageManager.locale)
                                    ),
                                    tint: .indigo
                                )

                                MetricTile(
                                    title: languageManager.string(L.shiftsMetricWorked),
                                    value: Formatters.duration(seconds: viewModel.workedDurationSeconds),
                                    detail: languageManager.string(
                                        L.shiftsDurationFormula,
                                        Formatters.decimal(
                                            Decimal(viewModel.workedDurationSeconds) / 3600,
                                            locale: languageManager.locale
                                        )
                                    ),
                                    tint: .blue
                                )
                            }
                        }
                    }
                }
                .padding(.horizontal, AppUI.pagePadding)
                .padding(.top, AppUI.Spacing.xLarge)
                .padding(.bottom, AppUI.bottomPadding)
            }
        }
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
                    saveShift()
                }
                .fontWeight(.semibold)
            }
        }
        .task {
            guard viewModel.shouldAutofillRateOnAppear else { return }
            viewModel.applyHourlyRate(using: settings.first)
        }
        .onChange(of: viewModel.shiftType) {
            viewModel.applyShiftTemplate(for: viewModel.shiftType)
            viewModel.applyHourlyRate(using: settings.first)
        }
    }

    private func pickerRow<Content: View>(titleKey: LocalizedTextKey, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(languageManager.string(titleKey))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppUI.Colors.primaryText)

            HStack {
                content()
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .premiumControlBackground()
        }
    }

    private func saveShift() {
        do {
            try viewModel.save(
                in: modelContext,
                selectedEmployee: availableEmployees.first(where: { $0.id == viewModel.selectedEmployeeID }),
                settings: settings.first
            )
            toastManager.show(AppToast(message: languageManager.string(L.shiftsSaved), kind: .success))
            dismiss()
        } catch {
            if viewModel.validationMessageKey == nil {
                viewModel.validationMessageKey = L.shiftsValidationSaveFailed
            }
        }
    }

    private var availableEmployees: [Employee] {
        employees.filter { employee in
            employee.isActive || employee.id == viewModel.selectedEmployeeID
        }
    }

}
