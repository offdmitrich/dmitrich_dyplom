import SwiftUI
import UIKit

enum AppUI {
    enum Spacing {
        static let xSmall: CGFloat = 4
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let xLarge: CGFloat = 20
        static let xxLarge: CGFloat = 28
        static let page: CGFloat = 20
        static let top: CGFloat = 16
        static let bottom: CGFloat = 32
    }

    enum Radius {
        static let small: CGFloat = 12
        static let medium: CGFloat = 16
        static let large: CGFloat = 20
        static let xLarge: CGFloat = 24
        static let pill: CGFloat = 999
    }

    enum Colors {
        static let accent = Color(
            uiColor: UIColor { traits in
                traits.userInterfaceStyle == .dark
                    ? UIColor(red: 0.28, green: 0.56, blue: 1.00, alpha: 1.0)
                    : UIColor(red: 0.07, green: 0.36, blue: 0.82, alpha: 1.0)
            }
        )
        static let accentSoft = Color(
            uiColor: UIColor { traits in
                traits.userInterfaceStyle == .dark
                    ? UIColor(red: 0.10, green: 0.20, blue: 0.34, alpha: 1.0)
                    : UIColor(red: 0.83, green: 0.90, blue: 1.0, alpha: 1.0)
            }
        )

        static let primaryText = Color(
            uiColor: UIColor { traits in
                traits.userInterfaceStyle == .dark
                    ? UIColor(red: 0.96, green: 0.97, blue: 0.98, alpha: 1.0)
                    : UIColor.label
            }
        )
        static let secondaryText = Color(
            uiColor: UIColor { traits in
                traits.userInterfaceStyle == .dark
                    ? UIColor(red: 0.78, green: 0.80, blue: 0.84, alpha: 1.0)
                    : UIColor.secondaryLabel
            }
        )
        static let tertiaryText = Color(
            uiColor: UIColor { traits in
                traits.userInterfaceStyle == .dark
                    ? UIColor(red: 0.65, green: 0.68, blue: 0.72, alpha: 1.0)
                    : UIColor.tertiaryLabel
            }
        )

        static let pageBackground = Color(
            uiColor: UIColor { traits in
                traits.userInterfaceStyle == .dark
                    ? UIColor(red: 0.07, green: 0.08, blue: 0.09, alpha: 1.0)
                    : UIColor.systemGroupedBackground
            }
        )
        static let pageBackgroundElevated = Color(
            uiColor: UIColor { traits in
                traits.userInterfaceStyle == .dark
                    ? UIColor(red: 0.09, green: 0.10, blue: 0.12, alpha: 1.0)
                    : UIColor.secondarySystemGroupedBackground
            }
        )
        static let surface = Color(
            uiColor: UIColor { traits in
                traits.userInterfaceStyle == .dark
                    ? UIColor(red: 0.14, green: 0.15, blue: 0.17, alpha: 1.0)
                    : UIColor.secondarySystemGroupedBackground
            }
        )
        static let surfaceElevated = Color(
            uiColor: UIColor { traits in
                traits.userInterfaceStyle == .dark
                    ? UIColor(red: 0.15, green: 0.17, blue: 0.19, alpha: 1.0)
                    : UIColor.systemBackground
            }
        )
        static let controlSurface = Color(
            uiColor: UIColor { traits in
                traits.userInterfaceStyle == .dark
                    ? UIColor(red: 0.17, green: 0.19, blue: 0.21, alpha: 1.0)
                    : UIColor.tertiarySystemGroupedBackground
            }
        )
        static let separator = Color(
            uiColor: UIColor { traits in
                traits.userInterfaceStyle == .dark
                    ? UIColor(white: 1.0, alpha: 0.34)
                    : UIColor.separator
            }
        )
        static let navigationBar = Color(
            uiColor: UIColor { traits in
                traits.userInterfaceStyle == .dark
                    ? UIColor(red: 0.09, green: 0.10, blue: 0.12, alpha: 1.0)
                    : UIColor.systemBackground
            }
        )
        static let tabBar = Color(
            uiColor: UIColor { traits in
                traits.userInterfaceStyle == .dark
                    ? UIColor(red: 0.09, green: 0.10, blue: 0.12, alpha: 1.0)
                    : UIColor.systemBackground
            }
        )
        static let chromeSeparator = separator.opacity(0.28)
        static let cardShadow = Color(
            uiColor: UIColor { traits in
                traits.userInterfaceStyle == .dark
                    ? UIColor(white: 0.0, alpha: 0.34)
                    : UIColor(white: 0.0, alpha: 0.14)
            }
        )
    }

