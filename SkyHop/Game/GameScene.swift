import SpriteKit
import UIKit

/// Delegate protocol notifying `GameController` of gameplay events from `GameScene`.
@MainActor
protocol GameSceneEventsDelegate: AnyObject {
    func gameSceneDidBeginPlaying()
    func gameSceneDidScorePoint(newScore: Int)
    func gameSceneDidTriggerCollision(finalScore: Int)
}

/// Core 2D SpriteKit gameplay scene optimized for 60Hz–120Hz ProMotion displays
/// and scaled proportionally around the iPhone 16 Pro Max (440x956pt) aspect ratio.
@MainActor
final class GameScene: SKScene, SKPhysicsContactDelegate {
    weak var eventsDelegate: GameSceneEventsDelegate?

    private let worldNode = SKNode()
    private let obstacleContainer = SKNode()
    private let effectsContainer = SKNode()

    private var backgroundNode: ParallaxBackgroundNode!
    private var playerNode: PlayerNode!
    private let ceilingBarrierNode = SKSpriteNode()
    private let flashOverlayNode = SKSpriteNode()

    // Pre-allocated pools to avoid mid-gameplay heap allocations
    private var obstaclePool: [ObstaclePairNode] = []
    private var activeObstacles: [ObstaclePairNode] = []

    private(set) var currentPhase: PlayPhase = .menu
    private(set) var score: Int = 0
    private var settings = GameSettings()
    private var currentSkin: CharacterSkin = .defaultSkin

    private var safeTopMarginScene: CGFloat = 62.0
    private var safeBottomMarginScene: CGFloat = 34.0
    private var lastUpdateTimestamp: TimeInterval?
    private var distanceSinceLastSpawn: CGFloat = 0.0
    private var previousGapCenterY: CGFloat?
    private var trailAccumulator: TimeInterval = 0.0

