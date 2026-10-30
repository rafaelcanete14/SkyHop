import UIKit
import SpriteKit

/// Pose variants rendered for each playable Sky Pufflet skin.
enum PlayerPose: CaseIterable, Hashable {
    case wingUp
    case wingMid
    case wingDown
    case blink
    case collided
}

/// Renders and caches crisp @3x vector-drawn `SKTexture` assets in memory so gameplay runs
/// at 120Hz on iPhone 16 Pro Max without `SKShapeNode` draw-call overhead or external image dependencies.
@MainActor
final class TextureFactory {
    static let shared = TextureFactory()

    private struct SkinCacheKey: Hashable {
        let skinID: String
        let pose: PlayerPose
        let highContrast: Bool
    }

    private var playerTextureCache: [SkinCacheKey: SKTexture] = [:]
    private var previewImageCache: [String: UIImage] = [:]
    private var cloudTexturesCache: [SKTexture]?
    private var mountainStripTexture: SKTexture?
    private var islandStripTexture: SKTexture?
    private var groundNormalTexture: SKTexture?
    private var groundHighContrastTexture: SKTexture?
    private var spireNormalBodyTexture: SKTexture?
    private var spireContrastBodyTexture: SKTexture?
    private var spireNormalCapTexture: SKTexture?
    private var spireContrastCapTexture: SKTexture?
    private var moteTextureCache: SKTexture?

    private init() {}

    // MARK: - Player Character Textures

    func playerTexture(skin: CharacterSkin, pose: PlayerPose, highContrast: Bool) -> SKTexture {
        let key = SkinCacheKey(skinID: skin.id, pose: pose, highContrast: highContrast)
        if let cached = playerTextureCache[key] {
            return cached
        }
        let image = renderPlayerImage(skin: skin, pose: pose, highContrast: highContrast, canvasSize: CGSize(width: 68, height: 56))
        let texture = SKTexture(image: image)
        texture.filteringMode = .linear
        playerTextureCache[key] = texture
        return texture
    }

    func flightAnimationTextures(skin: CharacterSkin, highContrast: Bool) -> [SKTexture] {
        [
            playerTexture(skin: skin, pose: .wingUp, highContrast: highContrast),
            playerTexture(skin: skin, pose: .wingMid, highContrast: highContrast),
            playerTexture(skin: skin, pose: .wingDown, highContrast: highContrast),
            playerTexture(skin: skin, pose: .wingMid, highContrast: highContrast)
        ]
    }

    /// High-resolution portrait image used in SwiftUI Main Menu and Skin Wardrobe cards.
    func previewImage(for skin: CharacterSkin) -> UIImage {
        if let cached = previewImageCache[skin.id] {
            return cached
        }
        let image = renderPlayerImage(skin: skin, pose: .wingUp, highContrast: false, canvasSize: CGSize(width: 136, height: 112))
        previewImageCache[skin.id] = image
        return image
    }

    private func renderPlayerImage(
        skin: CharacterSkin,
        pose: PlayerPose,
        highContrast: Bool,
        canvasSize: CGSize
    ) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 3.0
        format.opaque = false