    enum Typography {
        static let hero = Font.system(.largeTitle, design: .rounded, weight: .bold)
        static let sectionTitle = Font.title3.weight(.bold)
        static let cardTitle = Font.headline.weight(.semibold)
        static let body = Font.body
        static let secondary = Font.subheadline
        static let label = Font.caption.weight(.semibold)
        static let metric = Font.system(.title, design: .rounded, weight: .bold)
    }

    static let pagePadding = Spacing.page
    static let topPadding = Spacing.top
    static let bottomPadding = Spacing.bottom
    static let sectionSpacing = Spacing.xLarge
    static let contentSpacing = Spacing.large
    static let groupSpacing = Spacing.medium
    static let surfaceRadius = Radius.xLarge
    static let controlRadius = Radius.large
    static let badgeRadius = Radius.medium
    static let controlPadding = Spacing.large
}

extension View {
    func glassControlBackground(opacity: Double = 0.44) -> some View {
        premiumControlBackground()
    }

    func premiumControlBackground() -> some View {
        background(AppUI.Colors.controlSurface, in: RoundedRectangle(cornerRadius: AppUI.controlRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: AppUI.controlRadius, style: .continuous)
                    .strokeBorder(AppUI.Colors.separator.opacity(0.58), lineWidth: 0.6)
            }
    }

    func appScreenBackground() -> some View {
        background(AppBackground())
    }

    func dismissKeyboardOnTap() -> some View {
        overlay(KeyboardDismissLayer())
    }
}

extension UIApplication {
    func dismissKeyboard() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

private struct KeyboardDismissLayer: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = KeyboardDismissPassthroughView(frame: .zero)
        view.backgroundColor = .clear
        view.onWindowChanged = { window in
            context.coordinator.attach(to: window)
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        private weak var attachedWindow: UIWindow?
        private var recognizer: UITapGestureRecognizer?

        func attach(to window: UIWindow?) {
            guard attachedWindow !== window else { return }

            if let recognizer, let attachedWindow {
                attachedWindow.removeGestureRecognizer(recognizer)
            }

            attachedWindow = window

            guard let window else {
                recognizer = nil
                return
            }

            let recognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
            recognizer.cancelsTouchesInView = false
            recognizer.delegate = self
            window.addGestureRecognizer(recognizer)
            self.recognizer = recognizer
        }

        @objc func handleTap() {
            UIApplication.shared.dismissKeyboard()
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
            guard let touchedView = touch.view else { return true }
            return !touchedView.isTextInputOrControl
        }
    }
}

private final class KeyboardDismissPassthroughView: UIView {
    var onWindowChanged: ((UIWindow?) -> Void)?

    override func didMoveToWindow() {
        super.didMoveToWindow()
        onWindowChanged?(window)
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        false
    }
}

private extension UIView {
    var isTextInputOrControl: Bool {
        if self is UITextField || self is UITextView || self is UIControl {
            return true
        }

        return superview?.isTextInputOrControl ?? false
    }
}

struct AppBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                AppUI.Colors.pageBackground,
                AppUI.Colors.pageBackgroundElevated
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        .overlay(alignment: .top) {
            VStack(spacing: 0) {
                AppUI.Colors.navigationBar
                    .frame(height: 112)

                LinearGradient(
                    colors: [
                        AppUI.Colors.navigationBar.opacity(0.82),
                        AppUI.Colors.navigationBar.opacity(0.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 28)
            }
                .ignoresSafeArea(edges: .top)
        }
    }
}

struct SectionHeader: View {
    let title: String
    let subtitle: String?

