import SwiftUI
import SpriteKit

/// Custom `SKView` subclass configured for 120Hz ProMotion displays that automatically
/// forwards viewport bounds and Dynamic Island / Home Indicator safe-area insets to `GameScene`.
final class ViewportAwareSKView: SKView {
    weak var targetGameScene: GameScene?

    override func layoutSubviews() {
        super.layoutSubviews()
        syncViewportToScene()
    }

    override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        syncViewportToScene()
    }

    private func syncViewportToScene() {
        let resolvedInsets: UIEdgeInsets
        if safeAreaInsets.top > 0 || safeAreaInsets.bottom > 0 {
            resolvedInsets = safeAreaInsets
        } else if let windowInsets = window?.safeAreaInsets {
            resolvedInsets = windowInsets
        } else {
            resolvedInsets = UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0)
        }
        targetGameScene?.updateViewport(viewBounds: bounds.size, safeAreaInsets: resolvedInsets)
    }
}

/// Bridges `GameScene` into SwiftUI with ProMotion 120fps support and background GPU suspension.
struct SpriteKitViewportView: UIViewRepresentable {
    let scene: GameScene
    let isPausedForBackground: Bool

    func makeUIView(context: Context) -> ViewportAwareSKView {
        let skView = ViewportAwareSKView(frame: .zero)
        skView.preferredFramesPerSecond = 120
        skView.ignoresSiblingOrder = true
        skView.shouldCullNonVisibleNodes = true
        skView.isMultipleTouchEnabled = false
        skView.allowsTransparency = false
        skView.showsFPS = false
        skView.showsNodeCount = false

        skView.targetGameScene = scene
        skView.presentScene(scene)
        return skView
    }

    func updateUIView(_ uiView: ViewportAwareSKView, context: Context) {
        uiView.targetGameScene = scene
        if uiView.scene !== scene {
            uiView.presentScene(scene)
        }
        uiView.isPaused = isPausedForBackground
    }
}