    override init(size: CGSize) {
        super.init(size: size)
        scaleMode = .aspectFill
        backgroundColor = UIColor(red: 0.22, green: 0.66, blue: 0.96, alpha: 1.0)
        setupSceneGraph()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Scene Setup

    private func setupSceneGraph() {
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self

        addChild(worldNode)

        backgroundNode = ParallaxBackgroundNode(sceneSize: size, highContrast: settings.highContrastMode)
        worldNode.addChild(backgroundNode)

        obstacleContainer.zPosition = 5
        worldNode.addChild(obstacleContainer)

        effectsContainer.zPosition = 12
        worldNode.addChild(effectsContainer)

        playerNode = PlayerNode(skin: currentSkin, highContrast: settings.highContrastMode)
        playerNode.zPosition = 15
        worldNode.addChild(playerNode)

        // Subtle upper stratosphere shimmer marking ceiling boundary
        ceilingBarrierNode.anchorPoint = CGPoint(x: 0, y: 1)
        ceilingBarrierNode.position = CGPoint(x: 0, y: size.height)
        ceilingBarrierNode.size = CGSize(width: size.width, height: 14)
        ceilingBarrierNode.color = UIColor(white: 1.0, alpha: 0.24)
        ceilingBarrierNode.zPosition = 18
        worldNode.addChild(ceilingBarrierNode)

        // Full-screen flash node for crisp collision feedback
        flashOverlayNode.anchorPoint = .zero
        flashOverlayNode.position = .zero
        flashOverlayNode.size = size
        flashOverlayNode.color = .white
        flashOverlayNode.alpha = 0.0
        flashOverlayNode.zPosition = 60
        addChild(flashOverlayNode)

        warmUpObstaclePool(count: 5)
        positionPlayerForIdle()
    }

    private func warmUpObstaclePool(count: Int) {
        guard obstaclePool.isEmpty else { return }
        for _ in 0..<count {
            let pair = ObstaclePairNode(highContrast: settings.highContrastMode)
            pair.deactivateToPool()
            obstacleContainer.addChild(pair)
            obstaclePool.append(pair)
        }
    }

    // MARK: - Viewport & Safe Area Adaptation

    func updateViewport(viewBounds: CGSize, safeAreaInsets: UIEdgeInsets) {
        guard viewBounds.width > 10, viewBounds.height > 10 else { return }

        let refHeight = DifficultyProfile.referenceSceneHeight
        let clampedAspect = min(max(viewBounds.width / viewBounds.height, 0.40), 0.65)
        let targetWidth = round(refHeight * clampedAspect)
        let newSceneSize = CGSize(width: targetWidth, height: refHeight)

        let toSceneScale = refHeight / viewBounds.height
        safeTopMarginScene = max(48.0, safeAreaInsets.top * toSceneScale)
        safeBottomMarginScene = max(20.0, safeAreaInsets.bottom * toSceneScale)

        if abs(size.width - newSceneSize.width) > 1.0 || abs(size.height - newSceneSize.height) > 1.0 {
            size = newSceneSize
            backgroundNode.resizeIfNeeded(newSize: newSceneSize)
            ceilingBarrierNode.position = CGPoint(x: 0, y: newSceneSize.height)
            ceilingBarrierNode.size = CGSize(width: newSceneSize.width, height: 14)
            flashOverlayNode.size = newSceneSize

            if currentPhase == .menu || currentPhase == .ready {
                positionPlayerForIdle()
            } else {
                playerNode.position.x = playerAnchorX
            }
        }
    }

    private var playerAnchorX: CGFloat {
        round(size.width * 0.28)
    }

    private var playerIdleCenterY: CGFloat {
        let playableBottom = DifficultyProfile.groundHeight
        let playableTop = size.height - safeTopMarginScene
        return round((playableBottom + playableTop) * 0.52)
    }

    private func positionPlayerForIdle() {
        let anchorX = currentPhase == .menu ? round(size.width * 0.50) : playerAnchorX
        let anchorY = currentPhase == .menu ? round(size.height * 0.58) : playerIdleCenterY
        playerNode.reset(at: CGPoint(x: anchorX, y: anchorY))
    }

    // MARK: - Configuration & State Transitions

    func applyConfiguration(settings: GameSettings, skin: CharacterSkin) {
        let contrastChanged = self.settings.highContrastMode != settings.highContrastMode
        self.settings = settings
        self.currentSkin = skin

        playerNode.applyAppearance(skin: skin, highContrast: settings.highContrastMode)
        backgroundNode.applySettings(highContrast: settings.highContrastMode)

        if contrastChanged {
            for pair in obstaclePool {
                pair.updateContrastAppearance(highContrast: settings.highContrastMode)
            }
        }
    }

    func enterMenuMode() {
        currentPhase = .menu
        score = 0
        lastUpdateTimestamp = nil
        recycleAllObstacles()
        effectsContainer.removeAllChildren()
        worldNode.position = .zero
        backgroundNode.updateAtmosphere(forScore: 0, reducedMotion: settings.reducedMotion, forceImmediate: true)
        positionPlayerForIdle()
    }

    func prepareNewRun() {
        currentPhase = .ready
        score = 0
        lastUpdateTimestamp = nil
        distanceSinceLastSpawn = 0
        previousGapCenterY = nil
        recycleAllObstacles()
        effectsContainer.removeAllChildren()
        worldNode.position = .zero
        backgroundNode.updateAtmosphere(forScore: 0, reducedMotion: settings.reducedMotion, forceImmediate: true)
        positionPlayerForIdle()
    }

    func setPhase(_ phase: PlayPhase) {
        if case .playing = phase {
            lastUpdateTimestamp = nil
        }
        currentPhase = phase
    }

    /// Triggers a single upward hop (either launching from `.ready` or hopping during `.playing`).
    func performPlayerHop() {
        switch currentPhase {
        case .ready:
            currentPhase = .playing
            lastUpdateTimestamp = nil
            // Pre-position first Wind Gate comfortably ahead of the player
            spawnNextObstaclePair(atX: size.width + 110)
            distanceSinceLastSpawn = 0
            executeFlapImpulse()
            eventsDelegate?.gameSceneDidBeginPlaying()

        case .playing:
            executeFlapImpulse()

        default:
            break
        }
    }

    private func executeFlapImpulse() {
        let profile = DifficultyProfile.evaluate(forScore: score, relaxedMode: settings.relaxedFlightMode)
        playerNode.flap(impulseVelocity: profile.hopImpulseVelocity, reducedMotion: settings.reducedMotion)
        AudioManager.shared.play(.flap)
        HapticsManager.shared.playHop()

        if !settings.reducedMotion {
            spawnHopFeatherBurst(at: CGPoint(x: playerNode.position.x - 14, y: playerNode.position.y - 6))
        }
    }

    // MARK: - Touch Handling (Immediate Touch-Down Response)

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard currentPhase == .ready || currentPhase == .playing else { return }
        guard let touch = touches.first else { return }

        // Ignore taps inside the top HUD bar region so tapping Pause never triggers an unintended hop
        let location = touch.location(in: self)
        let hudExclusionFloor = size.height - safeTopMarginScene - 56.0
        if currentPhase == .playing && location.y > hudExclusionFloor {
            let isPauseSide = settings.leftHandedHUD ? (location.x < 96.0) : (location.x > size.width - 96.0)
            if isPauseSide {
                return
            }
        }

        performPlayerHop()
    }

