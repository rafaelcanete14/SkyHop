import SwiftUI

@main
struct SkyHopApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var gameController = GameController()

    var body: some Scene {
        WindowGroup {
            ContentView(controller: gameController, dataStore: gameController.dataStore)
                .preferredColorScheme(.dark)
        }
        .onChange(of: scenePhase) { _, newPhase in
            gameController.handleScenePhaseChange(newPhase)
        }
    }
}
