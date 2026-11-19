import SwiftUI

struct MetricTile: View {
    let title: String
    let value: String
    let detail: String?
    let tint: Color

    init(title: String, value: String, detail: String? = nil, tint: Color = .blue) {
        self.title = title
        self.value = value
        self.detail = detail
        self.tint = tint
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppUI.Spacing.small) {
            Capsule()
                .fill(tint)
                .frame(width: 34, height: 4)

            Text(title.uppercased())
                .font(AppUI.Typography.label)
                .foregroundStyle(AppUI.Colors.secondaryText)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Text(value)
                .font(AppUI.Typography.metric)
                .foregroundStyle(AppUI.Colors.primaryText)
                .lineLimit(2)
                .minimumScaleFactor(0.8)

            if let detail {
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(AppUI.Colors.secondaryText)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 132, alignment: .topLeading)
        .padding(AppUI.Spacing.large)
        .background {
            RoundedRectangle(cornerRadius: AppUI.controlRadius, style: .continuous)
                .fill(AppUI.Colors.controlSurface)
                .overlay(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: AppUI.controlRadius, style: .continuous)
                        .fill(tint.opacity(0.08))
                }
        }
        .overlay {
            RoundedRectangle(cornerRadius: AppUI.controlRadius, style: .continuous)
                .strokeBorder(AppUI.Colors.separator.opacity(0.42), lineWidth: 0.6)
        }
        .overlay {
            RoundedRectangle(cornerRadius: AppUI.controlRadius, style: .continuous)
                .strokeBorder(tint.opacity(0.18), lineWidth: 0.5)
        }
    }
}
