import SwiftUI

/// End-of-run summary card displaying score, high-score celebrations, earned medal,
/// newly unlocked companion skins, and instant restart controls.
struct GameOverView: View {
    @ObservedObject var controller: GameController
    @ObservedObject var dataStore: GameDataStore

    private var summary: RunSummary {
        controller.lastRunSummary ?? RunSummary(
            score: controller.score,
            bestScore: dataStore.bestScore,
            previousBestScore: dataStore.bestScore,
            isNewBest: false,
            medal: SkyMedal.earned(for: controller.score),
            newlyUnlockedSkins: []
        )
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.44)
                .ignoresSafeArea()

            VStack(spacing: 18) {
                Text("FLIGHT COMPLETE")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .tracking(1.0)
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.38), radius: 8, x: 0, y: 4)

                GlassCard(highContrast: dataStore.settings.highContrastMode) {
                    VStack(spacing: 20) {
                        HStack(spacing: 20) {
                            MedalBadgeView(medal: summary.medal)
                                .frame(width: 108)

                            Divider()
                                .frame(height: 86)
                                .overlay(Color.white.opacity(0.28))

                            VStack(alignment: .leading, spacing: 12) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("SCORE")
                                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                                        .foregroundStyle(.white.opacity(0.72))
                                    Text("\(summary.score)")
                                        .font(.system(size: 38, weight: .black, design: .rounded))
                                        .monospacedDigit()
                                        .foregroundStyle(.white)
                                }
                                .accessibilityElement(children: .combine)
                                .accessibilityLabel("Final Score \(summary.score)")

                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 6) {
                                        Text("BEST")
                                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                                            .foregroundStyle(.white.opacity(0.72))

                                        if summary.isNewBest {
                                            Text("NEW BEST!")
                                                .font(.system(size: 10, weight: .black, design: .rounded))
                                                .foregroundStyle(.black)
                                                .padding(.horizontal, 7)
                                                .padding(.vertical, 3)
                                                .background(
                                                    Capsule()
                                                        .fill(Color(red: 1.0, green: 0.86, blue: 0.24))
                                                )
                                        }
                                    }

                                    Text("\(summary.bestScore)")
                                        .font(.system(.title2, design: .rounded, weight: .black))
                                        .monospacedDigit()
                                        .foregroundStyle(
                                            summary.isNewBest
                                                ? Color(red: 1.0, green: 0.88, blue: 0.34)
                                                : .white
                                        )
                                }
                                .accessibilityElement(children: .combine)
                                .accessibilityLabel(summary.isNewBest ? "New Best Score \(summary.bestScore)" : "Best Score \(summary.bestScore)")
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        // Highlight newly unlocked character skins if a milestone was reached
                        if let unlockedSkin = summary.newlyUnlockedSkins.first {
                            HStack(spacing: 12) {
                                Image(uiImage: TextureFactory.shared.previewImage(for: unlockedSkin))
                                    .resizable()
                                    .interpolation(.high)
                                    .scaledToFit()
                                    .frame(width: 48, height: 40)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("NEW SKIN UNLOCKED!")
                                        .font(.system(size: 11, weight: .black, design: .rounded))
                                        .foregroundStyle(Color(red: 1.0, green: 0.88, blue: 0.36))
                                    Text(unlockedSkin.name)
                                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                                        .foregroundStyle(.white)
                                }

                                Spacer()

                                Button("Equip") {
                                    AudioManager.shared.play(.button)
                                    dataStore.selectSkin(unlockedSkin)
                                }
                                .font(.system(.caption, design: .rounded, weight: .heavy))
                                .foregroundStyle(.black)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(Capsule().fill(Color(red: 1.0, green: 0.86, blue: 0.28)))
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color.white.opacity(0.14))
                            )
                        }

                        VStack(spacing: 12) {
                            Button {
                                controller.restartGame()
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "arrow.clockwise")
                                    Text("PLAY AGAIN")
                                }
                            }
                            .buttonStyle(ArcadePrimaryButtonStyle())
                            .accessibilityHint("Immediately starts a new round")

                            HStack(spacing: 12) {
                                Button {
                                    AudioManager.shared.play(.button)
                                    controller.isShowingSkins = true
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "sparkles")
                                        Text("Skins")
                                    }
                                }
                                .buttonStyle(ArcadeSecondaryButtonStyle(highContrast: dataStore.settings.highContrastMode))

                                Button {
                                    controller.returnToMainMenu()
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "house.fill")
                                        Text("Menu")
                                    }
                                }
                                .buttonStyle(ArcadeSecondaryButtonStyle(highContrast: dataStore.settings.highContrastMode))
                            }
                        }
                    }
                }
                .padding(.horizontal, 22)
            }
        }
        .accessibilityAddTraits(.isModal)
    }
}

