import SwiftUI

enum AuraTheme {
    static let accent = Color(red: 0.12, green: 0.47, blue: 0.95)
    static let success = Color(red: 0.18, green: 0.68, blue: 0.36)
    static let warning = Color(red: 0.95, green: 0.62, blue: 0.16)
    static let danger = Color(red: 0.92, green: 0.23, blue: 0.28)
    static let surface = Color(nsColor: .controlBackgroundColor)
    static let elevatedSurface = Color(nsColor: .windowBackgroundColor)
    static let separator = Color(nsColor: .separatorColor)

    static func statusColor(_ status: AuraRuntimeStatus) -> Color {
        switch status {
        case .running:
            success
        case .paused:
            warning
        case .unhealthy:
            danger
        case .stopped:
            .secondary
        }
    }
}

struct AuraPage: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Color(nsColor: .textBackgroundColor).opacity(0.32))
    }
}

extension View {
    func auraPage() -> some View {
        modifier(AuraPage())
    }
}

struct AuraSurface<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(.regularMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(AuraTheme.separator.opacity(0.35), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct AuraSectionHeader: View {
    let title: String
    let subtitle: String?
    let systemImage: String?

    init(_ title: String, subtitle: String? = nil, systemImage: String? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            if let systemImage {
                Image(systemName: systemImage)
                    .foregroundStyle(AuraTheme.accent)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
    }
}

struct AuraMetricCard: View {
    let title: String
    let value: String
    let detail: String
    let systemImage: String
    let tint: Color

    var body: some View {
        AuraSurface {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Image(systemName: systemImage)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(tint)
                        .frame(width: 28, height: 28)
                        .background(tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                    Spacer()
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(value)
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                    Text(title)
                        .font(.subheadline.weight(.medium))
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .padding(16)
        }
        .frame(minHeight: 132)
    }
}

struct AuraStatusBadge: View {
    let status: AuraRuntimeStatus

    var body: some View {
        let color = AuraTheme.statusColor(status)
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(status.badgeLabel)
                .font(.caption.weight(.medium))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.13), in: Capsule())
        .foregroundStyle(color)
    }
}

struct AuraEmptyState: View {
    let title: String
    let message: String
    let systemImage: String

    var body: some View {
        AuraSurface {
            VStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 30, weight: .regular))
                    .foregroundStyle(.secondary)
                Text(title)
                    .font(.headline)
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 360)
            }
            .frame(maxWidth: .infinity, minHeight: 220)
            .padding(22)
        }
    }
}

struct AuraTableHeader: View {
    let columns: [String]

    var body: some View {
        HStack(spacing: 12) {
            ForEach(columns, id: \.self) { column in
                Text(column.uppercased())
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(AuraTheme.surface.opacity(0.55))
    }
}

struct AuraCompactButtonStyle: ButtonStyle {
    var prominent = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.medium))
            .padding(.horizontal, 11)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(prominent ? AuraTheme.accent.opacity(configuration.isPressed ? 0.75 : 0.95) : Color.secondary.opacity(configuration.isPressed ? 0.18 : 0.10))
            )
            .foregroundStyle(prominent ? .white : .primary)
    }
}
