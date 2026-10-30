import SwiftUI

/// Frosted glassmorphic card container used across menus, pause, and game-over overlays.
struct GlassCard<Content: View>: View {
    let highContrast: Bool
    @ViewBuilder var content: () -> Content

    init(highContrast: Bool = false, @ViewBuilder content: @escaping () -> Content) {
        self.highContrast = highContrast
        self.content = content
    }

    var body: some View {
        content()
            .padding(24)
            .background {
                if highContrast {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(Color(red: 0.08, green: 0.12, blue: 0.22).opacity(0.96))
                } else {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.24), Color.white.opacity(0.04)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .strokeBorder(
                        highContrast ? Color.white : Color.white.opacity(0.45),
                        lineWidth: highContrast ? 2.5 : 1.5
                    )
            )
            .shadow(color: Color.black.opacity(0.24), radius: 22, x: 0, y: 12)
    }
}

/// Prominent tactile arcade call-to-action button style.
struct ArcadePrimaryButtonStyle: ButtonStyle {
    var tintTop: Color = Color(red: 1.00, green: 0.74, blue: 0.18)
    var tintBottom: Color = Color(red: 0.96, green: 0.46, blue: 0.12)

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.title3, design: .rounded, weight: .heavy))
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.28), radius: 2, x: 0, y: 1)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 58)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [tintTop, tintBottom],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.65), lineWidth: 2)
            )
            .shadow(color: tintBottom.opacity(0.45), radius: configuration.isPressed ? 4 : 10, x: 0, y: configuration.isPressed ? 2 : 6)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

/// Secondary translucent button style for menu actions.
struct ArcadeSecondaryButtonStyle: ButtonStyle {
    var highContrast: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.headline, design: .rounded, weight: .bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 52)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(highContrast ? Color.white.opacity(0.22) : Color.black.opacity(0.26))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(
                        highContrast ? Color.white : Color.white.opacity(0.38),
                        lineWidth: highContrast ? 2 : 1.5
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

