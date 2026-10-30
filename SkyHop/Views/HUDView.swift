import SwiftUI

/// In-game Heads-Up Display positioned safely clear of the iPhone 16 Pro Max Dynamic Island.
struct HUDView: View {
    @ObservedObject var controller: GameController
    @ObservedObject var dataStore: GameDataStore

    @State private var pulseReadyPrompt: Bool = false

    var body: some View {
        ZStack {
            VStack(spacing: 12) {
                topBar
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                if let banner = controller.milestoneBannerText {
                    Text(banner)
                        .font(.system(.caption, design: .rounded, weight: .heavy))
                        .tracking(1.2)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color(red: 0.14, green: 0.22, blue: 0.42).opacity(0.84))
                        )
                        .overlay(
                            Capsule()
                                .strokeBorder(Color.yellow.opacity(0.75), lineWidth: 1.5)
                        )
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                Spacer()

                if controller.phase == .ready {
                    readyInstructionBadge
                        .padding(.bottom, 150)
                        .allowsHitTesting(false)
                }
            }

            if case .resuming(let count) = controller.phase {
                VStack(spacing: 8) {
                    Text("\(count)")
                        .font(.system(size: 84, weight: .black, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.42), radius: 10, x: 0, y: 5)
                        .contentTransition(.numericText())

                    Text("GET READY")
                        .font(.system(.headline, design: .rounded, weight: .heavy))
                        .tracking(2)
                        .foregroundStyle(.white.opacity(0.92))
                }
                .padding(.horizontal, 36)
                .padding(.vertical, 24)
                .background(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
                .allowsHitTesting(false)
                .accessibilityLabel("Resuming in \(count)")
            }
        }
        // VoiceOver direct tap support for hopping
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private var topBar: some View {
        let leftHanded = dataStore.settings.leftHandedHUD

        HStack {
            if leftHanded {
                pauseButton
                Spacer()
                scoreCounter
                Spacer()
                Color.clear.frame(width: 48, height: 48)
            } else {
                Color.clear.frame(width: 48, height: 48)
                Spacer()
                scoreCounter
                Spacer()
                pauseButton
            }
        }
    }

    private var scoreCounter: some View {
        Text("\(controller.score)")
            .font(.system(size: 54, weight: .black, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.42), radius: 0, x: 0, y: 4)
            .shadow(color: .black.opacity(0.28), radius: 10, x: 0, y: 6)
            .contentTransition(.numericText())
            .animation(.spring(response: 0.24, dampingFraction: 0.68), value: controller.score)
            .allowsHitTesting(false)
            .accessibilityLabel("Score \(controller.score)")
    }

    private var pauseButton: some View {
        Button {
            controller.pauseGame()
        } label: {
            Image(systemName: "pause.fill")
                .font(.system(size: 20, weight: .black))
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(
                    Circle()
                        .fill(Color.black.opacity(dataStore.settings.highContrastMode ? 0.72 : 0.30))
                )
                .overlay(
                    Circle()
                        .strokeBorder(Color.white.opacity(0.65), lineWidth: 1.8)
                )
        }
        .accessibilityLabel("Pause Game")
    }

    private var readyInstructionBadge: some View {
        VStack(spacing: 12) {
            ZStack {
                if !dataStore.settings.reducedMotion {
                    Circle()
                        .stroke(Color.white.opacity(0.65), lineWidth: 2.5)
                        .frame(width: 58, height: 58)
                        .scaleEffect(pulseReadyPrompt ? 1.35 : 0.88)
                        .opacity(pulseReadyPrompt ? 0.0 : 0.85)
                }

                Image(systemName: "hand.tap.fill")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.35), radius: 4, x: 0, y: 2)
            }

            Text("TAP ANYWHERE TO HOP")
                .font(.system(.headline, design: .rounded, weight: .heavy))
                .tracking(1.4)
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(dataStore.settings.highContrastMode ? 0.78 : 0.34))
                )
                .overlay(
                    Capsule()
                        .strokeBorder(Color.white.opacity(0.55), lineWidth: 1.5)
                )
        }
        .onAppear {
            guard !dataStore.settings.reducedMotion else { return }
            withAnimation(.easeOut(duration: 1.25).repeatForever(autoreverses: false)) {
                pulseReadyPrompt = true
            }
        }
    }
}

