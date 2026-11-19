import SwiftUI

struct GlassSurface<Content: View>: View {
    private let content: Content
    private let isElevated: Bool
    private let contentPadding: CGFloat

    init(
        isElevated: Bool = true,
        contentPadding: CGFloat = AppUI.Spacing.xLarge,
        @ViewBuilder content: () -> Content
    ) {
        self.isElevated = isElevated
        self.contentPadding = contentPadding
        self.content = content()
    }

    var body: some View {
        content
            .padding(contentPadding)
            .background(surfaceFill, in: RoundedRectangle(cornerRadius: AppUI.surfaceRadius, style: .continuous))
            .background(.thinMaterial.opacity(isElevated ? 0.08 : 0.04), in: RoundedRectangle(cornerRadius: AppUI.surfaceRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: AppUI.surfaceRadius, style: .continuous)
                    .strokeBorder(AppUI.Colors.separator.opacity(isElevated ? 0.56 : 0.46), lineWidth: 0.6)
            }
            .overlay(alignment: .top) {
                RoundedRectangle(cornerRadius: AppUI.surfaceRadius, style: .continuous)
                    .stroke(AppUI.Colors.primaryText.opacity(0.10), lineWidth: 1)
                    .blendMode(.overlay)
            }
            .shadow(color: AppUI.Colors.cardShadow.opacity(isElevated ? 0.65 : 0.35), radius: isElevated ? 18 : 8, x: 0, y: isElevated ? 10 : 4)
    }

    private var surfaceFill: Color {
        isElevated ? AppUI.Colors.surfaceElevated : AppUI.Colors.surface
    }
}
