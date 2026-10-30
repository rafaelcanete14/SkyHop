import XCTest
@testable import SkyHop

@MainActor
final class SkyHopTests: XCTestCase {
    func testDifficultyScalesSmoothlyWithScore() {
        let initial = DifficultyProfile.evaluate(forScore: 0, relaxedMode: false)
        let mid = DifficultyProfile.evaluate(forScore: 20, relaxedMode: false)
        let master = DifficultyProfile.evaluate(forScore: 60, relaxedMode: false)

        XCTAssertLessThan(initial.scrollSpeed, mid.scrollSpeed)
        XCTAssertLessThan(mid.scrollSpeed, master.scrollSpeed)

        XCTAssertGreaterThan(initial.gapHeight, mid.gapHeight)
        XCTAssertGreaterThan(mid.gapHeight, master.gapHeight)
        XCTAssertGreaterThanOrEqual(master.gapHeight, 170.0, "Gap must never shrink below fair playable bounds")
    }

    func testRelaxedFlightAssistModeWidensGapAndSoftensSpeed() {
        let standard = DifficultyProfile.evaluate(forScore: 15, relaxedMode: false)
        let relaxed = DifficultyProfile.evaluate(forScore: 15, relaxedMode: true)

        XCTAssertGreaterThan(relaxed.gapHeight, standard.gapHeight)
        XCTAssertLessThan(relaxed.scrollSpeed, standard.scrollSpeed)
        XCTAssertGreaterThan(relaxed.gravity, standard.gravity) // Less negative downward pull
    }

    func testMedalThresholds() {
        XCTAssertEqual(SkyMedal.earned(for: 0), .none)
        XCTAssertEqual(SkyMedal.earned(for: 4), .none)
        XCTAssertEqual(SkyMedal.earned(for: 5), .bronze)
        XCTAssertEqual(SkyMedal.earned(for: 15), .silver)
        XCTAssertEqual(SkyMedal.earned(for: 30), .gold)
        XCTAssertEqual(SkyMedal.earned(for: 50), .prism)
    }

    func testHighScorePersistenceAndSkinUnlocks() {
        let suiteName = "com.skyhop.tests.\(UUID().uuidString)"
        guard let testDefaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Failed to create isolated UserDefaults suite")
            return
        }
        defer { testDefaults.removePersistentDomain(forName: suiteName) }

        let store = GameDataStore(defaults: testDefaults)
        XCTAssertEqual(store.bestScore, 0)
        XCTAssertTrue(store.isSkinUnlocked(CharacterSkin.defaultSkin))

        let firstRun = store.recordCompletedRun(score: 6)
        XCTAssertTrue(firstRun.isNewBest)
        XCTAssertEqual(store.bestScore, 6)
        XCTAssertFalse(firstRun.newlyUnlockedSkins.isEmpty, "Azure Breeze unlocks at Best Score 5")

        let secondRun = store.recordCompletedRun(score: 3)
        XCTAssertFalse(secondRun.isNewBest)
        XCTAssertEqual(store.bestScore, 6)
        XCTAssertEqual(store.totalGatesPassed, 9)
    }
}

