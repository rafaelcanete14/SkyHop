import SwiftUI

/// Safe-area-aware Main Menu overlay rendered over the live parallax SpriteKit sky.
struct MainMenuView: View {
    @ObservedObject var controller: GameController
    @ObservedObject var dataStore: GameDataStore

    private var unlockedSkinsCount: Int {
        CharacterSkin.allSkins.filter { dataStore.isSkinUnlocked($0) }.count
    }

    var body: some View {
        VStack(spacing: 0) {
            // Top bar with Settings shortcut safely below Dynamic Island
            HStack {
                if dataStore.settings.relaxedFlightMode {
                    Label("Relaxed Flight", systemImage: "leaf.fill")
                        .font(.system(.caption, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Capsule().fill(Color.green.opacity(0.75)))
                        .accessibilityLabel("Relaxed Flight Mode Enabled")
                }

                Spacer()

                Button {
                    AudioManager.shared.play(.button)
                    controller.isShowingSettings = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 48, height: 48)
                        .background(Circle().fill(Color.black.opacity(0.28)))
                        .overlay(Circle().strokeBorder(Color.white.opacity(0.45), lineWidth: 1.5))
                }
                .accessibilityLabel("Settings and Accessibility")
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)

            // Stylized game logo
            VStack(spacing: 6) {
                Text("SKY HOP")
                    .font(.system(size: 52, weight: .black, design: .rounded))
                    .tracking(1.5)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, Color(red: 1.0, green: 0.94, blue: 0.72)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: Color(red: 0.10, green: 0.32, blue: 0.62).opacity(0.75), radius: 0, x: 0, y: 5)
                    .shadow(color: .black.opacity(0.30), radius: 12, x: 0, y: 8)

                Text("WIND GATE ARCHIPELAGO")
                    .font(.system(.caption, design: .rounded, weight: .heavy))
                    .tracking(2.4)
                    .foregroundStyle(.white.opacity(0.92))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Color.black.opacity(0.22)))
            }
            .padding(.top, 18)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Sky Hop: Wind Gate Archipelago")

            // Leave open center window so the live hovering Sky Pufflet in SpriteKit shines through
            Spacer()

            // Bottom action card safely above Home Indicator
            GlassCard(highContrast: dataStore.settings.highContrastMode) {
                VStack(spacing: 16) {
                    // Best Score & Active Companion summary row
                    HStack(spacing: 14) {
                        HStack(spacing: 10) {
                            Image(systemName: "trophy.fill")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(Color(red: 1.0, green: 0.84, blue: 0.24))

                            VStack(alignment: .leading, spacing: 2) {
                                Text("BEST SCORE")
                                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.72))
                                Text("\(dataStore.bestScore)")
                                    .font(.system(.title2, design: .rounded, weight: .black))
                                    .monospacedDigit()
                                    .foregroundStyle(.white)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Best Score \(dataStore.bestScore)")

                        Divider()
                            .frame(height: 36)
                            .overlay(Color.white.opacity(0.3))

                        HStack(spacing: 8) {
                            Image(uiImage: TextureFactory.shared.previewImage(for: dataStore.selectedSkin))
                                .resizable()
                                .interpolation(.high)
                                .scaledToFit()
                                .frame(width: 42, height: 35)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("COMPANION")
                                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.72))
                                Text(dataStore.selectedSkin.name)
                                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Button {
                        controller.startGameFromMenu()
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "play.fill")
                            Text("TAP TO FLY")
                        }
                    }
                    .buttonStyle(ArcadePrimaryButtonStyle())
                    .accessibilityHint("Starts a new Sky Hop flight")

                    HStack(spacing: 12) {
                        Button {
                            AudioManager.shared.play(.button)
                            controller.isShowingSkins = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "sparkles")
                                Text("Skins (\(unlockedSkinsCount)/\(CharacterSkin.allSkins.count))")
                            }
                        }
                        .buttonStyle(ArcadeSecondaryButtonStyle(highContrast: dataStore.settings.highContrastMode))
                        .accessibilityLabel("Character Skins, \(unlockedSkinsCount) of \(CharacterSkin.allSkins.count) unlocked")

                        Button {
                            AudioManager.shared.play(.button)
                            controller.isShowingSettings = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "slider.horizontal.3")
                                Text("Options")
                            }
                        }
                        .buttonStyle(ArcadeSecondaryButtonStyle(highContrast: dataStore.settings.highContrastMode))
                        .accessibilityLabel("Options and Accessibility")
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 18)
        }
    }
}