    // MARK: - Frame-Rate Independent Update Loop (60Hz / 80Hz / 120Hz ProMotion)

    override func update(_ currentTime: TimeInterval) {
        let rawDelta: TimeInterval
        if let prev = lastUpdateTimestamp {
            rawDelta = currentTime - prev
        } else {
            rawDelta = 1.0 / 60.0
        }
        lastUpdateTimestamp = currentTime

        // Clamp delta-time to prevent large physics jumps after pause or system interruptions
        let dt = min(max(rawDelta, 0.0), 1.0 / 28.0)

        switch currentPhase {
        case .menu:
            backgroundNode.step(deltaTime: dt, foregroundSpeed: 95.0, scrollGround: true)
            playerNode.updateIdleHover(deltaTime: dt, baseY: round(size.height * 0.58))

        case .ready:
            let profile = DifficultyProfile.evaluate(forScore: 0, relaxedMode: settings.relaxedFlightMode)
            backgroundNode.step(deltaTime: dt, foregroundSpeed: profile.scrollSpeed * 0.72, scrollGround: true)
            playerNode.updateIdleHover(deltaTime: dt, baseY: playerIdleCenterY)

        case .paused, .resuming:
            // Freeze world & physics cleanly while paused or counting down to resume
            break

        case .playing:
            stepActiveGameplay(deltaTime: dt)

        case .dying, .gameOver:
            // Ambient clouds drift very softly after game over
            backgroundNode.step(deltaTime: dt, foregroundSpeed: 18.0, scrollGround: false)
        }
    }

    private func stepActiveGameplay(deltaTime dt: TimeInterval) {
        let profile = DifficultyProfile.evaluate(forScore: score, relaxedMode: settings.relaxedFlightMode)

        // 1. Scroll parallax world & ground
        backgroundNode.step(deltaTime: dt, foregroundSpeed: profile.scrollSpeed, scrollGround: true)

        // 2. Step player flight physics
        playerNode.updateFlight(
            deltaTime: dt,
            gravity: profile.gravity,
            terminalFallVelocity: profile.terminalFallVelocity
        )

        // Optional subtle trail motes on high streaks
        if !settings.reducedMotion && score >= 15 {
            trailAccumulator += dt
            if trailAccumulator >= 0.075 {
                trailAccumulator = 0
                spawnTrailMote(at: CGPoint(x: playerNode.position.x - 18, y: playerNode.position.y))
            }
        }

        // 3. Spawn & advance pooled obstacles
        distanceSinceLastSpawn += profile.scrollSpeed * CGFloat(dt)
        if distanceSinceLastSpawn >= profile.horizontalSpacing {
            distanceSinceLastSpawn -= profile.horizontalSpacing
            spawnNextObstaclePair(atX: size.width + DifficultyProfile.obstacleWidth)
        }

        let bounds = safeGapVerticalBounds(forGapHeight: profile.gapHeight)
        var index = activeObstacles.count - 1
        while index >= 0 {
            let pair = activeObstacles[index]
            pair.step(
                deltaTime: dt,
                scrollSpeed: profile.scrollSpeed,
                minSafeY: bounds.minY,
                maxSafeY: bounds.maxY
            )

            // Award score once player's center passes the Wind Gate center
            if !pair.hasScored && pair.position.x <= playerNode.position.x {
                pair.hasScored = true
                handlePointScored(at: CGPoint(x: pair.position.x, y: pair.currentGapCenterY))
            }

            // Recycle off-screen obstacle back to pool
            if pair.position.x < -DifficultyProfile.obstacleWidth - 40 {
                pair.deactivateToPool()
                activeObstacles.remove(at: index)
            }
            index -= 1
        }

        // 4. Deterministic boundary & obstacle collision verification
        let playerPos = playerNode.position
        let hitRadius = DifficultyProfile.playerHitboxRadius
        let groundTopY = DifficultyProfile.groundHeight
        let ceilingBottomY = size.height - 10.0

        if playerPos.y - hitRadius <= groundTopY {
            playerNode.position.y = groundTopY + hitRadius
            triggerCollision()
            return
        }

        if playerPos.y + hitRadius >= ceilingBottomY {
            playerNode.position.y = ceilingBottomY - hitRadius
            triggerCollision()
            return
        }

        for pair in activeObstacles where pair.intersectsPlayer(center: playerPos, radius: hitRadius) {
            triggerCollision()
            return
        }
    }

