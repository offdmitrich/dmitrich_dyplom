import LocalAuthentication
import SwiftUI

struct LockScreenView: View {
    @Environment(LanguageManager.self) private var languageManager
    @Environment(SecurityManager.self) private var securityManager

    @State private var enteredPIN = ""
    @State private var errorMessage: String?
    @State private var isAuthenticatingBiometrics = false

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: AppUI.Spacing.xLarge) {
                Spacer(minLength: AppUI.Spacing.xxLarge)

                VStack(spacing: AppUI.Spacing.medium) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 44, weight: .semibold))
                        .foregroundStyle(AppUI.Colors.accent)
                        .frame(width: 72, height: 72)
                        .background(AppUI.Colors.accentSoft.opacity(0.72), in: Circle())

                    Text(languageManager.string(L.securityEnterPIN))
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(AppUI.Colors.primaryText)
                }

                pinIndicators

                if let errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.red)
                        .fixedSize(horizontal: false, vertical: true)
                }

                keypad

                if securityManager.canUseBiometryUnlock {
                    SecondaryActionButton(
                        title: languageManager.string(L.securityUnlockWithFaceID),
                        systemImage: biometryIconName,
                        isDisabled: isAuthenticatingBiometrics
                    ) {
                        authenticateWithBiometrics()
                    }
                }

                Spacer(minLength: AppUI.Spacing.large)
            }
            .padding(.horizontal, AppUI.pagePadding)
            .padding(.vertical, AppUI.Spacing.xxLarge)
        }
        .task {
            guard securityManager.canUseBiometryUnlock else { return }
            authenticateWithBiometrics()
        }
    }

    private var pinIndicators: some View {
        HStack(spacing: AppUI.Spacing.medium) {
            ForEach(0..<4, id: \.self) { index in
                Circle()
                    .fill(index < enteredPIN.count ? AppUI.Colors.accent : AppUI.Colors.separator.opacity(0.4))
                    .frame(width: 16, height: 16)
            }
        }
        .accessibilityLabel(languageManager.string(L.securityPINCode))
    }

    private var keypad: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: AppUI.Spacing.medium), count: 3), spacing: AppUI.Spacing.medium) {
            ForEach(1...9, id: \.self) { digit in
                keypadButton("\(digit)") {
                    appendDigit(digit)
                }
            }

            if securityManager.canUseBiometryUnlock {
                keypadIconButton(systemImage: biometryIconName, accessibilityLabel: languageManager.string(L.securityUnlockWithFaceID)) {
                    authenticateWithBiometrics()
                }
            } else {
                Color.clear
                    .frame(height: 64)
            }

            keypadButton("0") {
                appendDigit(0)
            }

            keypadIconButton(systemImage: "delete.left", accessibilityLabel: languageManager.string(L.securityDeleteDigit)) {
                deleteDigit()
            }
        }
        .frame(maxWidth: 320)
    }

    private func keypadButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.title2.weight(.semibold))
                .foregroundStyle(AppUI.Colors.primaryText)
                .frame(maxWidth: .infinity, minHeight: 64)
                .premiumControlBackground()
        }
        .buttonStyle(.plain)
    }

    private func keypadIconButton(systemImage: String, accessibilityLabel: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.title3.weight(.semibold))
                .foregroundStyle(AppUI.Colors.primaryText)
                .frame(maxWidth: .infinity, minHeight: 64)
                .premiumControlBackground()
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }

    private var biometryIconName: String {
        switch securityManager.biometryType {
        case .touchID:
            return "touchid"
        default:
            return "faceid"
        }
    }

    private func appendDigit(_ digit: Int) {
        guard enteredPIN.count < 4 else { return }
        errorMessage = nil
        enteredPIN.append(String(digit))

        if enteredPIN.count == 4 {
            verifyPIN()
        }
    }

    private func deleteDigit() {
        guard !enteredPIN.isEmpty else { return }
        errorMessage = nil
        enteredPIN.removeLast()
    }

    private func verifyPIN() {
        if securityManager.unlock(with: enteredPIN) {
            enteredPIN = ""
        } else {
            errorMessage = languageManager.string(L.securityWrongPIN)
            enteredPIN = ""
        }
    }

    private func authenticateWithBiometrics() {
        guard !isAuthenticatingBiometrics else { return }
        isAuthenticatingBiometrics = true

        Task {
            let didAuthenticate = await securityManager.authenticateWithBiometrics(
                reason: languageManager.string(L.securityUnlockWithFaceID)
            )

            await MainActor.run {
                isAuthenticatingBiometrics = false
                if !didAuthenticate {
                    errorMessage = nil
                }
            }
        }
    }
}
