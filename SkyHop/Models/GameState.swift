import SwiftUI

/// Represents the lifecycle state of a Sky Hop gameplay session.
enum PlayPhase: Equatable {
    case menu
    case ready
    case playing
    case paused
    case resuming(Int)
    case dying
    case gameOver
}

/// Medals awarded at the end of a run based on final score.
enum SkyMedal: String, CaseIterable, Identifiable {
    case none
    case bronze
    case silver
    case gold
    case prism

    var id: String { rawValue }

    static func earned(for score: Int) -> SkyMedal {
        switch score {
        case 50...:
            return .prism
        case 30..<50:
            return .gold
        case 15..<30:
            return .silver
        case 5..<15:
            return .bronze
        default:
            return .none
        }
    }

    var title: String {
        switch self {
        case .none: return "No Medal Yet"
        case .bronze: return "Bronze Wing"
        case .silver: return "Silver Breeze"
        case .gold: return "Golden Zephyr"
        case .prism: return "Prism Sky Crown"
        }
    }

    var systemImage: String {
        switch self {
        case .none: return "circle.dashed"
        case .bronze: return "medal.fill"
        case .silver: return "medal.fill"
        case .gold: return "crown.fill"
        case .prism: return "sparkles"
        }
    }

    var gradientColors: [Color] {
        switch self {
        case .none:
            return [Color.gray.opacity(0.35), Color.gray.opacity(0.2)]
        case .bronze:
            return [Color(red: 0.85, green: 0.55, blue: 0.32), Color(red: 0.62, green: 0.34, blue: 0.18)]
        case .silver:
            return [Color(red: 0.90, green: 0.94, blue: 0.98), Color(red: 0.60, green: 0.68, blue: 0.78)]
        case .gold:
            return [Color(red: 1.00, green: 0.86, blue: 0.28), Color(red: 0.92, green: 0.58, blue: 0.10)]
        case .prism:
            return [
                Color(red: 0.42, green: 0.92, blue: 1.00),
                Color(red: 0.76, green: 0.52, blue: 1.00),
                Color(red: 1.00, green: 0.62, blue: 0.80)
            ]
        }
    }
}

/// Physics category bitmasks for SpriteKit contact and collision detection.
struct PhysicsCategory {
    static let none: UInt32      = 0
    static let player: UInt32    = 1 << 0
    static let obstacle: UInt32  = 1 << 1
    static let boundary: UInt32  = 1 << 2
    static let scoreGate: UInt32 = 1 << 3
}

