import UIKit
import SwiftUI

/// RGBA color components used across both SpriteKit (`UIColor`) and SwiftUI (`Color`).
struct RGBAColor: Equatable, Hashable {
    let red: CGFloat
    let green: CGFloat
    let blue: CGFloat
    let alpha: CGFloat

    init(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat = 1.0) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    var uiColor: UIColor {
        UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }

    var swiftUIColor: Color {
        Color(red: Double(red), green: Double(green), blue: Double(blue), opacity: Double(alpha))
    }
}

/// Visual palette defining an original playable Sky Pufflet skin.
struct SkinPalette: Equatable, Hashable {
    let bodyTop: RGBAColor
    let bodyBottom: RGBAColor
    let belly: RGBAColor
    let wing: RGBAColor
    let crest: RGBAColor
    let beak: RGBAColor
    let cheek: RGBAColor
    let trail: RGBAColor
}

/// Unlockable original creature skins for Sky Hop.
struct CharacterSkin: Identifiable, Equatable, Hashable {
    let id: String
    let name: String
    let subtitle: String
    let requiredBestScore: Int
    let requiredTotalGates: Int
    let palette: SkinPalette

    func isUnlocked(bestScore: Int, totalGates: Int) -> Bool {
        if requiredBestScore == 0 && requiredTotalGates == 0 {
            return true
        }
        return bestScore >= requiredBestScore || totalGates >= requiredTotalGates
    }

    var unlockRequirementText: String {
        if requiredBestScore == 0 && requiredTotalGates == 0 {
            return "Starter Companion"
        }
        return "Best Score \(requiredBestScore) or \(requiredTotalGates) Total Gates"
    }

    static let defaultSkin: CharacterSkin = allSkins[0]

    static func skin(withID id: String) -> CharacterSkin {
        allSkins.first(where: { $0.id == id }) ?? defaultSkin
    }

    static let allSkins: [CharacterSkin] = [
        CharacterSkin(
            id: "sunbeam",
            name: "Sunbeam Puff",
            subtitle: "Cheerful golden sky-hopper born in morning clouds.",
            requiredBestScore: 0,
            requiredTotalGates: 0,
            palette: SkinPalette(
                bodyTop: RGBAColor(1.00, 0.80, 0.24),
                bodyBottom: RGBAColor(0.97, 0.56, 0.16),
                belly: RGBAColor(1.00, 0.96, 0.84),
                wing: RGBAColor(1.00, 0.90, 0.50),
                crest: RGBAColor(0.98, 0.36, 0.30),
                beak: RGBAColor(1.00, 0.48, 0.14),
                cheek: RGBAColor(1.00, 0.45, 0.52, 0.65),
                trail: RGBAColor(1.00, 0.88, 0.46)
            )
        ),
        CharacterSkin(
            id: "azure",
            name: "Azure Breeze",
            subtitle: "Rides high-altitude jetstreams with sapphire wings.",
            requiredBestScore: 5,
            requiredTotalGates: 25,
            palette: SkinPalette(
                bodyTop: RGBAColor(0.30, 0.78, 0.98),
                bodyBottom: RGBAColor(0.14, 0.50, 0.90),
                belly: RGBAColor(0.92, 0.98, 1.00),
                wing: RGBAColor(0.62, 0.90, 1.00),
                crest: RGBAColor(0.16, 0.34, 0.82),
                beak: RGBAColor(1.00, 0.68, 0.22),
                cheek: RGBAColor(0.98, 0.58, 0.74, 0.55),
                trail: RGBAColor(0.56, 0.88, 1.00)
            )
        ),
        CharacterSkin(
            id: "sakura",
            name: "Sakura Petal",
            subtitle: "Glides effortlessly on warm spring blossoms.",
            requiredBestScore: 12,
            requiredTotalGates: 60,
            palette: SkinPalette(
                bodyTop: RGBAColor(1.00, 0.66, 0.80),
                bodyBottom: RGBAColor(0.92, 0.38, 0.62),
                belly: RGBAColor(1.00, 0.94, 0.97),
                wing: RGBAColor(1.00, 0.80, 0.90),
                crest: RGBAColor(0.84, 0.22, 0.50),
                beak: RGBAColor(1.00, 0.64, 0.24),
                cheek: RGBAColor(0.96, 0.28, 0.46, 0.55),
                trail: RGBAColor(1.00, 0.74, 0.86)
            )
        ),
        CharacterSkin(
            id: "emerald",
            name: "Emerald Sprout",
            subtitle: "Guardian spirit of the floating archipelago canopies.",
            requiredBestScore: 20,
            requiredTotalGates: 120,
            palette: SkinPalette(
                bodyTop: RGBAColor(0.34, 0.88, 0.58),
                bodyBottom: RGBAColor(0.14, 0.64, 0.42),
                belly: RGBAColor(0.92, 1.00, 0.90),
                wing: RGBAColor(0.62, 0.96, 0.72),
                crest: RGBAColor(0.98, 0.74, 0.22),
                beak: RGBAColor(1.00, 0.58, 0.18),
                cheek: RGBAColor(1.00, 0.56, 0.56, 0.55),
                trail: RGBAColor(0.55, 0.95, 0.68)
            )
        ),
        CharacterSkin(
            id: "nebula",
            name: "Twilight Nebula",
            subtitle: "Woven from starlight and dusk aurora currents.",
            requiredBestScore: 35,
            requiredTotalGates: 220,
            palette: SkinPalette(
                bodyTop: RGBAColor(0.62, 0.42, 0.98),
                bodyBottom: RGBAColor(0.32, 0.18, 0.72),
                belly: RGBAColor(0.92, 0.88, 1.00),
                wing: RGBAColor(0.38, 0.92, 0.94),
                crest: RGBAColor(0.98, 0.48, 0.88),
                beak: RGBAColor(1.00, 0.78, 0.32),
                cheek: RGBAColor(0.46, 0.94, 0.98, 0.55),
                trail: RGBAColor(0.72, 0.58, 1.00)
            )
        ),
        CharacterSkin(
            id: "phoenix",
            name: "Solar Crest",
            subtitle: "Legendary sky champion trailing radiant embers.",
            requiredBestScore: 50,
            requiredTotalGates: 350,
            palette: SkinPalette(
                bodyTop: RGBAColor(1.00, 0.44, 0.22),
                bodyBottom: RGBAColor(0.84, 0.16, 0.24),
                belly: RGBAColor(1.00, 0.92, 0.68),
                wing: RGBAColor(1.00, 0.76, 0.24),
                crest: RGBAColor(1.00, 0.90, 0.30),
                beak: RGBAColor(1.00, 0.82, 0.28),
                cheek: RGBAColor(1.00, 0.76, 0.32, 0.60),
                trail: RGBAColor(1.00, 0.58, 0.22)
            )
        )
    ]
}