    init(title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppUI.Spacing.xSmall) {
            Text(title)
                .font(AppUI.Typography.sectionTitle)
                .foregroundStyle(AppUI.Colors.primaryText)

            if let subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(AppUI.Typography.secondary)
                    .foregroundStyle(AppUI.Colors.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct EmptyStateView: View {
    let title: String
    let message: String
    let systemImage: String
    let actionTitle: String?
    let action: (() -> Void)?

    init(
        title: String,
        message: String,
        systemImage: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.systemImage = systemImage
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        GlassSurface {
            VStack(alignment: .leading, spacing: AppUI.contentSpacing) {
                Image(systemName: systemImage)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(AppUI.Colors.accent)
                    .frame(width: 44, height: 44)
                    .background(AppUI.Colors.accentSoft.opacity(0.7), in: Circle())

                Text(title)
                    .font(AppUI.Typography.cardTitle)
                    .foregroundStyle(AppUI.Colors.primaryText)

                Text(message)
                    .font(AppUI.Typography.secondary)
                    .foregroundStyle(AppUI.Colors.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)

                if let actionTitle, let action {
                    PrimaryActionButton(title: actionTitle, action: action)
                }
            }
        }
    }
}

struct InfoBadge: View {
    let title: String
    let tint: Color
    var systemImage: String? = nil

    var body: some View {
        Group {
            if let systemImage {
                Label(title, systemImage: systemImage)
            } else {
                Text(title)
            }
        }
        .font(.caption.weight(.semibold))
        .lineLimit(1)
        .minimumScaleFactor(0.85)
        .padding(.horizontal, AppUI.Spacing.medium)
        .padding(.vertical, AppUI.Spacing.small)
        .background(tint.opacity(0.13), in: Capsule())
        .overlay {
            Capsule()
                .strokeBorder(tint.opacity(0.20), lineWidth: 0.5)
        }
        .foregroundStyle(tint)
    }
}

struct EmployeeFilterPicker: View {
    @Environment(LanguageManager.self) private var languageManager

    let titleKey: LocalizedTextKey
    let allEmployeesTitleKey: LocalizedTextKey
    let employees: [Employee]
    @Binding var selectedEmployeeID: UUID?

    var body: some View {
        GlassSurface(isElevated: false, contentPadding: AppUI.Spacing.medium) {
            Menu {
                Button {
                    selectedEmployeeID = nil
                } label: {
                    Label(
                        languageManager.string(allEmployeesTitleKey),
                        systemImage: selectedEmployeeID == nil ? "checkmark" : "person.2"
                    )
                }

                if !employees.isEmpty {
                    Divider()
                }

                ForEach(employees) { employee in
                    Button {
                        selectedEmployeeID = employee.id
                    } label: {
                        Label(
                            employee.fullName,
                            systemImage: selectedEmployeeID == employee.id ? "checkmark" : "person"
                        )
                    }
                }
            } label: {
                HStack(spacing: AppUI.Spacing.medium) {
                    Image(systemName: "person.crop.circle")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(AppUI.Colors.accent)

                    VStack(alignment: .leading, spacing: AppUI.Spacing.xSmall) {
                        Text(languageManager.string(titleKey))
                            .font(AppUI.Typography.label)
                            .foregroundStyle(AppUI.Colors.secondaryText)
                            .textCase(.uppercase)

                        Text(selectedEmployeeTitle)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppUI.Colors.primaryText)
                            .lineLimit(1)
                    }

                    Spacer(minLength: AppUI.Spacing.small)

                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(AppUI.Colors.secondaryText)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private var selectedEmployeeTitle: String {
        guard let selectedEmployeeID,
              let employee = employees.first(where: { $0.id == selectedEmployeeID })
        else {
            return languageManager.string(allEmployeesTitleKey)
        }

        return employee.fullName
    }
}

struct PrimaryActionButton: View {
    let title: String
    var systemImage: String? = nil
    var isDisabled = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            buttonLabel
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(AppUI.Colors.accent, in: RoundedRectangle(cornerRadius: AppUI.controlRadius, style: .continuous))
                .foregroundStyle(.white)
                .shadow(color: AppUI.Colors.accent.opacity(0.22), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.55 : 1.0)
    }

    @ViewBuilder
    private var buttonLabel: some View {
        if let systemImage {
            Label(title, systemImage: systemImage)
                .font(AppUI.Typography.secondary.weight(.semibold))
        } else {
            Text(title)
                .font(AppUI.Typography.secondary.weight(.semibold))
        }
    }
}

struct SecondaryActionButton: View {
    let title: String
    var systemImage: String? = nil
    var isDisabled = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            buttonLabel
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .premiumControlBackground()
                .foregroundStyle(AppUI.Colors.primaryText)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.55 : 1.0)
    }

    @ViewBuilder
    private var buttonLabel: some View {
        if let systemImage {
            Label(title, systemImage: systemImage)
                .font(AppUI.Typography.secondary.weight(.semibold))
        } else {
            Text(title)
                .font(AppUI.Typography.secondary.weight(.semibold))
        }
    }
}

struct DestructiveActionButton: View {
    let title: String
    var systemImage: String? = nil
    var isDisabled = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            buttonLabel
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.red.opacity(0.12), in: RoundedRectangle(cornerRadius: AppUI.controlRadius, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: AppUI.controlRadius, style: .continuous)
                        .strokeBorder(Color.red.opacity(0.22), lineWidth: 0.5)
                }
                .foregroundStyle(.red)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.55 : 1.0)
    }

    @ViewBuilder
    private var buttonLabel: some View {
        if let systemImage {
            Label(title, systemImage: systemImage)
                .font(AppUI.Typography.secondary.weight(.semibold))
        } else {
            Text(title)
                .font(AppUI.Typography.secondary.weight(.semibold))
        }
    }
}
