import SwiftUI
import UIKit

@Observable
@MainActor
final class ToastManager {
    var toast: AppToast?

    @ObservationIgnored private var dismissTask: Task<Void, Never>?

    func show(_ toast: AppToast, durationSeconds: Double = 2.0) {
        dismissTask?.cancel()

        if toast.kind == .success {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
        UIAccessibility.post(notification: .announcement, argument: toast.message)

        withAnimation(.easeOut(duration: 0.22)) {
            self.toast = toast
        }

        dismissTask = Task {
            let nanoseconds = UInt64(durationSeconds * 1_000_000_000)
            try? await Task.sleep(nanoseconds: nanoseconds)

            guard !Task.isCancelled else { return }

            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.24)) {
                    self.toast = nil
                }
            }
        }
    }
}

struct AppToast: Equatable, Identifiable {
    let id = UUID()
    let message: String
    let kind: Kind

    enum Kind {
        case success
        case error
        case info
    }
}

struct AppToastOverlay: View {
    let toast: AppToast?

    var body: some View {
        VStack {
            if let toast {
                toastView(toast)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, AppUI.pagePadding)
        .padding(.top, 14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .animation(.easeInOut(duration: 0.22), value: toast?.id)
        .allowsHitTesting(false)
        .accessibilityHidden(toast == nil)
    }

    private func toastView(_ toast: AppToast) -> some View {
        HStack(spacing: AppUI.Spacing.small) {
            Image(systemName: toast.kind.systemImage)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(toast.kind.tint)

            Text(toast.message)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppUI.Colors.primaryText)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, AppUI.Spacing.medium)
        .padding(.vertical, 12)
        .background {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(AppUI.Colors.surfaceElevated.opacity(0.84))
        }
        .background {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.ultraThinMaterial)
                .opacity(0.82)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(AppUI.Colors.separator.opacity(0.46), lineWidth: 0.6)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(toast.kind.tint.opacity(0.24), lineWidth: 0.8)
        }
        .shadow(color: AppUI.Colors.cardShadow.opacity(0.58), radius: 14, x: 0, y: 8)
        .frame(maxWidth: 360, alignment: .center)
        .allowsHitTesting(false)
    }
}

private extension AppToast.Kind {
    var systemImage: String {
        switch self {
        case .success:
            return "checkmark.circle.fill"
        case .error:
            return "exclamationmark.triangle.fill"
        case .info:
            return "info.circle.fill"
        }
    }

    var tint: Color {
        switch self {
        case .success:
            return .green
        case .error:
            return .orange
        case .info:
            return AppUI.Colors.accent
        }
    }
}

private struct AutoDismissMessageModifier: ViewModifier {
    @Binding var message: String?
    let delaySeconds: Double

    @State private var dismissTask: Task<Void, Never>?

    func body(content: Content) -> some View {
        content
            .animation(.easeInOut(duration: 0.2), value: message)
            .onChange(of: message) { _, newValue in
                scheduleDismiss(for: newValue)
            }
            .onDisappear {
                dismissTask?.cancel()
                dismissTask = nil
                message = nil
            }
    }

    private func scheduleDismiss(for newValue: String?) {
        dismissTask?.cancel()

        guard newValue != nil else {
            dismissTask = nil
            return
        }

        dismissTask = Task {
            let nanoseconds = UInt64(delaySeconds * 1_000_000_000)
            try? await Task.sleep(nanoseconds: nanoseconds)

            guard !Task.isCancelled else { return }

            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.2)) {
                    message = nil
                }
            }
        }
    }
}

extension View {
    func autoDismissMessage(_ message: Binding<String?>, after delaySeconds: Double = 2.5) -> some View {
        modifier(AutoDismissMessageModifier(message: message, delaySeconds: delaySeconds))
    }
}