        let renderer = UIGraphicsImageRenderer(size: canvasSize, format: format)
        return renderer.image { rendererContext in
            let ctx = rendererContext.cgContext
            let scaleX = canvasSize.width / 68.0
            let scaleY = canvasSize.height / 56.0
            ctx.scaleBy(x: scaleX, y: scaleY)

            let palette = skin.palette
            let outlineColor = highContrast ? UIColor.black : UIColor(white: 0.14, alpha: 0.88)
            let outlineWidth: CGFloat = highContrast ? 2.6 : 1.7

            // 1. Tail feathers (left rear)
            ctx.saveGState()
            let tailPath = UIBezierPath()
            tailPath.move(to: CGPoint(x: 16, y: 29))
            tailPath.addQuadCurve(to: CGPoint(x: 4, y: 22), controlPoint: CGPoint(x: 8, y: 21))
            tailPath.addQuadCurve(to: CGPoint(x: 9, y: 30), controlPoint: CGPoint(x: 5, y: 27))
            tailPath.addQuadCurve(to: CGPoint(x: 5, y: 36), controlPoint: CGPoint(x: 4, y: 33))
            tailPath.addQuadCurve(to: CGPoint(x: 18, y: 35), controlPoint: CGPoint(x: 11, y: 38))
            tailPath.close()
            palette.crest.uiColor.setFill()
            tailPath.fill()
            outlineColor.setStroke()
            tailPath.lineWidth = outlineWidth
            tailPath.stroke()
            ctx.restoreGState()

            // 2. Crown crest tuft (top of head)
            ctx.saveGState()
            let crestPath = UIBezierPath()
            crestPath.move(to: CGPoint(x: 31, y: 11))
            crestPath.addQuadCurve(to: CGPoint(x: 24, y: 3), controlPoint: CGPoint(x: 28, y: 4))
            crestPath.addQuadCurve(to: CGPoint(x: 35, y: 8), controlPoint: CGPoint(x: 31, y: 4))
            crestPath.addQuadCurve(to: CGPoint(x: 32, y: 3), controlPoint: CGPoint(x: 35, y: 4))
            crestPath.addQuadCurve(to: CGPoint(x: 40, y: 11), controlPoint: CGPoint(x: 38, y: 5))
            crestPath.close()
            palette.crest.uiColor.setFill()
            crestPath.fill()
            outlineColor.setStroke()
            crestPath.lineWidth = outlineWidth
            crestPath.stroke()
            ctx.restoreGState()

            // 3. Plump teardrop-oval body with smooth vertical gradient
            let bodyRect = CGRect(x: 14, y: 9, width: 42, height: 38)
            let bodyPath = UIBezierPath(ovalIn: bodyRect)

            ctx.saveGState()
            bodyPath.addClip()
            drawLinearGradient(
                in: ctx,
                rect: bodyRect,
                topColor: palette.bodyTop.uiColor,
                bottomColor: palette.bodyBottom.uiColor
            )

            // Soft warm belly patch clipped inside body
            let bellyPath = UIBezierPath(ovalIn: CGRect(x: 22, y: 24, width: 32, height: 24))
            palette.belly.uiColor.setFill()
            bellyPath.fill()

            // Subtle overhead highlight sheen
            let highlightPath = UIBezierPath(ovalIn: CGRect(x: 21, y: 11, width: 22, height: 9))
            UIColor(white: 1.0, alpha: 0.28).setFill()
            highlightPath.fill()
            ctx.restoreGState()

            outlineColor.setStroke()
            bodyPath.lineWidth = outlineWidth
            bodyPath.stroke()

            // 4. Cute curved beak (front right)
            ctx.saveGState()
            let beakPath = UIBezierPath()
            beakPath.move(to: CGPoint(x: 53, y: 24))
            beakPath.addQuadCurve(to: CGPoint(x: 65, y: 29), controlPoint: CGPoint(x: 62, y: 24))
            beakPath.addQuadCurve(to: CGPoint(x: 53, y: 34), controlPoint: CGPoint(x: 61, y: 34))
            beakPath.close()
            palette.beak.uiColor.setFill()
            beakPath.fill()
            outlineColor.setStroke()
            beakPath.lineWidth = outlineWidth
            beakPath.stroke()

            // Smile line inside beak
            let beakLine = UIBezierPath()
            beakLine.move(to: CGPoint(x: 54, y: 29.5))
            beakLine.addQuadCurve(to: CGPoint(x: 63, y: 29.0), controlPoint: CGPoint(x: 59, y: 31))
            outlineColor.setStroke()
            beakLine.lineWidth = 1.2
            beakLine.stroke()
            ctx.restoreGState()

            // 5. Expressive eye & cheek blush
            let cheekPath = UIBezierPath(ovalIn: CGRect(x: 41, y: 30, width: 8.5, height: 5.5))
            palette.cheek.uiColor.setFill()
            cheekPath.fill()

            let eyeCenter = CGPoint(x: 45.5, y: 22.0)
            switch pose {
            case .blink:
                let blinkPath = UIBezierPath()
                blinkPath.move(to: CGPoint(x: 40.5, y: 22.5))
                blinkPath.addQuadCurve(to: CGPoint(x: 50.5, y: 22.5), controlPoint: CGPoint(x: 45.5, y: 19.0))
                outlineColor.setStroke()
                blinkPath.lineWidth = 2.2
                blinkPath.lineCapStyle = .round
                blinkPath.stroke()

            case .collided:
                // Wide startled eye with tiny pupil
                let eyeWhite = UIBezierPath(ovalIn: CGRect(x: 39.5, y: 15.5, width: 12.0, height: 12.5))
                UIColor.white.setFill()
                eyeWhite.fill()
                outlineColor.setStroke()
                eyeWhite.lineWidth = 1.6
                eyeWhite.stroke()

                // Startled X / pinpoint pupil
                let cross1 = UIBezierPath()
                cross1.move(to: CGPoint(x: 43.2, y: 19.5))
                cross1.addLine(to: CGPoint(x: 48.2, y: 24.5))
                cross1.move(to: CGPoint(x: 48.2, y: 19.5))
                cross1.addLine(to: CGPoint(x: 43.2, y: 24.5))
                UIColor(white: 0.12, alpha: 1.0).setStroke()
                cross1.lineWidth = 2.0
                cross1.lineCapStyle = .round
                cross1.stroke()

            case .wingUp, .wingMid, .wingDown:
                let eyeWhite = UIBezierPath(ovalIn: CGRect(x: eyeCenter.x - 5.5, y: eyeCenter.y - 6.0, width: 11.0, height: 12.0))
                UIColor.white.setFill()
                eyeWhite.fill()
                outlineColor.setStroke()
                eyeWhite.lineWidth = 1.4
                eyeWhite.stroke()

                let pupil = UIBezierPath(ovalIn: CGRect(x: eyeCenter.x - 2.2, y: eyeCenter.y - 3.6, width: 5.8, height: 6.8))
                UIColor(red: 0.10, green: 0.12, blue: 0.18, alpha: 1.0).setFill()
                pupil.fill()

                let catchlight = UIBezierPath(ovalIn: CGRect(x: eyeCenter.x - 1.0, y: eyeCenter.y - 2.6, width: 2.6, height: 2.6))
                UIColor.white.setFill()
                catchlight.fill()
            }

            // 6. Animated feathered wing (pivots cleanly around shoulder)
            ctx.saveGState()
            let shoulder = CGPoint(x: 31, y: 28)
            ctx.translateBy(x: shoulder.x, y: shoulder.y)

            let wingAngle: CGFloat
            let wingScaleY: CGFloat
            switch pose {
            case .wingUp:
                wingAngle = -0.58
                wingScaleY = 1.05
            case .wingMid, .blink:
                wingAngle = 0.04
                wingScaleY = 0.92
            case .wingDown:
                wingAngle = 0.56
                wingScaleY = 1.05
            case .collided:
                wingAngle = -0.82
                wingScaleY = 0.95
            }
            ctx.rotate(by: wingAngle)
            ctx.scaleBy(x: 1.0, y: wingScaleY)

            let wingPath = UIBezierPath()
            wingPath.move(to: CGPoint(x: 4, y: -4))
            wingPath.addCurve(
                to: CGPoint(x: -16, y: 2),
                controlPoint1: CGPoint(x: -4, y: -11),
                controlPoint2: CGPoint(x: -15, y: -6)
            )
            wingPath.addQuadCurve(to: CGPoint(x: -9, y: 9), controlPoint: CGPoint(x: -16, y: 8))
            wingPath.addQuadCurve(to: CGPoint(x: 4, y: 6), controlPoint: CGPoint(x: -2, y: 11))
            wingPath.addQuadCurve(to: CGPoint(x: 4, y: -4), controlPoint: CGPoint(x: 8, y: 1))
            wingPath.close()

            palette.wing.uiColor.setFill()
            wingPath.fill()
            outlineColor.setStroke()
            wingPath.lineWidth = outlineWidth
            wingPath.stroke()
            ctx.restoreGState()
        }
    }

    // MARK: - Parallax Environment Textures

    func cloudTextures() -> [SKTexture] {
        if let cached = cloudTexturesCache {
            return cached
        }
        let sizes = [
            CGSize(width: 130, height: 58),
            CGSize(width: 96, height: 46),
            CGSize(width: 158, height: 64)
        ]

        let generated: [SKTexture] = sizes.enumerated().map { index, size in
            let format = UIGraphicsImageRendererFormat()
            format.scale = 2.0
            format.opaque = false

            let image = UIGraphicsImageRenderer(size: size, format: format).image { ctx in
                let cg = ctx.cgContext
                let w = size.width
                let h = size.height

                let path = UIBezierPath()
                path.addArc(withCenter: CGPoint(x: w * 0.26, y: h * 0.64), radius: h * 0.26, startAngle: 0, endAngle: .pi * 2, clockwise: true)
                path.addArc(withCenter: CGPoint(x: w * 0.46, y: h * 0.46), radius: h * 0.36, startAngle: 0, endAngle: .pi * 2, clockwise: true)
                if index != 1 {
                    path.addArc(withCenter: CGPoint(x: w * 0.67, y: h * 0.52), radius: h * 0.30, startAngle: 0, endAngle: .pi * 2, clockwise: true)
                }
                path.addArc(withCenter: CGPoint(x: w * 0.78, y: h * 0.66), radius: h * 0.22, startAngle: 0, endAngle: .pi * 2, clockwise: true)
                let baseRect = UIBezierPath(roundedRect: CGRect(x: w * 0.16, y: h * 0.56, width: w * 0.68, height: h * 0.34), cornerRadius: h * 0.17)
                path.append(baseRect)

                UIColor(white: 1.0, alpha: 0.90).setFill()
                path.fill()

                // Soft underside lavender-blue shadow
                cg.saveGState()
                let underRect = UIBezierPath(roundedRect: CGRect(x: w * 0.18, y: h * 0.74, width: w * 0.64, height: h * 0.15), cornerRadius: h * 0.07)
                UIColor(red: 0.78, green: 0.88, blue: 0.98, alpha: 0.45).setFill()
                underRect.fill()
                cg.restoreGState()
            }

            let tex = SKTexture(image: image)
            tex.filteringMode = .linear
            return tex
        }

        cloudTexturesCache = generated
        return generated
    }

    /// Seamlessly tileable 512x220 distant mountain range texture.
    func mountainRangeTexture() -> SKTexture {
        if let cached = mountainStripTexture {
            return cached
        }
        let size = CGSize(width: 512, height: 220)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 2.0
        format.opaque = false

        let image = UIGraphicsImageRenderer(size: size, format: format).image { ctx in
            let cg = ctx.cgContext

            // Far misty peaks (starts and ends at y = 148 for seamless horizontal wrap)
            let farPeaks = UIBezierPath()
            farPeaks.move(to: CGPoint(x: 0, y: 220))
            farPeaks.addLine(to: CGPoint(x: 0, y: 148))
            farPeaks.addLine(to: CGPoint(x: 78, y: 58))
            farPeaks.addLine(to: CGPoint(x: 162, y: 132))
            farPeaks.addLine(to: CGPoint(x: 258, y: 34))
            farPeaks.addLine(to: CGPoint(x: 348, y: 126))
            farPeaks.addLine(to: CGPoint(x: 432, y: 66))
            farPeaks.addLine(to: CGPoint(x: 512, y: 148))
            farPeaks.addLine(to: CGPoint(x: 512, y: 220))
            farPeaks.close()

            cg.saveGState()
            farPeaks.addClip()
            drawLinearGradient(
                in: cg,
                rect: CGRect(origin: .zero, size: size),
                topColor: UIColor(red: 0.56, green: 0.68, blue: 0.88, alpha: 0.72),
                bottomColor: UIColor(red: 0.42, green: 0.56, blue: 0.78, alpha: 0.88)
            )
            cg.restoreGState()

            // Snow caps on the two tallest peaks
            let snowCap1 = UIBezierPath()
            snowCap1.move(to: CGPoint(x: 78, y: 58))
            snowCap1.addLine(to: CGPoint(x: 56, y: 84))
            snowCap1.addLine(to: CGPoint(x: 70, y: 79))
            snowCap1.addLine(to: CGPoint(x: 80, y: 87))
            snowCap1.addLine(to: CGPoint(x: 99, y: 82))
            snowCap1.close()

            let snowCap2 = UIBezierPath()
            snowCap2.move(to: CGPoint(x: 258, y: 34))
            snowCap2.addLine(to: CGPoint(x: 230, y: 70))
            snowCap2.addLine(to: CGPoint(x: 248, y: 63))
            snowCap2.addLine(to: CGPoint(x: 262, y: 74))
            snowCap2.addLine(to: CGPoint(x: 286, y: 68))
            snowCap2.close()

            UIColor(white: 1.0, alpha: 0.72).setFill()
            snowCap1.fill()
            snowCap2.fill()

            // Nearer rolling hills (starts and ends at y = 168 for seamless wrap)
            let nearHills = UIBezierPath()
            nearHills.move(to: CGPoint(x: 0, y: 220))
            nearHills.addLine(to: CGPoint(x: 0, y: 168))
            nearHills.addCurve(to: CGPoint(x: 180, y: 152), controlPoint1: CGPoint(x: 65, y: 118), controlPoint2: CGPoint(x: 125, y: 124))
            nearHills.addCurve(to: CGPoint(x: 360, y: 146), controlPoint1: CGPoint(x: 235, y: 180), controlPoint2: CGPoint(x: 295, y: 108))
            nearHills.addCurve(to: CGPoint(x: 512, y: 168), controlPoint1: CGPoint(x: 418, y: 176), controlPoint2: CGPoint(x: 468, y: 142))
            nearHills.addLine(to: CGPoint(x: 512, y: 220))
            nearHills.close()

            UIColor(red: 0.32, green: 0.54, blue: 0.68, alpha: 0.85).setFill()
            nearHills.fill()
        }

        let texture = SKTexture(image: image)
        texture.filteringMode = .linear
        mountainStripTexture = texture
        return texture
    }

    /// Midground floating islands & silhouette trees strip (512x250).
    func floatingIslandsTexture() -> SKTexture {
        if let cached = islandStripTexture {
            return cached
        }
        let size = CGSize(width: 512, height: 250)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 2.0
        format.opaque = false

        let image = UIGraphicsImageRenderer(size: size, format: format).image { _ in
            // Draw two scenic floating islands at different heights
            let islands: [(center: CGPoint, width: CGFloat, rockDepth: CGFloat)] = [
                (CGPoint(x: 128, y: 112), 118, 56),
                (CGPoint(x: 382, y: 74), 94, 46)
            ]

            for island in islands {
                let cx = island.center.x
                let cy = island.center.y
                let halfW = island.width * 0.5

                // Tapered floating rock underside
                let rock = UIBezierPath()
                rock.move(to: CGPoint(x: cx - halfW * 0.88, y: cy))
                rock.addLine(to: CGPoint(x: cx + halfW * 0.88, y: cy))
                rock.addLine(to: CGPoint(x: cx + halfW * 0.42, y: cy + island.rockDepth * 0.65))
                rock.addLine(to: CGPoint(x: cx - 4, y: cy + island.rockDepth))
                rock.addLine(to: CGPoint(x: cx - halfW * 0.48, y: cy + island.rockDepth * 0.58))
                rock.close()
                UIColor(red: 0.44, green: 0.40, blue: 0.52, alpha: 0.88).setFill()
                rock.fill()

                // Tiny cascading waterfall ribbon on the larger island
                if island.width > 100 {
                    let falls = UIBezierPath(roundedRect: CGRect(x: cx + 10, y: cy + 2, width: 9, height: 68), cornerRadius: 4.5)
                    UIColor(red: 0.72, green: 0.94, blue: 1.0, alpha: 0.75).setFill()
                    falls.fill()
                }

                // Lush grassy cap
                let turf = UIBezierPath(roundedRect: CGRect(x: cx - halfW, y: cy - 11, width: island.width, height: 20), cornerRadius: 10)
                UIColor(red: 0.28, green: 0.74, blue: 0.50, alpha: 0.95).setFill()
                turf.fill()

                // Stylized round canopy tree on top of island
                let trunk = UIBezierPath(rect: CGRect(x: cx - 18, y: cy - 30, width: 6, height: 20))
                UIColor(red: 0.45, green: 0.30, blue: 0.24, alpha: 0.90).setFill()
                trunk.fill()

                let canopy = UIBezierPath(ovalIn: CGRect(x: cx - 32, y: cy - 52, width: 34, height: 28))
                UIColor(red: 0.22, green: 0.68, blue: 0.46, alpha: 0.95).setFill()
                canopy.fill()
            }
        }

        let texture = SKTexture(image: image)
        texture.filteringMode = .linear
        islandStripTexture = texture
        return texture
    }

    /// Seamlessly scrolling foreground grass & cliff ground strip (512x132).
    func groundTexture(highContrast: Bool) -> SKTexture {
        if highContrast, let cached = groundHighContrastTexture {
            return cached
        }
        if !highContrast, let cached = groundNormalTexture {
            return cached
        }

        let size = CGSize(width: 512, height: DifficultyProfile.groundHeight)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 3.0
        format.opaque = true

        let image = UIGraphicsImageRenderer(size: size, format: format).image { ctx in
            let cg = ctx.cgContext

            // Rich cliff earth base
            drawLinearGradient(
                in: cg,
                rect: CGRect(origin: .zero, size: size),
                topColor: highContrast ? UIColor(red: 0.30, green: 0.22, blue: 0.16, alpha: 1) : UIColor(red: 0.56, green: 0.38, blue: 0.26, alpha: 1),
                bottomColor: highContrast ? UIColor(red: 0.16, green: 0.12, blue: 0.09, alpha: 1) : UIColor(red: 0.36, green: 0.23, blue: 0.16, alpha: 1)
            )

            // Decorative stone strata pebbles
            UIColor(white: 1.0, alpha: 0.10).setFill()
            for idx in 0..<16 {
                let px = CGFloat(idx) * 32.0 + 8.0
                let py = 46.0 + CGFloat((idx * 19) % 58)
                let rw = 16.0 + CGFloat((idx * 7) % 10)
                let pebble = UIBezierPath(roundedRect: CGRect(x: px, y: py, width: rw, height: 9), cornerRadius: 4.5)
                pebble.fill()
            }

            // Lush grass top band (28pt tall)
            let grassHeight: CGFloat = 28.0
            let grassRect = CGRect(x: 0, y: 0, width: size.width, height: grassHeight)
            drawLinearGradient(
                in: cg,
                rect: grassRect,
                topColor: highContrast ? UIColor(red: 0.22, green: 0.88, blue: 0.38, alpha: 1) : UIColor(red: 0.36, green: 0.84, blue: 0.42, alpha: 1),
                bottomColor: UIColor(red: 0.18, green: 0.64, blue: 0.32, alpha: 1)
            )

            // Scalloped overhanging grass tufts (tileable every 32pt)
            UIColor(red: 0.18, green: 0.64, blue: 0.32, alpha: 1).setFill()
            for idx in 0..<16 {
                let x = CGFloat(idx) * 32.0
                let tuft = UIBezierPath(ovalIn: CGRect(x: x - 2, y: grassHeight - 9, width: 36, height: 16))
                tuft.fill()
            }

            // Crisp top rim highlight (or bold outline in High Contrast mode)
            let topRim = UIBezierPath(rect: CGRect(x: 0, y: 0, width: size.width, height: highContrast ? 4.0 : 3.0))
            (highContrast ? UIColor.white : UIColor(red: 0.68, green: 0.96, blue: 0.56, alpha: 0.90)).setFill()
            topRim.fill()
        }

        let texture = SKTexture(image: image)
        texture.filteringMode = .linear
        if highContrast {
            groundHighContrastTexture = texture
        } else {
            groundNormalTexture = texture
        }
        return texture
    }

    // MARK: - Original Sky Spire / Wind Gate Obstacles

    /// Column shaft texture for Sky Spire obstacles (76pt wide).
    func spireShaftTexture(highContrast: Bool) -> SKTexture {
        if highContrast, let cached = spireContrastBodyTexture {
            return cached
        }
        if !highContrast, let cached = spireNormalBodyTexture {
            return cached
        }

        let size = CGSize(width: DifficultyProfile.obstacleWidth, height: 520)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 3.0
        format.opaque = false

        let image = UIGraphicsImageRenderer(size: size, format: format).image { ctx in
            let cg = ctx.cgContext
            let insetRect = CGRect(x: 4, y: 0, width: size.width - 8, height: size.height)

            // Warm alabaster/sandstone architectural column with cylindrical shading
            let leftColor = highContrast ? UIColor(red: 0.22, green: 0.26, blue: 0.36, alpha: 1) : UIColor(red: 0.88, green: 0.84, blue: 0.76, alpha: 1)
            let midColor = highContrast ? UIColor(red: 0.34, green: 0.40, blue: 0.54, alpha: 1) : UIColor(red: 0.98, green: 0.96, blue: 0.90, alpha: 1)
            let rightColor = highContrast ? UIColor(red: 0.14, green: 0.18, blue: 0.26, alpha: 1) : UIColor(red: 0.68, green: 0.64, blue: 0.60, alpha: 1)

            cg.saveGState()
            UIBezierPath(rect: insetRect).addClip()
            let shaftLocations: [CGFloat] = [0.0, 0.36, 1.0]
            if let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: [leftColor.cgColor, midColor.cgColor, rightColor.cgColor] as CFArray,
                locations: shaftLocations
            ) {
                cg.drawLinearGradient(
                    gradient,
                    start: CGPoint(x: insetRect.minX, y: 0),
                    end: CGPoint(x: insetRect.maxX, y: 0),
                    options: []
                )
            }

            // Vertical architectural fluting grooves & teal wind-rune bands
            let grooveColor = highContrast ? UIColor(white: 1.0, alpha: 0.16) : UIColor(red: 0.52, green: 0.50, blue: 0.48, alpha: 0.22)
            grooveColor.setFill()
            UIBezierPath(rect: CGRect(x: 17, y: 0, width: 4, height: size.height)).fill()
            UIBezierPath(rect: CGRect(x: 36, y: 0, width: 4, height: size.height)).fill()
            UIBezierPath(rect: CGRect(x: 55, y: 0, width: 4, height: size.height)).fill()

            // Decorative sky-teal bands every 96pt
            let bandColor = highContrast ? UIColor(red: 1.0, green: 0.84, blue: 0.20, alpha: 0.85) : UIColor(red: 0.22, green: 0.72, blue: 0.78, alpha: 0.55)
            bandColor.setFill()
            var bandY: CGFloat = 44
            while bandY < size.height {
                UIBezierPath(rect: CGRect(x: insetRect.minX, y: bandY, width: insetRect.width, height: 8)).fill()
                bandY += 96
            }
            cg.restoreGState()

            // Crisp side borders
            let strokeColor = highContrast ? UIColor.white : UIColor(red: 0.30, green: 0.28, blue: 0.34, alpha: 0.90)
            strokeColor.setStroke()
            let border = UIBezierPath(rect: insetRect.insetBy(dx: 1.0, dy: -2.0))
            border.lineWidth = highContrast ? 2.6 : 1.8
            border.stroke()
        }

        let texture = SKTexture(image: image)
        texture.filteringMode = .linear
        if highContrast {
            spireContrastBodyTexture = texture
        } else {
            spireNormalBodyTexture = texture
        }
        return texture
    }

    /// Ornate beveled stone capital + glowing crystal rim placed at the gap edge of each Sky Spire.
    func spireCapTexture(highContrast: Bool) -> SKTexture {
        if highContrast, let cached = spireContrastCapTexture {
            return cached
        }
        if !highContrast, let cached = spireNormalCapTexture {
            return cached
        }

        let size = CGSize(width: DifficultyProfile.obstacleWidth + 8, height: 34)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 3.0
        format.opaque = false

        let image = UIGraphicsImageRenderer(size: size, format: format).image { ctx in
            let cg = ctx.cgContext
            let capRect = CGRect(x: 2, y: 2, width: size.width - 4, height: size.height - 4)
            let capPath = UIBezierPath(roundedRect: capRect, cornerRadius: 7)

            cg.saveGState()
            capPath.addClip()
            drawLinearGradient(
                in: cg,
                rect: capRect,
                topColor: highContrast ? UIColor(red: 1.0, green: 0.86, blue: 0.24, alpha: 1) : UIColor(red: 0.98, green: 0.78, blue: 0.34, alpha: 1),
                bottomColor: highContrast ? UIColor(red: 0.86, green: 0.56, blue: 0.08, alpha: 1) : UIColor(red: 0.82, green: 0.52, blue: 0.20, alpha: 1)
            )

            // Top specular highlight bar
            UIColor(white: 1.0, alpha: 0.38).setFill()
            UIBezierPath(rect: CGRect(x: capRect.minX, y: capRect.minY, width: capRect.width, height: 6)).fill()
            cg.restoreGState()

            // Glowing aqua crystal gem centered in the gate cap
            let gemRect = CGRect(x: size.width * 0.5 - 9, y: size.height * 0.5 - 6, width: 18, height: 12)
            let gemPath = UIBezierPath(roundedRect: gemRect, cornerRadius: 6)
            (highContrast ? UIColor.cyan : UIColor(red: 0.26, green: 0.92, blue: 0.96, alpha: 1.0)).setFill()
            gemPath.fill()

            let outlineColor = highContrast ? UIColor.black : UIColor(red: 0.30, green: 0.24, blue: 0.22, alpha: 0.95)
            outlineColor.setStroke()
            capPath.lineWidth = highContrast ? 2.6 : 1.8
            capPath.stroke()
        }

        let texture = SKTexture(image: image)
        texture.filteringMode = .linear
        if highContrast {
            spireContrastCapTexture = texture
        } else {
            spireNormalCapTexture = texture
        }
        return texture
    }

    // MARK: - Particle Mote Texture

    func softMoteTexture() -> SKTexture {
        if let cached = moteTextureCache {
            return cached
        }
        let size = CGSize(width: 18, height: 18)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 2.0
        format.opaque = false

        let image = UIGraphicsImageRenderer(size: size, format: format).image { ctx in
            let cg = ctx.cgContext
            let center = CGPoint(x: 9, y: 9)
            let moteLocations: [CGFloat] = [0.0, 0.45, 1.0]
            if let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: [
                    UIColor.white.cgColor,
                    UIColor(white: 1.0, alpha: 0.45).cgColor,
                    UIColor(white: 1.0, alpha: 0.0).cgColor
                ] as CFArray,
                locations: moteLocations
            ) {
                cg.drawRadialGradient(
                    gradient,
                    startCenter: center,
                    startRadius: 0,
                    endCenter: center,
                    endRadius: 9,
                    options: []
                )
            }
        }

        let texture = SKTexture(image: image)
        texture.filteringMode = .linear
        moteTextureCache = texture
        return texture
    }

    // MARK: - Gradient Utility

    private func drawLinearGradient(
        in context: CGContext,
        rect: CGRect,
        topColor: UIColor,
        bottomColor: UIColor
    ) {
        let linearLocations: [CGFloat] = [0.0, 1.0]
        guard let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: [topColor.cgColor, bottomColor.cgColor] as CFArray,
            locations: linearLocations
        ) else { return }

        context.drawLinearGradient(
            gradient,
            start: CGPoint(x: rect.midX, y: rect.minY),
            end: CGPoint(x: rect.midX, y: rect.maxY),
            options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
        )
    }
}

