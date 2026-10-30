import SwiftUI

/// Settings and Accessibility configuration sheet with audio controls, haptics,
/// ergonomic HUD placement, visual clarity modes, and progress management.
struct SettingsView: View {
    @ObservedObject var dataStore: GameDataStore
    @Environment(\.dismiss) private var dismiss
    @State private var showResetConfirmation: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle(isOn: $dataStore.settings.soundEffectsEnabled) {
                        Label("Sound Effects", systemImage: "speaker.wave.2.fill")
                    }

                    if dataStore.settings.soundEffectsEnabled {
                        HStack {
                            Text("SFX Volume")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Slider(value: $dataStore.settings.soundEffectsVolume, in: 0.1...1.0, step: 0.05)
                                .accessibilityLabel("Sound Effects Volume")
                        }
                    }

                    Toggle(isOn: $dataStore.settings.musicEnabled) {
                        Label("Background Music", systemImage: "music.note")
                    }

                    if dataStore.settings.musicEnabled {
                        HStack {
                            Text("Music Volume")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Slider(value: $dataStore.settings.musicVolume, in: 0.1...1.0, step: 0.05)
                                .accessibilityLabel("Background Music Volume")
                        }
                    }

                    Toggle(isOn: $dataStore.settings.hapticsEnabled) {
                        Label("Haptic Feedback", systemImage: "iphone.radiowaves.left.and.right")
                    }
                } header: {
                    Text("Audio & Haptics")
                }

                Section {
                    Toggle(isOn: $dataStore.settings.highContrastMode) {
                        VStack(alignment: .leading, spacing: 2) {
                            Label("High Contrast Graphics", systemImage: "circle.lefthalf.filled")
                            Text("Bold outlines, darker sky, and high-visibility Wind Gates.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Toggle(isOn: $dataStore.settings.reducedMotion) {
                        VStack(alignment: .leading, spacing: 2) {
                            Label("Reduced Motion", systemImage: "sparkles.rectangle.stack")
                            Text("Disables screen shake, particle bursts, and sky color transitions.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Toggle(isOn: $dataStore.settings.relaxedFlightMode) {
                        VStack(alignment: .leading, spacing: 2) {
                            Label("Relaxed Flight (Assist Mode)", systemImage: "leaf.fill")
                            Text("Gentler gravity, slower scroll speed, and wider obstacle gaps.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Toggle(isOn: $dataStore.settings.leftHandedHUD) {
                        VStack(alignment: .leading, spacing: 2) {
                            Label("Left-Handed Pause Button", systemImage: "hand.point.left.fill")
                            Text("Moves the top Pause control to the left corner for easier reach.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Accessibility & Ergonomics")
                }

                Section {
                    LabeledContent("Best Score", value: "\(dataStore.bestScore)")
                    LabeledContent("Total Wind Gates Passed", value: "\(dataStore.totalGatesPassed)")
                    LabeledContent("Flights Played", value: "\(dataStore.gamesPlayed)")

                    Button(role: .destructive) {
                        showResetConfirmation = true
                    } label: {
                        Label("Reset Scores & Unlocks", systemImage: "trash")
                    }
                } header: {
                    Text("Lifetime Statistics")
                }
            }
            .navigationTitle("Options")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        AudioManager.shared.play(.button)
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
            .confirmationDialog(
                "Reset High Score & Unlocks?",
                isPresented: $showResetConfirmation,
                titleVisibility: .visible
            ) {
                Button("Reset All Progress", role: .destructive) {
                    dataStore.resetHighScoresAndUnlocks()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This clears your Best Score, lifetime gate count, and unlocked companion skins. Your accessibility settings will be kept.")
            }
        }
    }
}