    // MARK: - SKPhysicsContactDelegate (Secondary Contact Hook)

    func didBegin(_ contact: SKPhysicsContact) {
        let combinedMask = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        let hitObstacle = (combinedMask & PhysicsCategory.player != 0) &&
                          (combinedMask & (PhysicsCategory.obstacle | PhysicsCategory.boundary) != 0)
        guard hitObstacle, currentPhase == .playing else { return }
        triggerCollision()
    }

    // MARK: - Obstacle Spawning & Pooling

    private func safeGapVerticalBounds(forGapHeight gapHeight: CGFloat) -> (minY: CGFloat, maxY: CGFloat) {
        let halfGap = gapHeight * 0.5
        // Keep lower cap comfortably above scrolling meadow ground
        let minY = DifficultyProfile.groundHeight + 76.0 + halfGap
        // Keep upper cap comfortably below Dynamic Island & top Score HUD
        let topHUDClearance = safeTopMarginScene + 84.0
        let maxY = max(minY + 40.0, size.height - topHUDClearance - halfGap)
        return (minY, maxY)
    }

    private func spawnNextObstaclePair(atX spawnX: CGFloat) {
        let profile = DifficultyProfile.evaluate(forScore: score, relaxedMode: settings.relaxedFlightMode)
        let bounds = safeGapVerticalBounds(forGapHeight: profile.gapHeight)

        let chosenY: CGFloat
        if let prevY = previousGapCenterY {
            // Limit vertical step between consecutive gates so every gap is fairly reachable
            let maxStep: CGFloat = 230.0
            let windowLow = max(bounds.minY, prevY - maxStep)
            let windowHigh = min(bounds.maxY, prevY + maxStep)
            chosenY = CGFloat.random(in: min(windowLow, windowHigh)...max(windowLow, windowHigh))
        } else {
            // First obstacle spawns near comfortable mid-screen altitude
            let mid = (bounds.minY + bounds.maxY) * 0.5
            chosenY = CGFloat.random(in: max(bounds.minY, mid - 75)...min(bounds.maxY, mid + 75))
        }
        previousGapCenterY = chosenY

        let shouldOscillate = Double.random(in: 0...1) < profile.movingGateProbability
        let pair = dequeueObstaclePair()
        pair.activate(
            spawnX: spawnX,
            gapCenterY: chosenY,
            gapHeight: profile.gapHeight,
            oscillates: shouldOscillate,
            amplitude: profile.verticalOscillationAmplitude,
            speed: profile.verticalOscillationSpeed
        )
        activeObstacles.append(pair)
    }

    private func dequeueObstaclePair() -> ObstaclePairNode {
        if let reusable = obstaclePool.first(where: { !$0.isActiveInScene }) {
            return reusable
        }
        let created = ObstaclePairNode(highContrast: settings.highContrastMode)
        obstacleContainer.addChild(created)
        obstaclePool.append(created)
        return created
    }

    private func recycleAllObstacles() {
        for pair in activeObstacles {
            pair.deactivateToPool()
        }
        activeObstacles.removeAll()
    }

    // MARK: - Scoring & Visual Feedback

    private func handlePointScored(at gateCenter: CGPoint) {
        score += 1

        if score % 10 == 0 {
            AudioManager.shared.play(.milestone)
            HapticsManager.shared.playMilestone()
        } else {
            AudioManager.shared.play(.score)
            HapticsManager.shared.playScore()
        }

        if score % 15 == 0 {
            backgroundNode.updateAtmosphere(forScore: score, reducedMotion: settings.reducedMotion)
        }

        spawnFloatingScorePopup(at: CGPoint(x: playerNode.position.x + 12, y: playerNode.position.y + 34))
        eventsDelegate?.gameSceneDidScorePoint(newScore: score)
    }

