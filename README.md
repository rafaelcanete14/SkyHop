# Sky Hop — One-Touch iOS Flying Arcade Game

**Sky Hop** is a complete, original 2D flying arcade game built natively with **Swift**, **SpriteKit**, and **SwiftUI** for **iOS 18+** and tuned primarily for the **iPhone 16 Pro Max** (440 × 956 pt logical viewport, 120Hz ProMotion Super Retina XDR display, Dynamic Island & Home Indicator safe areas), while scaling smoothly across all supported iPhones.

---

## Quick Start (Xcode 16+)

1. Copy or clone this project folder to a Mac running **macOS Sequoia / Sonoma** with **Xcode 16.0 or later**.
2. Open **`SkyHop.xcodeproj`** in Xcode.
3. Select the **`SkyHop`** scheme and choose **iPhone 16 Pro Max (iOS 18.0+)** in the Simulator destination menu (or select your Apple ID / Development Team under **Signing & Capabilities** to deploy to a physical iPhone).
4. Press **`Cmd + R`** to build and play, or **`Cmd + U`** to run the `SkyHopTests` unit test suite.

> **Zero External Asset Setup Required:** All character sprites, multi-layer parallax scenery, Wind Gate spires, sound effects, and looping background music are generated procedurally in memory at launch (`TextureFactory` & `AudioManager`), alongside a bundled 1024×1024 `AppIcon`.

---

## Core Features

- **Responsive One-Touch Flight:** Immediate touch-down (`touchesBegan`) hop physics with smooth velocity-driven pitch rotation, wing-flap burst cycles, blinking, squash-and-stretch feedback, and forgiving circular hitboxes.
- **Original Sky Archipelago Aesthetic:**
  - **6 Unlockable Sky Pufflet Companions:** *Sunbeam Puff*, *Azure Breeze*, *Sakura Petal*, *Emerald Sprout*, *Twilight Nebula*, and *Solar Crest* — unlocked via Best Score milestones or cumulative passed Wind Gates.
  - **Dynamic Parallax Environment:** Score-reactive sky transitions (Morning Sky → Coral Sunset → Starlit Twilight), twinkling stars, drifting clouds, snow-capped mountains, floating waterfall islands, and seamlessly tiled meadow cliffs.
  - **Ancient Wind Gate Obstacles:** Pooled architectural sandstone/crystal columns with fair vertical step limits and gentle vertical oscillation at higher score tiers.
- **iPhone 16 Pro Max Display Optimization:**
  - Native **120Hz ProMotion** support (`preferredFramesPerSecond = 120` + `CADisableMinimumFrameDurationOnPhone`).
  - Clamped delta-time physics integration (`update(_:)`) ensuring identical flight physics across 60Hz, 80Hz, and 120Hz refresh rates.
  - Dynamic Island & Home Indicator safe-area-aware SwiftUI overlays (`MainMenuView`, `HUDView`, `PauseMenuView`, `GameOverView`) and safe obstacle gap bounds.
  - Automatic pause & background GPU suspension on app backgrounding, Notification Center / Control Center pull-down, and audio interruptions.
- **Procedural Audio & Taptic Engine Haptics:**
  - In-memory 44.1 kHz PCM WAV synthesizer (`AudioManager`) generating original wing-hop chirps, crystal gate chimes, 10-point streak arpeggios, unlock fanfare, collision impacts, and a seamless 16-second sky-island background music loop.
  - Pre-warmed `UIImpactFeedbackGenerator` & `UINotificationFeedbackGenerator` haptics.
- **Settings & Accessibility:**
  - Independent SFX & Background Music toggles and volume sliders.
  - **High Contrast Graphics** mode (bold outlines, darker sky, high-visibility Wind Gates).
  - **Reduced Motion** mode (disables screen shake, particle bursts, and sky transitions).
  - **Relaxed Flight (Assist Mode)** (gentler gravity, slower scroll speed, and wider Wind Gate gaps).
  - **Left-Handed HUD** toggle (moves the top Pause button to the top-left corner for comfortable one-handed reach on the 6.9-inch iPhone 16 Pro Max display).
  - VoiceOver labels, modal traits, and named `"Hop Upward"` accessibility action.

---

## Project Architecture

```text
SkyHop.xcodeproj/               # Xcode 16+ project, workspace & shared SkyHop scheme
SkyHop/
├── App/
│   ├── SkyHopApp.swift         # App entry point & ScenePhase lifecycle handling
│   └── ContentView.swift       # Root ZStack layering SpriteKit + SwiftUI overlays
├── Models/
│   ├── GameState.swift         # PlayPhase, SkyMedal & PhysicsCategory definitions
│   ├── CharacterSkin.swift     # 6 original unlockable Sky Pufflet skins & palettes
│   ├── GameSettings.swift      # Codable audio, haptic & accessibility settings
│   └── DifficultyProfile.swift # Smooth progressive difficulty & physics evaluation
├── Services/
│   ├── GameDataStore.swift     # UserDefaults persistence for scores, stats & unlocks
│   ├── AudioManager.swift      # Procedural PCM WAV SFX & background music engine
│   └── HapticsManager.swift    # Low-latency Taptic Engine feedback wrapper
├── Game/
│   ├── GameController.swift    # ObservableObject coordinator between SwiftUI & SpriteKit
│   ├── GameScene.swift         # Delta-time flight loop, pooling, scoring & collisions
│   ├── SpriteKitViewportView.swift # 120Hz ProMotion SKView + safe-area bridge
│   ├── TextureFactory.swift    # Cached @3x vector sprite & scenery renderer
│   ├── PlayerNode.swift        # Animated creature sprite, pitch & collision reaction
│   ├── ObstaclePairNode.swift  # Reusable pooled Wind Gate spires & AABB hit checks
│   └── ParallaxBackgroundNode.swift # Multi-layer parallax clouds, mountains, islands & ground
├── Views/
│   ├── MainMenuView.swift      # Title screen, Best Score & companion summary
│   ├── HUDView.swift           # Dynamic Island-safe score HUD, pause & countdown
│   ├── PauseMenuView.swift     # Frosted pause modal with 3-2-1 smooth resume
│   ├── GameOverView.swift      # Score summary, medals, skin unlock banner & restart
│   ├── SkinSelectorView.swift  # Companion wardrobe & unlock milestone sheet
│   ├── SettingsView.swift      # Audio, haptics, accessibility & progress reset
│   └── Components/
│       ├── GlassCard.swift     # Glassmorphic card & tactile arcade button styles
│       └── MedalBadgeView.swift # Medal badge view
└── Assets.xcassets/            # 1024x1024 AppIcon & AccentColor catalog
SkyHopTests/
└── SkyHopTests.swift           # Unit tests for difficulty, medals & persistence
```

