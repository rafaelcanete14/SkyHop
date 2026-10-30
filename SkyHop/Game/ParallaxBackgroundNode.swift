import SpriteKit
import UIKit

/// Multi-layer parallax sky environment featuring a score-reactive sky gradient,
/// celestial sun/stars, drifting clouds, distant mountains, floating sky islands,
/// and a seamlessly tiled foreground cliff/grass ground layer.
@MainActor
final class ParallaxBackgroundNode: SKNode {
    private var sceneSize: CGSize
    private var highContrast: Bool = false

    private let skyTopBanner = SKSpriteNode()
    private let skyHorizonGlow = SKSpriteNode()
    private let sunNode = SKShapeNode(circleOfRadius: 34)
    private var starNodes: [SKShapeNode] = []

    private var cloudSprites: [(node: SKSpriteNode, speedFactor: CGFloat)] = []
    private var mountainTiles: [SKSpriteNode] = []
    private var islandTiles: [SKSpriteNode] = []
    private var groundTiles: [SKSpriteNode] = []

    private let stripWidth: CGFloat = 512.0

    init(sceneSize: CGSize, highContrast: Bool) {
        self.sceneSize = sceneSize
        self.highContrast = highContrast
        super.init()
        buildLayers()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func resizeIfNeeded(newSize: CGSize) {
        guard abs(newSize.width - sceneSize.width) > 1 || abs(newSize.height - sceneSize.height) > 1 else {
            return
        }
        sceneSize = newSize
        removeAllChildren()
        starNodes.removeAll()
        cloudSprites.removeAll()
        mountainTiles.removeAll()
        islandTiles.removeAll()
        groundTiles.removeAll()
        buildLayers()
    }

    func applySettings(highContrast: Bool) {
        guard self.highContrast != highContrast else { return }
        self.highContrast = highContrast
        let groundTex = TextureFactory.shared.groundTexture(highContrast: highContrast)
        for tile in groundTiles {
            tile.texture = groundTex
        }
        updateAtmosphere(forScore: 0, reducedMotion: false, forceImmediate: true)
    }

    // MARK: - Layer Construction

    private func buildLayers() {
        // 1. Base Sky Backdrop & Horizon Warmth
        skyTopBanner.anchorPoint = .zero
        skyTopBanner.position = .zero
        skyTopBanner.size = sceneSize
        skyTopBanner.zPosition = -50
        skyTopBanner.color = UIColor(red: 0.25, green: 0.68, blue: 0.96, alpha: 1.0)
        addChild(skyTopBanner)

        skyHorizonGlow.anchorPoint = CGPoint(x: 0, y: 0)
        skyHorizonGlow.position = CGPoint(x: 0, y: DifficultyProfile.groundHeight)
        skyHorizonGlow.size = CGSize(width: sceneSize.width, height: sceneSize.height * 0.52)
        skyHorizonGlow.zPosition = -48
        skyHorizonGlow.texture = Self.makeVerticalFadeTexture()
        skyHorizonGlow.color = UIColor(red: 0.72, green: 0.92, blue: 1.0, alpha: 1.0)
        skyHorizonGlow.colorBlendFactor = 1.0
        skyHorizonGlow.alpha = 0.85
        addChild(skyHorizonGlow)

        // 2. Twinkling twilight stars (fade in smoothly during dusk/night score tiers)
        let starPositions: [CGPoint] = [
            CGPoint(x: 0.14, y: 0.88), CGPoint(x: 0.34, y: 0.92), CGPoint(x: 0.62, y: 0.86),
            CGPoint(x: 0.84, y: 0.90), CGPoint(x: 0.22, y: 0.78), CGPoint(x: 0.74, y: 0.79),
            CGPoint(x: 0.48, y: 0.83), CGPoint(x: 0.90, y: 0.74)
        ]
        for (idx, rel) in starPositions.enumerated() {
            let radius: CGFloat = (idx % 2 == 0) ? 2.2 : 1.5
            let star = SKShapeNode(circleOfRadius: radius)
            star.fillColor = .white
            star.strokeColor = .clear
            star.position = CGPoint(x: sceneSize.width * rel.x, y: sceneSize.height * rel.y)
            star.zPosition = -46
            star.alpha = 0.0
            addChild(star)
            starNodes.append(star)
        }

        // 3. Soft Glowing Sun / Moon Orb
        sunNode.fillColor = UIColor(red: 1.0, green: 0.95, blue: 0.72, alpha: 0.88)
        sunNode.strokeColor = UIColor(red: 1.0, green: 0.92, blue: 0.58, alpha: 0.35)
        sunNode.lineWidth = 10
        sunNode.position = CGPoint(x: sceneSize.width * 0.76, y: sceneSize.height * 0.78)
        sunNode.zPosition = -44
        addChild(sunNode)

        // 4. Slow Drifting Clouds
        let cloudTexs = TextureFactory.shared.cloudTextures()
        let cloudCount = 5
        for i in 0..<cloudCount {
            let tex = cloudTexs[i % cloudTexs.count]
            let sprite = SKSpriteNode(texture: tex)
            let scale = CGFloat(0.75 + Double(i % 3) * 0.18)
            sprite.setScale(scale)
            sprite.alpha = highContrast ? 0.45 : 0.86
            let x = (sceneSize.width + 180) * (CGFloat(i) / CGFloat(cloudCount)) - 60
            let y = sceneSize.height * (0.52 + CGFloat((i * 17) % 32) / 100.0)
            sprite.position = CGPoint(x: x, y: y)
            sprite.zPosition = -36
            addChild(sprite)
            let speedFactor = 0.08 + CGFloat(i % 3) * 0.035
            cloudSprites.append((sprite, speedFactor))
        }

        // 5. Distant Mountain Strip (3 tiles cover up to 1536pt width seamlessly)
        let mountainTex = TextureFactory.shared.mountainRangeTexture()
        let tileCount = max(3, Int(ceil(sceneSize.width / stripWidth)) + 2)
        for i in 0..<tileCount {
            let tile = SKSpriteNode(texture: mountainTex, size: CGSize(width: stripWidth, height: 220))
            tile.anchorPoint = .zero
            tile.position = CGPoint(x: CGFloat(i) * stripWidth, y: DifficultyProfile.groundHeight - 8)
            tile.zPosition = -28
            addChild(tile)
            mountainTiles.append(tile)
        }

        // 6. Midground Floating Sky Islands
        let islandTex = TextureFactory.shared.floatingIslandsTexture()
        for i in 0..<tileCount {
            let tile = SKSpriteNode(texture: islandTex, size: CGSize(width: stripWidth, height: 250))
            tile.anchorPoint = .zero
            tile.position = CGPoint(x: CGFloat(i) * stripWidth, y: DifficultyProfile.groundHeight + 135)
            tile.zPosition = -20
            addChild(tile)
            islandTiles.append(tile)
        }

        // 7. Foreground Scrolling Cliff & Meadow Ground (zPosition above obstacles so pillars emerge cleanly)
        let groundTex = TextureFactory.shared.groundTexture(highContrast: highContrast)
        for i in 0..<tileCount {
            let tile = SKSpriteNode(
                texture: groundTex,
                size: CGSize(width: stripWidth, height: DifficultyProfile.groundHeight)
            )
            tile.anchorPoint = .zero
            tile.position = CGPoint(x: CGFloat(i) * stripWidth, y: 0)
            tile.zPosition = 20
            addChild(tile)
            groundTiles.append(tile)
        }
    }

    // MARK: - Frame Update

    func step(deltaTime dt: TimeInterval, foregroundSpeed: CGFloat, scrollGround: Bool) {
        let dtf = CGFloat(dt)

        // Drift clouds continuously even on menu/ready
        for item in cloudSprites {
            item.node.position.x -= foregroundSpeed * item.speedFactor * dtf
            let halfW = item.node.size.width * 0.5 + 24
            if item.node.position.x < -halfW {
                item.node.position.x = sceneSize.width + halfW + CGFloat.random(in: 10...65)
                item.node.position.y = sceneSize.height * CGFloat.random(in: 0.50...0.84)
            }
        }

        advanceStrip(tiles: mountainTiles, speed: foregroundSpeed * 0.16, dt: dtf)
        advanceStrip(tiles: islandTiles, speed: foregroundSpeed * 0.36, dt: dtf)

        if scrollGround {
            advanceStrip(tiles: groundTiles, speed: foregroundSpeed, dt: dtf)
        }
    }

    /// Smoothly shifts sky colors through Morning -> Sunset -> Starlit Twilight as score progresses.
    func updateAtmosphere(forScore score: Int, reducedMotion: Bool, forceImmediate: Bool = false) {
        if highContrast {
            skyTopBanner.color = UIColor(red: 0.07, green: 0.14, blue: 0.28, alpha: 1.0)
            skyHorizonGlow.color = UIColor(red: 0.12, green: 0.24, blue: 0.44, alpha: 1.0)
            sunNode.alpha = 0.25
            for star in starNodes { star.alpha = 0.0 }
            for item in cloudSprites { item.node.alpha = 0.30 }
            return
        }

        for item in cloudSprites { item.node.alpha = 0.86 }

        // Cycle every 45 points (0..15 Morning, 15..30 Golden Sunset, 30..45 Starlit Dusk)
        let phaseIndex = reducedMotion ? 0 : (score / 15) % 3
        let topColor: UIColor
        let horizonColor: UIColor
        let starAlpha: CGFloat

        switch phaseIndex {
        case 0: // Crisp Morning Sky
            topColor = UIColor(red: 0.22, green: 0.66, blue: 0.96, alpha: 1.0)
            horizonColor = UIColor(red: 0.74, green: 0.93, blue: 1.00, alpha: 1.0)
            starAlpha = 0.0
        case 1: // Warm Coral Sunset
            topColor = UIColor(red: 0.38, green: 0.30, blue: 0.74, alpha: 1.0)
            horizonColor = UIColor(red: 1.00, green: 0.64, blue: 0.44, alpha: 1.0)
            starAlpha = 0.35
        default: // Starlit Twilight Indigo
            topColor = UIColor(red: 0.11, green: 0.14, blue: 0.36, alpha: 1.0)
            horizonColor = UIColor(red: 0.32, green: 0.42, blue: 0.76, alpha: 1.0)
            starAlpha = 0.85
        }

        sunNode.alpha = phaseIndex == 2 ? 0.65 : 0.88

        if forceImmediate || reducedMotion {
            skyTopBanner.color = topColor
            skyHorizonGlow.color = horizonColor
            for star in starNodes { star.alpha = starAlpha }
        } else {
            skyTopBanner.run(.colorize(with: topColor, colorBlendFactor: 1.0, duration: 1.6))
            skyHorizonGlow.run(.colorize(with: horizonColor, colorBlendFactor: 1.0, duration: 1.6))
            for star in starNodes {
                star.run(.fadeAlpha(to: starAlpha, duration: 1.6))
            }
        }
    }

    private func advanceStrip(tiles: [SKSpriteNode], speed: CGFloat, dt: CGFloat) {
        guard !tiles.isEmpty else { return }
        for tile in tiles {
            tile.position.x -= speed * dt
        }

        // Find rightmost edge so wrapped tiles snap seamlessly without drift
        var maxRight = -CGFloat.greatestFiniteMagnitude
        for tile in tiles {
            maxRight = max(maxRight, tile.position.x + stripWidth)
        }

        for tile in tiles where tile.position.x + stripWidth <= 0 {
            tile.position.x = maxRight
            maxRight += stripWidth
        }
    }

    private static func makeVerticalFadeTexture() -> SKTexture {
        let size = CGSize(width: 4, height: 128)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        format.opaque = false

        let image = UIGraphicsImageRenderer(size: size, format: format).image { ctx in
            let cg = ctx.cgContext
            // UIKit top (y = 0) corresponds to top of sprite -> transparent; bottom (y = 128) -> opaque white
            let gradientLocations: [CGFloat] = [0.0, 1.0]
            if let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: [
                    UIColor(white: 1.0, alpha: 0.0).cgColor,
                    UIColor(white: 1.0, alpha: 1.0).cgColor
                ] as CFArray,
                locations: gradientLocations
            ) {
                cg.drawLinearGradient(
                    gradient,
                    start: CGPoint(x: 2, y: 0),
                    end: CGPoint(x: 2, y: size.height),
                    options: []
                )
            }
        }
        return SKTexture(image: image)
    }
}

