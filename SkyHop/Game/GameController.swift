import SwiftUI
import SpriteKit
import UIKit
import Combine

/// Coordinates state transitions between the SpriteKit `GameScene`, persistent `GameDataStore`,
/// audio/haptics services, and SwiftUI overlays.
@MainActor
final class GameController: ObservableObject, GameSceneEventsDelegate {
    @Published private(set) var phase: PlayPhase = .menu
    @Published private(set) var score: Int = 0
    @Published private(set) var lastRunSummary: RunSummary?
    @Published private(set) var milestoneBannerText: String?
    @Published var isShowingSettings: Bool = false
    @Published var isShowingSkins: Bool = false
    @Published private(set) var isSceneViewPausedForBackground: Bool = false

    let dataStore: GameDataStore
    let scene: GameScene

    private var phaseBeforePause: PlayPhase = .playing
    private var resumeCountdownTask: Task<Void, Never>?
    private var dyingTransitionTask: Task<Void, Never>?
    private var bannerDismissTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    init(dataStore: GameDataStore? = nil) {
        self.dataStore = dataStore ?? GameDataStore()
        // Default to iPhone 16 Pro Max logical portrait dimensions (440 x 956 pt)
        self.scene = GameScene(size: CGSize(width: 440, height: 956))
        self.scene.eventsDelegate = self

        syncConfigurationToSystems()
        scene.enterMenuMode()
        AudioManager.shared.startBackgroundMusic()

        // Reactively forward settings and skin changes
        self.dataStore.$settings
            .sink { [weak self] newSettings in
                guard let self else { return }
                AudioManager.shared.apply(settings: newSettings)
                HapticsManager.shared.isEnabled = newSettings.hapticsEnabled
                self.scene.applyConfiguration(settings: newSettings, skin: self.dataStore.selectedSkin)
            }
            .store(in: &cancellables)

        self.dataStore.$selectedSkinID
            .sink { [weak self] _ in
                guard let self else { return }
                self.scene.applyConfiguration(settings: self.dataStore.settings, skin: self.dataStore.selectedSkin)
            }
            .store(in: &cancellables)

        observeAppResignActive()
    }

    func syncConfigurationToSystems() {
        AudioManager.shared.apply(settings: dataStore.settings)
        HapticsManager.shared.isEnabled = dataStore.settings.hapticsEnabled
        scene.applyConfiguration(settings: dataStore.settings, skin: dataStore.selectedSkin)
    }

    // MARK: - User Actions

    func startGameFromMenu() {
        cancelTransientTasks()
        AudioManager.shared.play(.button)
        HapticsManager.shared.prepareForGameplay()
        score = 0
        lastRunSummary = nil
        milestoneBannerText = nil
        phase = .ready
        scene.prepareNewRun()
    }

    func restartGame() {
        cancelTransientTasks()
        AudioManager.shared.play(.button)
        HapticsManager.shared.prepareForGameplay()
        score = 0
        lastRunSummary = nil
        milestoneBannerText = nil
        phase = .ready
        scene.prepareNewRun()
    }

    func pauseGame() {
        guard phase == .playing || phase == .ready || isResumingPhase else { return }
        if phase == .ready {
            phaseBeforePause = .ready
        } else if phase == .playing {
            phaseBeforePause = .playing
        }
        resumeCountdownTask?.cancel()
        resumeCountdownTask = nil
        AudioManager.shared.play(.button)
        phase = .paused
        scene.setPhase(.paused)
    }

    func resumeGame() {
        guard phase == .paused else { return }
        AudioManager.shared.play(.button)
        HapticsManager.shared.prepareForGameplay()

        // If the player hadn't tapped to start flying yet, return straight to `.ready`
        if phaseBeforePause == .ready {
            phase = .ready
            scene.setPhase(.ready)
            return
        }

        // Smooth 3-2-1 countdown so the player has time to position their thumb
        resumeCountdownTask?.cancel()
        resumeCountdownTask = Task { @MainActor [weak self] in
            guard let self else { return }
            for count in stride(from: 3, through: 1, by: -1) {
                self.phase = .resuming(count)
                self.scene.setPhase(.resuming(count))
                HapticsManager.shared.playUISelection()
                try? await Task.sleep(for: .milliseconds(650))
                if Task.isCancelled { return }
            }
            self.phase = .playing
            self.scene.setPhase(.playing)
        }
    }

    func returnToMainMenu() {
        cancelTransientTasks()
        AudioManager.shared.play(.button)
        score = 0
        lastRunSummary = nil
        milestoneBannerText = nil
        phase = .menu
        scene.enterMenuMode()
    }

    // MARK: - ScenePhase & Interruption Handling

    func handleScenePhaseChange(_ newScenePhase: ScenePhase) {
        switch newScenePhase {
        case .active:
            isSceneViewPausedForBackground = false
            AudioManager.shared.resumeBackgroundMusicIfNeeded()
        case .inactive:
            autoPauseIfNeededForInterruption()
        case .background:
            autoPauseIfNeededForInterruption()
            isSceneViewPausedForBackground = true
            AudioManager.shared.pauseBackgroundMusic()
        @unknown default:
            break
        }
    }

    private func observeAppResignActive() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.autoPauseIfNeededForInterruption()
            }
        }
    }

    private func autoPauseIfNeededForInterruption() {
        if phase == .playing || isResumingPhase {
            phaseBeforePause = .playing
            resumeCountdownTask?.cancel()
            resumeCountdownTask = nil
            phase = .paused
            scene.setPhase(.paused)
        }
    }

    private var isResumingPhase: Bool {
        if case .resuming = phase { return true }
        return false
    }

    private func cancelTransientTasks() {
        resumeCountdownTask?.cancel()
        resumeCountdownTask = nil
        dyingTransitionTask?.cancel()
        dyingTransitionTask = nil
        bannerDismissTask?.cancel()
        bannerDismissTask = nil
    }

    // MARK: - GameSceneEventsDelegate

    func gameSceneDidBeginPlaying() {
        phase = .playing
    }

    func gameSceneDidScorePoint(newScore: Int) {
        score = newScore

        if newScore > 0 && newScore % 10 == 0 {
            let tier = DifficultyProfile.tierName(forScore: newScore)
            showMilestoneBanner("\(newScore) STREAK • \(tier.uppercased())")
        }
    }

    func gameSceneDidTriggerCollision(finalScore: Int) {
        phase = .dying
        let summary = dataStore.recordCompletedRun(score: finalScore)
        lastRunSummary = summary

        dyingTransitionTask?.cancel()
        dyingTransitionTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(480))
            guard let self, !Task.isCancelled else { return }
            if !summary.newlyUnlockedSkins.isEmpty {
                AudioManager.shared.play(.unlock)
            }
            withAnimation(.spring(response: 0.42, dampingFraction: 0.80)) {
                self.phase = .gameOver
            }
        }
    }

    private func showMilestoneBanner(_ message: String) {
        bannerDismissTask?.cancel()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
            milestoneBannerText = message
        }
        bannerDismissTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(1.8))
            guard let self, !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.25)) {
                self.milestoneBannerText = nil
            }
        }
    }
}