    private func triggerCollision() {
        guard currentPhase == .playing else { return }
        currentPhase = .dying

        AudioManager.shared.play(.collision)
        HapticsManager.shared.playCollision()

        playerNode.playCollisionReaction(
            groundTopY: DifficultyProfile.groundHeight,
            reducedMotion: settings.reducedMotion
        )

        spawnImpactStarburst(at: playerNode.position)

        if !settings.reducedMotion {
            // Brief crisp flash + camera shake
            flashOverlayNode.removeAllActions()
            flashOverlayNode.alpha = 0.52
            flashOverlayNode.run(.fadeOut(withDuration: 0.22))

            worldNode.removeAllActions()
            let shake = SKAction.sequence([
                SKAction.moveBy(x: -9, y: 6, duration: 0.035),
                SKAction.moveBy(x: 16, y: -10, duration: 0.040),
                SKAction.moveBy(x: -12, y: 7, duration: 0.040),
                SKAction.moveBy(x: 5, y: -3, duration: 0.040),
                SKAction.move(to: .zero, duration: 0.035)
            ])
            worldNode.run(shake)
        }

        eventsDelegate?.gameSceneDidTriggerCollision(finalScore: score)
    }

    // MARK: - Lightweight Pooled/Transient Particle Effects

    private func spawnHopFeatherBurst(at origin: CGPoint) {
        let tex = TextureFactory.shared.softMoteTexture()
        for i in 0..<4 {
            let mote = SKSpriteNode(texture: tex, size: CGSize(width: 11, height: 11))
            mote.position = origin
            mote.color = currentSkin.palette.trail.uiColor
            mote.colorBlendFactor = 0.85
            mote.alpha = 0.88
            effectsContainer.addChild(mote)

            let angle = CGFloat.pi * (0.75 + CGFloat(i) * 0.18)
            let dist = CGFloat.random(in: 22...38)
            let dx = cos(angle) * dist
            let dy = sin(angle) * dist - 10
            let group = SKAction.group([
                SKAction.moveBy(x: dx, y: dy, duration: 0.30),
                SKAction.fadeOut(withDuration: 0.30),
                SKAction.scale(to: 0.25, duration: 0.30)
            ])
            mote.run(.sequence([group, .removeFromParent()]))
        }
    }

    private func spawnTrailMote(at origin: CGPoint) {
        let mote = SKSpriteNode(texture: TextureFactory.shared.softMoteTexture(), size: CGSize(width: 10, height: 10))
        mote.position = origin
        mote.color = currentSkin.palette.trail.uiColor
        mote.colorBlendFactor = 1.0
        mote.alpha = 0.72
        effectsContainer.addChild(mote)

        let drift = SKAction.group([
            SKAction.moveBy(x: -44, y: CGFloat.random(in: -8...8), duration: 0.34),
            SKAction.fadeOut(withDuration: 0.34),
            SKAction.scale(to: 0.2, duration: 0.34)
        ])
        mote.run(.sequence([drift, .removeFromParent()]))
    }

    private func spawnFloatingScorePopup(at origin: CGPoint) {
        let label = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        label.text = "+1"
        label.fontSize = 22
        label.fontColor = UIColor(red: 1.0, green: 0.96, blue: 0.56, alpha: 1.0)
        label.position = origin
        label.zPosition = 25
        effectsContainer.addChild(label)

        let rise = SKAction.group([
            SKAction.moveBy(x: 0, y: 34, duration: 0.48),
            SKAction.sequence([
                SKAction.scale(to: 1.22, duration: 0.10),
                SKAction.scale(to: 0.95, duration: 0.38)
            ]),
            SKAction.sequence([
                SKAction.wait(forDuration: 0.18),
                SKAction.fadeOut(withDuration: 0.30)
            ])
        ])
        label.run(.sequence([rise, .removeFromParent()]))
    }

    private func spawnImpactStarburst(at origin: CGPoint) {
        let ring = SKShapeNode(circleOfRadius: 12)
        ring.position = origin
        ring.strokeColor = UIColor(red: 1.0, green: 0.88, blue: 0.42, alpha: 0.95)
        ring.fillColor = .clear
        ring.lineWidth = 4.0
        effectsContainer.addChild(ring)

        let expand = SKAction.group([
            SKAction.scale(to: 3.4, duration: 0.28),
            SKAction.fadeOut(withDuration: 0.28)
        ])
        ring.run(.sequence([expand, .removeFromParent()]))
    }
}

