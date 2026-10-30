import SpriteKit

/// Playable flying Sky Pufflet node with animated wings, gentle idle bobbing,
/// velocity-driven pitch rotation, blinking, and collision animation.
@MainActor
final class PlayerNode: SKNode {
    private let bodySprite: SKSpriteNode
    private var skin: CharacterSkin
    private var highContrast: Bool

    /// Vertical velocity in scene points per second (integrated with clamped delta-time for 60Hz/120Hz consistency).
    var verticalVelocity: CGFloat = 0.0

    private var wingTimer: TimeInterval = 0.0
    private var wingFrameIndex: Int = 0
    private var flapBoostTimer: TimeInterval = 0.0
    private var blinkCooldown: TimeInterval = 2.8
    private var activeBlinkTimer: TimeInterval = 0.0
    private var idleBobTime: TimeInterval = 0.0
    private var isCollidedState: Bool = false

    private static let spriteSize = CGSize(width: 68, height: 56)

    init(skin: CharacterSkin, highContrast: Bool) {
        self.skin = skin
        self.highContrast = highContrast
        let initialTex = TextureFactory.shared.playerTexture(skin: skin, pose: .wingMid, highContrast: highContrast)
        self.bodySprite = SKSpriteNode(texture: initialTex, size: Self.spriteSize)
        super.init()

        bodySprite.zPosition = 1
        addChild(bodySprite)
        configurePhysicsBody()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configurePhysicsBody() {
        let body = SKPhysicsBody(circleOfRadius: DifficultyProfile.playerHitboxRadius)
        body.isDynamic = true
        body.affectedByGravity = false // Custom delta-time gravity keeps 60Hz & 120Hz ProMotion identical
        body.allowsRotation = false
        body.restitution = 0.0
        body.friction = 0.0
        body.linearDamping = 0.0
        body.usesPreciseCollisionDetection = true
        body.categoryBitMask = PhysicsCategory.player
        body.contactTestBitMask = PhysicsCategory.obstacle | PhysicsCategory.boundary | PhysicsCategory.scoreGate
        body.collisionBitMask = PhysicsCategory.none
        self.physicsBody = body
    }

    func applyAppearance(skin: CharacterSkin, highContrast: Bool) {
        self.skin = skin
        self.highContrast = highContrast
        refreshCurrentFrameTexture()
    }

    /// Resets creature to upright, calm hover pose at the given starting position.
    func reset(at startPosition: CGPoint) {
        removeAllActions()
        bodySprite.removeAllActions()
        position = startPosition
        zRotation = 0
        bodySprite.position = .zero
        bodySprite.setScale(1.0)
        verticalVelocity = 0
        isCollidedState = false
        flapBoostTimer = 0
        wingFrameIndex = 1
        blinkCooldown = Double.random(in: 2.2...4.0)
        activeBlinkTimer = 0
        refreshCurrentFrameTexture()
    }

    /// Triggers an upward flap impulse with squash-and-stretch body bounce and brisk wing cycle.
    func flap(impulseVelocity: CGFloat, reducedMotion: Bool) {
        guard !isCollidedState else { return }
        verticalVelocity = impulseVelocity
        flapBoostTimer = 0.24
        wingFrameIndex = 0
        wingTimer = 0
        refreshCurrentFrameTexture()

        if !reducedMotion {
            bodySprite.removeAction(forKey: "squashStretch")
            let stretch = SKAction.scaleX(to: 0.93, y: 1.09, duration: 0.065)
            let rebound = SKAction.scaleX(to: 1.04, y: 0.96, duration: 0.085)
            let settle = SKAction.scale(to: 1.0, duration: 0.08)
            bodySprite.run(.sequence([stretch, rebound, settle]), withKey: "squashStretch")
        }
    }

    /// Updates idle floating animation used on the Main Menu and Ready states.
    func updateIdleHover(deltaTime dt: TimeInterval, baseY: CGFloat) {
        idleBobTime += dt
        let offset = CGFloat(sin(idleBobTime * 3.4)) * 9.0
        position.y = baseY + offset
        zRotation = CGFloat(cos(idleBobTime * 3.4)) * 0.06
        advanceWingAndBlink(deltaTime: dt, wingInterval: 0.115)
    }

    /// Integrates vertical flight physics and smooth pitch rotation independent of display refresh rate.
    func updateFlight(deltaTime dt: TimeInterval, gravity: CGFloat, terminalFallVelocity: CGFloat) {
        guard !isCollidedState else { return }

        let dtf = CGFloat(dt)
        verticalVelocity = max(terminalFallVelocity, verticalVelocity + gravity * dtf)
        position.y += verticalVelocity * dtf

        // Map vertical velocity to natural pitch angle (+24 deg upward hop -> -68 deg steep dive)
        let targetRotation: CGFloat
        if verticalVelocity >= 0 {
            let ratio = min(1.0, verticalVelocity / 540.0)
            targetRotation = 0.42 * ratio
        } else {
            let fallRatio = min(1.0, abs(verticalVelocity) / abs(terminalFallVelocity))
            targetRotation = -1.18 * pow(fallRatio, 1.35)
        }

        let turnSpeed: CGFloat = verticalVelocity >= 0 ? 14.0 : 6.5
        let blend = min(1.0, turnSpeed * dtf)
        zRotation += (targetRotation - zRotation) * blend

        if flapBoostTimer > 0 {
            flapBoostTimer = max(0, flapBoostTimer - dt)
        }
        let interval = flapBoostTimer > 0 ? 0.055 : 0.115
        advanceWingAndBlink(deltaTime: dt, wingInterval: interval)
    }

    /// Plays startled collision pose and short tumble reaction before the Game Over overlay appears.
    func playCollisionReaction(groundTopY: CGFloat, reducedMotion: Bool) {
        guard !isCollidedState else { return }
        isCollidedState = true
        verticalVelocity = 0
        bodySprite.texture = TextureFactory.shared.playerTexture(
            skin: skin,
            pose: .collided,
            highContrast: highContrast
        )

        bodySprite.removeAllActions()
        if !reducedMotion {
            let pop = SKAction.scale(to: 1.18, duration: 0.07)
            let settle = SKAction.scale(to: 1.0, duration: 0.14)
            bodySprite.run(.sequence([pop, settle]))
        }

        let targetY = max(groundTopY + DifficultyProfile.playerHitboxRadius, position.y - 42)
        let dropDuration: TimeInterval = 0.36
        let hopArc = SKAction.sequence([
            SKAction.moveBy(x: -10, y: 18, duration: 0.10),
            SKAction.moveTo(y: targetY, duration: dropDuration - 0.10)
        ])
        let spin = SKAction.rotate(toAngle: -.pi * 0.42, duration: dropDuration, shortestUnitArc: true)
        run(.group([hopArc, spin]))
    }

    // MARK: - Frame Stepping

    private func advanceWingAndBlink(deltaTime dt: TimeInterval, wingInterval: TimeInterval) {
        guard !isCollidedState else { return }

        wingTimer += dt
        if wingTimer >= wingInterval {
            wingTimer -= wingInterval
            wingFrameIndex = (wingFrameIndex + 1) % 4
            refreshCurrentFrameTexture()
        }

        if activeBlinkTimer > 0 {
            activeBlinkTimer -= dt
            if activeBlinkTimer <= 0 {
                activeBlinkTimer = 0
                refreshCurrentFrameTexture()
            }
        } else {
            blinkCooldown -= dt
            if blinkCooldown <= 0 {
                activeBlinkTimer = 0.11
                blinkCooldown = Double.random(in: 2.6...4.8)
                refreshCurrentFrameTexture()
            }
        }
    }

    private func refreshCurrentFrameTexture() {
        let pose: PlayerPose
        if isCollidedState {
            pose = .collided
        } else if activeBlinkTimer > 0 {
            pose = .blink
        } else {
            switch wingFrameIndex {
            case 0: pose = .wingUp
            case 1: pose = .wingMid
            case 2: pose = .wingDown
            default: pose = .wingMid
            }
        }
        bodySprite.texture = TextureFactory.shared.playerTexture(
            skin: skin,
            pose: pose,
            highContrast: highContrast
        )
    }
}

