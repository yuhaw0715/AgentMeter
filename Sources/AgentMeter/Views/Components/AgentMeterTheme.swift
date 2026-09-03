import SwiftUI
import AppKit

/// Shared visual language for the macOS 26 style surfaces used by the desktop
/// dashboard and the Menu Bar popover.
enum AgentMeterTheme {
    static let contentBackground = Color(nsColor: .controlBackgroundColor)
    static let pageBackground = Color(nsColor: .windowBackgroundColor)
    static let primaryText = Color(nsColor: .labelColor)
    static let secondaryText = Color(nsColor: .secondaryLabelColor)
    static let divider = Color(nsColor: .separatorColor)
    static let track = Color(nsColor: .quaternaryLabelColor)
    static let accent = Color(nsColor: .controlAccentColor)
    static let warning = Color(nsColor: .systemOrange)
    static let destructive = Color(nsColor: .systemRed)
    static let success = Color(nsColor: .systemGreen)

    /// Material is used for hierarchy-level surfaces; quota content remains
    /// on an opaque control surface so percentages stay legible.
    static let glassMaterial: Material = .thin
    static let sidebarMaterial: Material = .regular

    static let cornerRadius: CGFloat = 14
}

struct AgentMeterBrandMark: View {
    var size: CGFloat = 42

    var body: some View {
        Text("AM")
            .font(.system(size: size * 0.43, weight: .black, design: .rounded))
            .tracking(-1.5)
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(
                LinearGradient(
                    colors: [Color(nsColor: .darkGray), Color(nsColor: .black)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: size * 0.28, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                    .stroke(.white.opacity(0.18), lineWidth: 0.5)
            }
            .shadow(color: .black.opacity(0.15), radius: 5, y: 2)
            .accessibilityLabel("AgentMeter")
    }
}

struct AgentMeterStatusPill: View {
    let title: String
    let tint: Color

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(tint)
                .frame(width: 6, height: 6)
            Text(title)
                .font(.caption2.weight(.semibold))
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(tint.opacity(0.12), in: Capsule())
    }
}
