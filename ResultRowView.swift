import SwiftUI

struct ResultRowView: View {
    let result: SearchResult
    let isSelected: Bool
    @ObservedObject var settings = AppSettings.shared

    var body: some View {
        HStack(spacing: 14) {
            if settings.showIcons {
                if let icon = result.icon {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: 30, height: 30)
                } else {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(.secondary.opacity(0.2))
                        .frame(width: 30, height: 30)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(result.title)
                    .font(.glint(settings.fontFamily, size: settings.fontSize * 0.62, weight: .medium))
                    .lineLimit(1)
                Text(result.subtitle)
                    .font(.glint(settings.fontFamily, size: settings.fontSize * 0.44))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Text(result.category.label)
                .font(.system(size: settings.fontSize * 0.38, weight: .medium))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    Capsule().fill(.secondary.opacity(0.12))
                )
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isSelected ? settings.tintColor.opacity(0.28) : .clear)
        )
        .contentShape(Rectangle())
    }
}
