import Foundation

/// User-configurable audio, haptic, control, and accessibility settings.
struct GameSettings: Codable, Equatable {
    var soundEffectsEnabled: Bool = true
    var soundEffectsVolume: Double = 0.85

    var musicEnabled: Bool = true
    var musicVolume: Double = 0.50

    var hapticsEnabled: Bool = true

    // Accessibility & Comfort
    var highContrastMode: Bool = false
    var reducedMotion: Bool = false
    var relaxedFlightMode: Bool = false
    var leftHandedHUD: Bool = false
}

