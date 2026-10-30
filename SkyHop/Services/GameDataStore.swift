import Foundation
import Combine

/// Summary returned when a run ends, powering Game Over animations and unlock banners.
struct RunSummary: Equatable {
    let score: Int
    let bestScore: Int
    let previousBestScore: Int
    let isNewBest: Bool
    let medal: SkyMedal
    let newlyUnlockedSkins: [CharacterSkin]
}

/// Manages persistent high scores, lifetime statistics, skin unlocks, and user settings.
@MainActor
final class GameDataStore: ObservableObject {
    private enum Keys {
        static let bestScore = "skyhop.bestScore"
        static let totalGatesPassed = "skyhop.totalGatesPassed"
        static let gamesPlayed = "skyhop.gamesPlayed"
        static let selectedSkinID = "skyhop.selectedSkinID"
        static let settings = "skyhop.settings"
    }

    private let defaults: UserDefaults

    @Published private(set) var bestScore: Int
    @Published private(set) var totalGatesPassed: Int
    @Published private(set) var gamesPlayed: Int
    @Published private(set) var selectedSkinID: String
    @Published var settings: GameSettings {
        didSet {
            saveSettings()
        }
    }

    var selectedSkin: CharacterSkin {
        let skin = CharacterSkin.skin(withID: selectedSkinID)
        return isSkinUnlocked(skin) ? skin : CharacterSkin.defaultSkin
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.bestScore = defaults.integer(forKey: Keys.bestScore)
        self.totalGatesPassed = defaults.integer(forKey: Keys.totalGatesPassed)
        self.gamesPlayed = defaults.integer(forKey: Keys.gamesPlayed)
        self.selectedSkinID = defaults.string(forKey: Keys.selectedSkinID) ?? CharacterSkin.defaultSkin.id

        if let data = defaults.data(forKey: Keys.settings),
           let decoded = try? JSONDecoder().decode(GameSettings.self, from: data) {
            self.settings = decoded
        } else {
            self.settings = GameSettings()
        }
    }

    func isSkinUnlocked(_ skin: CharacterSkin) -> Bool {
        skin.isUnlocked(bestScore: bestScore, totalGates: totalGatesPassed)
    }

    func selectSkin(_ skin: CharacterSkin) {
        guard isSkinUnlocked(skin) else { return }
        selectedSkinID = skin.id
        defaults.set(skin.id, forKey: Keys.selectedSkinID)
    }

    /// Persists run results and checks for new high scores and newly unlocked creature skins.
    func recordCompletedRun(score: Int) -> RunSummary {
        let previouslyUnlocked = Set(
            CharacterSkin.allSkins
                .filter { $0.isUnlocked(bestScore: bestScore, totalGates: totalGatesPassed) }
                .map(\.id)
        )

        let previousBest = bestScore
        let isNewBest = score > previousBest
        if isNewBest {
            bestScore = score
            defaults.set(bestScore, forKey: Keys.bestScore)
        }

        if score > 0 {
            totalGatesPassed += score
            defaults.set(totalGatesPassed, forKey: Keys.totalGatesPassed)
        }

        gamesPlayed += 1
        defaults.set(gamesPlayed, forKey: Keys.gamesPlayed)

        let newlyUnlocked = CharacterSkin.allSkins.filter { skin in
            !previouslyUnlocked.contains(skin.id) &&
            skin.isUnlocked(bestScore: bestScore, totalGates: totalGatesPassed)
        }

        return RunSummary(
            score: score,
            bestScore: bestScore,
            previousBestScore: previousBest,
            isNewBest: isNewBest,
            medal: SkyMedal.earned(for: score),
            newlyUnlockedSkins: newlyUnlocked
        )
    }

    func resetHighScoresAndUnlocks() {
        bestScore = 0
        totalGatesPassed = 0
        gamesPlayed = 0
        selectedSkinID = CharacterSkin.defaultSkin.id

        defaults.set(0, forKey: Keys.bestScore)
        defaults.set(0, forKey: Keys.totalGatesPassed)
        defaults.set(0, forKey: Keys.gamesPlayed)
        defaults.set(selectedSkinID, forKey: Keys.selectedSkinID)
    }

    private func saveSettings() {
        if let encoded = try? JSONEncoder().encode(settings) {
            defaults.set(encoded, forKey: Keys.settings)
        }
    }
}

