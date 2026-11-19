import LocalAuthentication
import SwiftUI

struct SecuritySettingsView: View {
    @Environment(LanguageManager.self) private var languageManager
    @Environment(SecurityManager.self) private var securityManager
    @Environment(ToastManager.self) private var toastManager

    @State private var pinSetupMode: PINSetupMode?
    @State private var statusMessage: String?

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: AppUI.groupSpacing) {
                    if let statusMessage {
                        statusCard(statusMessage)
                    }

                    GlassSurface {
                        VStack(alignment: .leading, spacing: AppUI.contentSpacing) {
                            SectionHeader(
                                title: languageManager.string(L.securityTitle),
                                subtitle: languageManager.string(L.securityPINCode)
                            )

                            Toggle(isOn: pinEnabledBinding) {
                                VStack(alignment: .leading, spacing: AppUI.Spacing.xSmall) {
                                    Text(languageManager.string(L.securityEnablePIN))
                                        .font(.subheadline.weight(.semibold))
                                    Text(languageManager.string(L.securityPINCode))
                                        .font(.caption)
                                        .foregroundStyle(AppUI.Colors.secondaryText)
                                }
                            }
                            .tint(AppUI.Colors.accent)

                            SecondaryActionButton(
                                title: languageManager.string(L.securityChangePIN),
                                systemImage: "number",
                                isDisabled: !securityManager.isPINEnabled
                            ) {
                                pinSetupMode = .change
                            }

                            Toggle(isOn: biometryEnabledBinding) {
                                VStack(alignment: .leading, spacing: AppUI.Spacing.xSmall) {
                                    Text(languageManager.string(biometryToggleKey))
                                        .font(.subheadline.weight(.semibold))
                                    Text(biometryAvailabilityText)
                                        .font(.caption)
                                        .foregroundStyle(AppUI.Colors.secondaryText)
                                }
                            }
                            .tint(AppUI.Colors.accent)
                            .disabled(!securityManager.isPINEnabled || !securityManager.isBiometryAvailable)

                            Toggle(languageManager.string(L.securityLockOnLaunch), isOn: lockOnLaunchBinding)
                                .font(.subheadline.weight(.semibold))
                                .tint(AppUI.Colors.accent)
                                .disabled(!securityManager.isPINEnabled)

                            VStack(alignment: .leading, spacing: AppUI.Spacing.small) {
                                Text(languageManager.string(L.securityLockAfterBackground))
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(AppUI.Colors.primaryText)

                                Picker("", selection: lockDelayBinding) {
                                    ForEach(AppLockDelay.allCases) { delay in
                                        Text(languageManager.string(delay.localizedTitleKey))
                                            .tag(delay)
                                    }
                                }
                                .pickerStyle(.menu)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .premiumControlBackground()
                                .disabled(!securityManager.isPINEnabled)

                                if !securityManager.isPINEnabled {
                                    Text(languageManager.string(L.securityAvailableAfterPIN))
                                        .font(.caption)
                                        .foregroundStyle(AppUI.Colors.secondaryText)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, AppUI.pagePadding)
                .padding(.top, AppUI.Spacing.large)
                .padding(.bottom, AppUI.bottomPadding)
            }
        }
        .navigationTitle(languageManager.string(L.securityTitle))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $pinSetupMode) { mode in
            NavigationStack {
                PINSetupView(mode: mode) { _ in
                    showSuccessConfirmation(L.securityPINSaved)
                }
            }
        }
        .task {
            securityManager.refreshBiometryAvailability()
        }
        .autoDismissMessage($statusMessage)
    }

    private var pinEnabledBinding: Binding<Bool> {
        Binding(
            get: { securityManager.isPINEnabled },
            set: { isEnabled in
                if isEnabled {
                    pinSetupMode = .enable
                } else {
                    securityManager.disablePIN()
                    showSuccessConfirmation()
                }
            }
        )
    }

    private var biometryEnabledBinding: Binding<Bool> {
        Binding(
            get: { securityManager.isBiometryEnabled },
            set: {
                securityManager.isBiometryEnabled = $0
                showSuccessConfirmation()
            }
        )
    }

    private var lockOnLaunchBinding: Binding<Bool> {
        Binding(
            get: { securityManager.locksOnLaunch },
            set: {
                securityManager.locksOnLaunch = $0
                showSuccessConfirmation()
            }
        )
    }

    private var lockDelayBinding: Binding<AppLockDelay> {
        Binding(
            get: { securityManager.lockDelay },
            set: {
                securityManager.lockDelay = $0
                showSuccessConfirmation()
            }
        )
    }

    private var biometryToggleKey: LocalizedTextKey {
        switch securityManager.biometryType {
        case .touchID:
            return L.securityUseTouchID
        default:
            return L.securityUseFaceID
        }
    }

    private var biometryAvailabilityText: String {
        securityManager.isBiometryAvailable
            ? languageManager.string(biometryToggleKey)
            : languageManager.string(L.securityBiometryUnavailable)
    }

    private func statusCard(_ message: String) -> some View {
        GlassSurface(isElevated: false) {
            Label(message, systemImage: "checkmark.circle.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppUI.Colors.secondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func showSuccessConfirmation(_ messageKey: LocalizedTextKey = L.settingsSaveSuccess) {
        statusMessage = nil
        toastManager.show(AppToast(message: languageManager.string(messageKey), kind: .success))
    }
}

enum PINSetupMode: String, Identifiable {
    case enable
    case change

    var id: String { rawValue }
}

private struct PINSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(LanguageManager.self) private var languageManager
    @Environment(SecurityManager.self) private var securityManager

    let mode: PINSetupMode
    let onComplete: (String) -> Void

    @State private var currentPIN = ""
    @State private var newPIN = ""
    @State private var repeatedPIN = ""
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView {
                GlassSurface {
                    VStack(alignment: .leading, spacing: AppUI.contentSpacing) {
                        SectionHeader(title: title)

                        if mode == .change {
                            pinField(title: languageManager.string(L.securityEnterPIN), text: $currentPIN)
                        }

                        pinField(title: languageManager.string(L.securityPINCode), text: $newPIN)
                        pinField(title: languageManager.string(L.securityRepeatPIN), text: $repeatedPIN)

                        if let errorMessage {
                            Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.red)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        PrimaryActionButton(
                            title: languageManager.string(L.commonSave),
                            systemImage: "checkmark",
                            isDisabled: !canSave
                        ) {
                            savePIN()
                        }
                    }
                }
                .padding(.horizontal, AppUI.pagePadding)
                .padding(.top, AppUI.Spacing.large)
                .padding(.bottom, AppUI.bottomPadding)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(languageManager.string(L.commonCancel)) {
                    dismiss()
                }
            }
        }
    }

    private var title: String {
        mode == .enable
            ? languageManager.string(L.securityEnablePIN)
            : languageManager.string(L.securityChangePIN)
    }

    private var canSave: Bool {
        newPIN.count == 4 && repeatedPIN.count == 4 && (mode == .enable || currentPIN.count == 4)
    }

    private func pinField(title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: AppUI.Spacing.small) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppUI.Colors.primaryText)

            SecureField(title, text: text)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .onChange(of: text.wrappedValue) { _, newValue in
                    text.wrappedValue = sanitizedPIN(newValue)
                    errorMessage = nil
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .premiumControlBackground()
        }
    }

    private func savePIN() {
        guard newPIN == repeatedPIN else {
            errorMessage = languageManager.string(L.securityPINMismatch)
            return
        }

        do {
            switch mode {
            case .enable:
                try securityManager.enablePIN(newPIN)
            case .change:
                guard try securityManager.updatePIN(currentPIN: currentPIN, newPIN: newPIN) else {
                    errorMessage = languageManager.string(L.securityWrongPIN)
                    return
                }
            }

            onComplete(languageManager.string(L.settingsSaveSuccess))
            dismiss()
        } catch {
            errorMessage = languageManager.string(L.securityWrongPIN)
        }
    }

    private func sanitizedPIN(_ value: String) -> String {
        String(value.filter(\.isNumber).prefix(4))
    }
}
