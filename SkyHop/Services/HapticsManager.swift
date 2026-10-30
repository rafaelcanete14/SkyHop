import UIKit

/// Provides low-latency Taptic Engine feedback tailored for iPhone gameplay.
@MainActor
final class HapticsManager {
    static let shared = HapticsManager()

    var isEnabled: Bool = true

    private let hopGenerator = UIImpactFeedbackGenerator(style: .light)
    private let scoreGenerator = UIImpactFeedbackGenerator(style: .soft)
    private let collisionGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private let uiGenerator = UISelectionFeedbackGenerator()
    private let notificationGenerator = UINotificationFeedbackGenerator()

    private init() {}

    func prepareForGameplay() {
        guard isEnabled else { return }
        hopGenerator.prepare()
        scoreGenerator.prepare()
        collisionGenerator.prepare()
    }

    func playHop() {
        guard isEnabled else { return }
        hopGenerator.impactOccurred(intensity: 0.72)
        hopGenerator.prepare()
    }

    func playScore() {
        guard isEnabled else { return }
        scoreGenerator.impactOccurred(intensity: 0.65)
        scoreGenerator.prepare()
    }

    func playMilestone() {
        guard isEnabled else { return }
        notificationGenerator.notificationOccurred(.success)
    }

    func playCollision() {
        guard isEnabled else { return }
        collisionGenerator.impactOccurred(intensity: 1.0)
    }

    func playUISelection() {
        guard isEnabled else { return }
        uiGenerator.selectionChanged()
    }
}

