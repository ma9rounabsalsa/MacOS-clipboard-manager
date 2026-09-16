import SwiftUI

struct ClipboardItemRow: View {
    @EnvironmentObject var monitor: ClipboardMonitor
    let item: ClipboardItem
    let isHovered: Bool

    var body: some View {
        HStack(spacing: 10) {
            iconView

            VStack(alignment: .leading, spacing: 2) {
                Text(item.previewText)
                    .font(.system(size: 12.5))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Text(item.relativeTime)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 4)

            if isHovered {
                HStack(spacing: 4) {
                    actionButton(
                        icon: item.isPinned ? "pin.fill" : "pin",
                        tint: item.isPinned ? .orange : .secondary
                    ) {
                        monitor.togglePin(item)
                    }
                    actionButton(icon: "trash", tint: .secondary) {
                        monitor.delete(item)
                    }
                }
            } else if item.isPinned {
                Image(systemName: "pin.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(.orange)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovered ? Color.primary.opacity(0.06) : Color.clear)
        )
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var iconView: some View {
        switch item.type {
        case .color:
            RoundedRectangle(cornerRadius: 6)
                .fill(item.swiftUIColor ?? .gray)
                .frame(width: 26, height: 26)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                )
        case .image:
            if let nsImage = item.nsImage {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 26, height: 26)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                iconBadge(systemName: "photo", color: .purple)
            }
        case .url:
            iconBadge(systemName: "link", color: .blue)
        case .text:
            iconBadge(systemName: "doc.plaintext", color: .gray)
        }
    }

    private func iconBadge(systemName: String, color: Color) -> some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(color.opacity(0.15))
            .frame(width: 26, height: 26)
            .overlay(
                Image(systemName: systemName)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(color)
            )
    }

    private func actionButton(icon: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(tint)
                .frame(width: 20, height: 20)
                .background(Color.primary.opacity(0.08), in: Circle())
        }
        .buttonStyle(.plain)
    }
}
