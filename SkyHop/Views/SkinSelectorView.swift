import SwiftUI
import UIKit

/// Modal wardrobe sheet showcasing unlockable Sky Pufflet skins and milestone progress.
struct SkinSelectorView: View {
    @ObservedObject var dataStore: GameDataStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Player lifetime unlock progress summary
                    HStack(spacing: 16) {
                        statPill(title: "Best Score", value: "\(dataStore.bestScore)", icon: "trophy.fill", tint: .orange)
                        statPill(title: "Total Gates", value: "\(dataStore.totalGatesPassed)", icon: "wind", tint: .cyan)
                    }
                    .padding(.top, 8)

                    ForEach(CharacterSkin.allSkins) { skin in
                        skinRow(for: skin)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 28)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Sky Companions")
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
        }
    }

    private func statPill(title: String, value: String, icon: String, tint: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(tint)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.system(.title3, design: .rounded, weight: .black))
                    .monospacedDigit()
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
        )
    }

    private func skinRow(for skin: CharacterSkin) -> some View {
        let unlocked = dataStore.isSkinUnlocked(skin)
        let isSelected = dataStore.selectedSkin.id == skin.id

        return Button {
            guard unlocked else { return }
            AudioManager.shared.play(.button)
            HapticsManager.shared.playUISelection()
            dataStore.selectSkin(skin)
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    skin.palette.bodyTop.swiftUIColor.opacity(unlocked ? 0.28 : 0.12),
                                    skin.palette.bodyBottom.swiftUIColor.opacity(unlocked ? 0.14 : 0.06)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 78, height: 72)

                    Image(uiImage: TextureFactory.shared.previewImage(for: skin))
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                        .frame(width: 64, height: 54)
                        .saturation(unlocked ? 1.0 : 0.0)
                        .opacity(unlocked ? 1.0 : 0.45)

                    if !unlocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(6)
                            .background(Circle().fill(Color.black.opacity(0.6)))
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(skin.name)
                            .font(.system(.headline, design: .rounded, weight: .bold))
                            .foregroundStyle(.primary)

                        if isSelected {
                            Text("EQUIPPED")
                                .font(.system(size: 10, weight: .black, design: .rounded))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(Color.accentColor))
                        }
                    }

                    Text(skin.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)

                    if !unlocked {
                        Text(skin.unlockRequirementText)
                            .font(.system(.caption2, design: .rounded, weight: .bold))
                            .foregroundStyle(.orange)
                            .padding(.top, 2)
                    }
                }

                Spacer(minLength: 4)

                Image(systemName: isSelected ? "checkmark.circle.fill" : (unlocked ? "circle" : "lock.circle"))
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary.opacity(0.5))
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .disabled(!unlocked)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(skin.name), \(isSelected ? "Equipped" : (unlocked ? "Unlocked" : "Locked. Requires \(skin.unlockRequirementText)"))")
    }
}

