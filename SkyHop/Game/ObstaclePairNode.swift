import SpriteKit

/// Reusable pooled Wind Gate obstacle pair consisting of an upper and lower Sky Spire
/// framing a vertical passage gap.
@MainActor
final class ObstaclePairNode: SKNode {
    static let spireHeight: CGFloat = 820.0
    static let capHeight: CGFloat = 34.0
    static let hitboxWidth: CGFloat = DifficultyProfile.obstacleWidth - 10.0

    private let topShaft: SKSpriteNode
    private let topCap: SKSpriteNode
    private let bottomShaft: SKSpriteNode
    private let bottomCap: SKSpriteNode
    private let scoreGateNode: SKNode

    private(set) var baseGapCenterY: CGFloat = 480.0
    private(set) var currentGapCenterY: CGFloat = 480.0
    private(set) var gapHeight: CGFloat = 220.0

    var isActiveInScene: Bool = false
    var hasScored: Bool = false

    private var oscillatesVertically: Bool = false
    private var oscillationAmplitude: CGFloat = 0.0
    private var oscillationSpeed: CGFloat = 0.0
    private var oscillationPhase: CGFloat = 0.0

    init(highContrast: Bool) {
        let shaftTex = TextureFactory.shared.spireShaftTexture(highContrast: highContrast)
        let capTex = TextureFactory.shared.spireCapTexture(highContrast: highContrast)

        let shaftSize = CGSize(width: DifficultyProfile.obstacleWidth, height: Self.spireHeight)
        let capSize = CGSize(width: DifficultyProfile.obstacleWidth + 8, height: Self.capHeight)

        self.topShaft = SKSpriteNode(texture: shaftTex, size: shaftSize)
        self.topCap = SKSpriteNode(texture: capTex, size: capSize)
        self.bottomShaft = SKSpriteNode(texture: shaftTex, size: shaftSize)
        self.bottomCap = SKSpriteNode(texture: capTex, size: capSize)
        self.scoreGateNode = SKNode()

        super.init()

        // Flip top shaft vertically for visual symmetry
        topShaft.yScale = -1.0

        addChild(bottomShaft)
        addChild(bottomCap)
        addChild(topShaft)
        addChild(topCap)
        addChild(scoreGateNode)

        topCap.zPosition = 2
        bottomCap.zPosition = 2
        topShaft.zPosition = 1
        bottomShaft.zPosition = 1

        configurePhysicsBodies()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configurePhysicsBodies() {
        let hitboxSize = CGSize(width: Self.hitboxWidth, height: Self.spireHeight)

        let topBody = SKPhysicsBody(rectangleOf: hitboxSize)
        topBody.isDynamic = false
        topBody.categoryBitMask = PhysicsCategory.obstacle
        topBody.contactTestBitMask = PhysicsCategory.player
        topBody.collisionBitMask = PhysicsCategory.none
        topShaft.physicsBody = topBody

        let bottomBody = SKPhysicsBody(rectangleOf: hitboxSize)
        bottomBody.isDynamic = false
        bottomBody.categoryBitMask = PhysicsCategory.obstacle
        bottomBody.contactTestBitMask = PhysicsCategory.player
        bottomBody.collisionBitMask = PhysicsCategory.none
        bottomShaft.physicsBody = bottomBody

        let gateBody = SKPhysicsBody(rectangleOf: CGSize(width: 8, height: 320))
        gateBody.isDynamic = false
        gateBody.categoryBitMask = PhysicsCategory.scoreGate
        gateBody.contactTestBitMask = PhysicsCategory.player
        gateBody.collisionBitMask = PhysicsCategory.none
        scoreGateNode.physicsBody = gateBody
    }

    func updateContrastAppearance(highContrast: Bool) {
        let shaftTex = TextureFactory.shared.spireShaftTexture(highContrast: highContrast)
        let capTex = TextureFactory.shared.spireCapTexture(highContrast: highContrast)
        topShaft.texture = shaftTex
        bottomShaft.texture = shaftTex
        topCap.texture = capTex
        bottomCap.texture = capTex
    }

    /// Configures and activates a pooled obstacle pair at `spawnX` without allocating new child nodes.
    func activate(
        spawnX: CGFloat,
        gapCenterY: CGFloat,
        gapHeight: CGFloat,
        oscillates: Bool,
        amplitude: CGFloat,
        speed: CGFloat
    ) {
        self.position = CGPoint(x: spawnX, y: 0)
        self.baseGapCenterY = gapCenterY
        self.currentGapCenterY = gapCenterY
        self.gapHeight = gapHeight
        self.hasScored = false
        self.isActiveInScene = true
        self.isHidden = false

        self.oscillatesVertically = oscillates
        self.oscillationAmplitude = oscillates ? amplitude : 0
        self.oscillationSpeed = oscillates ? speed : 0
        self.oscillationPhase = CGFloat.random(in: 0...(2.0 * .pi))

        layoutGap(at: gapCenterY)
    }

    func deactivateToPool() {
        isActiveInScene = false
        isHidden = true
        position = CGPoint(x: -1000, y: 0)
    }

    /// Advances horizontal scroll and optional gentle vertical drift using clamped delta-time.
    func step(deltaTime dt: TimeInterval, scrollSpeed: CGFloat, minSafeY: CGFloat, maxSafeY: CGFloat) {
        guard isActiveInScene else { return }
        let dtf = CGFloat(dt)
        position.x -= scrollSpeed * dtf

        if oscillatesVertically && oscillationAmplitude > 0 {
            oscillationPhase += oscillationSpeed * dtf
            let rawY = baseGapCenterY + sin(oscillationPhase) * oscillationAmplitude
            let clampedY = min(max(rawY, minSafeY), maxSafeY)
            currentGapCenterY = clampedY
            layoutGap(at: clampedY)
        }
    }

    /// Precise circle-vs-AABB hit check against upper and lower spires in scene space.
    func intersectsPlayer(center: CGPoint, radius: CGFloat) -> Bool {
        guard isActiveInScene else { return false }

        let halfW = Self.hitboxWidth * 0.5
        let minX = position.x - halfW
        let maxX = position.x + halfW

        // Quick horizontal rejection
        if center.x + radius < minX || center.x - radius > maxX {
            return false
        }

        let bottomTopEdge = currentGapCenterY - gapHeight * 0.5
        let topBottomEdge = currentGapCenterY + gapHeight * 0.5

        let bottomRect = CGRect(
            x: minX,
            y: bottomTopEdge - Self.spireHeight,
            width: Self.hitboxWidth,
            height: Self.spireHeight
        )
        let topRect = CGRect(
            x: minX,
            y: topBottomEdge,
            width: Self.hitboxWidth,
            height: Self.spireHeight
        )

        return Self.circleIntersects(center: center, radius: radius, rect: bottomRect) ||
               Self.circleIntersects(center: center, radius: radius, rect: topRect)
    }

    private func layoutGap(at centerY: CGFloat) {
        let halfGap = gapHeight * 0.5
        let bottomEdge = centerY - halfGap
        let topEdge = centerY + halfGap

        bottomShaft.position = CGPoint(x: 0, y: bottomEdge - Self.spireHeight * 0.5)
        bottomCap.position = CGPoint(x: 0, y: bottomEdge - Self.capHeight * 0.5)

        topShaft.position = CGPoint(x: 0, y: topEdge + Self.spireHeight * 0.5)
        topCap.position = CGPoint(x: 0, y: topEdge + Self.capHeight * 0.5)

        scoreGateNode.position = CGPoint(x: 8, y: centerY)
    }

    private static func circleIntersects(center: CGPoint, radius: CGFloat, rect: CGRect) -> Bool {
        let closestX = min(max(center.x, rect.minX), rect.maxX)
        let closestY = min(max(center.y, rect.minY), rect.maxY)
        let dx = center.x - closestX
        let dy = center.y - closestY
        return (dx * dx + dy * dy) < (radius * radius)
    }
}

