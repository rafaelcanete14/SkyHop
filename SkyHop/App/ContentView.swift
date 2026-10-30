import SwiftUI

/// Root container layering the full-bleed 120Hz SpriteKit viewport underneath
/// safe-area-aware SwiftUI menus, HUD controls, and modal sheets.
struct ContentView: View {
    @ObservedObject var controller: GameController
    @ObservedObject var dataStore: GameDataStore

    var body: some View {
        ZStack {
            // Full-screen SpriteKit viewport extending edge-to-edge behind Dynamic Island & Home Indicator
            SpriteKitViewportView(
                scene: controller.scene,
                isPausedForBackground: controller.isSceneViewPausedForBackground
            )
            .ignoresSafeArea()
            .accessibilityAction(named: Text("Hop Upward")) {
                controller.scene.performPlayerHop()
            }

            // Safe-area-aware UI overlays
            switch controller.phase {
            case .menu:
                MainMenuView(controller: controller, dataStore: dataStore)
                    .transition(.opacity)

            case .ready, .playing, .resuming, .dying:
                HUDView(controller: controller, dataStore: dataStore)
                    .transition(.opacity)

            case .paused:
                HUDView(controller: controller, dataStore: dataStore)
                PauseMenuView(controller: controller, dataStore: dataStore)
                    .transition(.opacity)

            case .gameOver:
                GameOverView(controller: controller, dataStore: dataStore)
                    .transition(.scale(scale: 0.94).combined(with: .opacity))
            }
        }
        .statusBarHidden(true)
        .defersSystemGestures(on: .bottom)
        .sheet(isPresented: $controller.isShowingSkins) {
            SkinSelectorView(dataStore: dataStore)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $controller.isShowingSettings) {
            SettingsView(dataStore: dataStore)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }
}

