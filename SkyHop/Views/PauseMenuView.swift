import SwiftUI

/// Pause overlay allowing players to resume with a smooth countdown, restart, adjust settings, or exit.
struct PauseMenuView: View {
    @ObservedObject var controller: GameController
    @ObservedObject var dataStore: GameDataStore

    var body: some View {
        ZStack {
            Color.black.opacity(0.42)
                .ignoresSafeArea()

            GlassCard(highContrast: dataStore.settings.highContrastMode) {
                VStack(spacing: 20) {
                    VStack(spacing: 4) {
                        Text("GAME PAUSED")
                            .font(.system(.title, design: .rounded, weight: .black))
                            .foregroundStyle(.white)

                        Text("Current Score: \(controller.score)  •  Best: \(dataStore.bestScore)")
                            .font(.system(.subheadline, design: .rounded, weight: .bold))
                            .monospacedDigit()
                            .foregroundStyle(.white.opacity(0.84))
                    }

                    VStack(spacing: 12) {
                        Button {
                            controller.resumeGame()
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "play.fill")
                                Text("RESUME FLIGHT")
                            }
                        }
                        .buttonStyle(ArcadePrimaryButtonStyle(
                            tintTop: Color(red: 0.24, green: 0.84, blue: 0.52),
                            tintBottom: Color(red: 0.12, green: 0.62, blue: 0.38)
                        ))

                        Button {
                            controller.restartGame()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.counterclockwise")
                                Text("Restart")
                            }
                        }
                        .buttonStyle(ArcadeSecondaryButtonStyle(highContrast: dataStore.settings.highContrastMode))

                        Button {
                            AudioManager.shared.play(.button)
                            controller.isShowingSettings = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "slider.horizontal.3")
                                Text("Settings & Accessibility")
                            }
                        }
                        .buttonStyle(ArcadeSecondaryButtonStyle(highContrast: dataStore.settings.highContrastMode))

                        Button {
                            controller.returnToMainMenu()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "house.fill")
                                Text("Main Menu")
                            }
                        }
                        .buttonStyle(ArcadeSecondaryButtonStyle(highContrast: dataStore.settings.highContrastMode))
                    }
                }
            }
            .padding(.horizontal, 26)
        }
        .accessibilityAddTraits(.isModal)
    }
}

