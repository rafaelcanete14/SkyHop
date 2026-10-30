import SwiftUI

/// Displays the medal badge earned for a completed Sky Hop run.
struct MedalBadgeView: View {
    let medal: SkyMedal

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: medal.gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 68, height: 68)
                    .overlay(
                        Circle()
                            .strokeBorder(Color.white.opacity(medal == .none ? 0.25 : 0.75), lineWidth: 2.5)
                    )
                    .shadow(color: .black.opacity(medal == .none ? 0.08 : 0.28), radius: 8, x: 0, y: 4)

                Image(systemName: medal.systemImage)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(medal == .none ? Color.white.opacity(0.45) : Color.white)
                    .shadow(color: .black.opacity(0.22), radius: 2, x: 0, y: 1)
            }

            Text(medal.title)
                .font(.system(.caption, design: .rounded, weight: .bold))
                .foregroundStyle(.white.opacity(0.92))
                .multilineTextAlignment(.center)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Medal: \(medal.title)")
    }
}

