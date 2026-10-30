import CoreGraphics

/// Encapsulates physics parameters and progressive difficulty scaling
/// normalized to the 956pt logical scene height (iPhone 16 Pro Max portrait height).
struct DifficultyProfile {
    /// Reference vertical height in scene coordinates (matches iPhone 16 Pro Max 956pt height).
    static let referenceSceneHeight: CGFloat = 956.0

    /// Height of the scrolling foreground cliff/grass ground layer.
    static let groundHeight: CGFloat = 132.0

    /// Horizontal width of each Wind Gate spire obstacle.
    static let obstacleWidth: CGFloat = 76.0

    /// Visual radius of the player character body.
    static let playerVisualRadius: CGFloat = 22.0

    /// Slightly forgiving collision radius (~82% of visual radius) for responsive arcade feel.
    static let playerHitboxRadius: CGFloat = 18.0

    let scrollSpeed: CGFloat
    let gapHeight: CGFloat
    let horizontalSpacing: CGFloat
    let movingGateProbability: Double
    let verticalOscillationAmplitude: CGFloat
    let verticalOscillationSpeed: CGFloat
    let gravity: CGFloat
    let hopImpulseVelocity: CGFloat
    let terminalFallVelocity: CGFloat

    /// Computes fair, progressively challenging gameplay parameters for a given score.
    static func evaluate(forScore score: Int, relaxedMode: Bool) -> DifficultyProfile {
        // Normalized progression factor from 0.0 (score 0) to 1.0 (score 45+)
        let clampedScore = CGFloat(min(max(score, 0), 48))
        let progress = clampedScore / 48.0

        // Smooth ease-out curve so early ramp is noticeable and high-score speed stays fair
        let eased = 1.0 - pow(1.0 - progress, 1.45)

        let baseSpeed: CGFloat = relaxedMode ? 190.0 : 220.0
        let maxSpeed: CGFloat = relaxedMode ? 275.0 : 330.0
        let scrollSpeed = baseSpeed + (maxSpeed - baseSpeed) * eased

        let startGap: CGFloat = relaxedMode ? 268.0 : 228.0
        let minGap: CGFloat = relaxedMode ? 216.0 : 176.0
        let gapHeight = startGap - (startGap - minGap) * eased

        // Maintain fair time-between-gates so fast speeds don't create impossible vertical climbs
        let baseSpacing: CGFloat = 305.0
        let maxSpacing: CGFloat = 345.0
        let horizontalSpacing = baseSpacing + (maxSpacing - baseSpacing) * eased

        // Introduce gently bobbing floating Wind Gates starting at score 10
        let movingChance: Double
        if score < 10 {
            movingChance = 0.0
        } else if score < 20 {
            movingChance = relaxedMode ? 0.20 : 0.35
        } else if score < 35 {
            movingChance = relaxedMode ? 0.35 : 0.55
        } else {
            movingChance = relaxedMode ? 0.45 : 0.72
        }

        let oscAmplitude: CGFloat = score < 10 ? 0.0 : (22.0 + 26.0 * eased) * (relaxedMode ? 0.70 : 1.0)
        let oscSpeed: CGFloat = 1.35 + 0.85 * eased

        let gravity: CGFloat = relaxedMode ? -1260.0 : -1520.0
        let hopVelocity: CGFloat = relaxedMode ? 495.0 : 545.0
        let maxFall: CGFloat = relaxedMode ? -660.0 : -790.0

        return DifficultyProfile(
            scrollSpeed: scrollSpeed,
            gapHeight: gapHeight,
            horizontalSpacing: horizontalSpacing,
            movingGateProbability: movingChance,
            verticalOscillationAmplitude: oscAmplitude,
            verticalOscillationSpeed: oscSpeed,
            gravity: gravity,
            hopImpulseVelocity: hopVelocity,
            terminalFallVelocity: maxFall
        )
    }

    /// Human-readable difficulty tier label for HUD callouts and accessibility.
    static func tierName(forScore score: Int) -> String {
        switch score {
        case 0..<8: return "Morning Breeze"
        case 8..<18: return "Rising Thermal"
        case 18..<32: return "Gale Currents"
        case 32..<48: return "Twilight Jetstream"
        default: return "Stratosphere Master"
        }
    }
}

