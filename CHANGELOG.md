# Changelog

All notable changes to SudoSodoku will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Added

- Completion time tracking: play clock accumulates active time per game, pauses in the background and freezes on victory; terminal-style `T+MM:SS` timer in the game header (toggleable via the game menu), duration shown on victory, in archive rows, and in personal bests (#4)
- Auto-clear pencil notes: placing a number removes that digit from notes in the same row, column, and box; undo/redo treats the placement and cleared notes as one compound move (#5)
- Numpad digit keys dim and strike through once all nine instances of a digit are placed; undo/clear revives them (#6)
- Numpad dims when no cell is selected and taps give a warning haptic nudge instead of being silently swallowed (#7)
- Semantic haptic vocabulary: selection tick on cell changes (`.sensoryFeedback`), rigid impact on placement, soft impact on removal/notes, error notification on conflicts, and a custom CoreHaptics victory pattern (three ascending ticks + rumble) with graceful fallback (#8)
- Conflicting placements shake the cell with a short CRT-glitch jitter alongside the error haptic; disabled under Reduce Motion (#9)
- The selection frame is now a single shared rectangle that glides between cells with a spring instead of jumping; instant under Reduce Motion (#10)
- Game Center leaderboards: global ELO ranking plus per-difficulty fastest-time boards; victories submit the solve time (whole seconds) and rating gains submit the new ELO; terminal-styled leaderboard screen (`cat /leaderboard` in the profile) with guest sign-in notice and `GKAccessPoint` fallback (#11)
- Breach-log loading screen: puzzle generation now plays a typewriter terminal log (`$ sudo breach --target=grid_9x9`) whose verdict lines report the real uniqueness check and difficulty index; instant under Reduce Motion (#12)
- Victory sequence rework: real matrix rain (TimelineView + Canvas), typewriter `ACCESS GRANTED`, ELO ticker rolling to the new value with a rank-up ceremony on tier crossings; dismissed by tap instead of a 2-second timer; fade-only under Reduce Motion (#13)
- Achievement system: twelve binary unlocks (first solve, solve counts, first MASTER, zero-undo, sub-3-minute solve, rank tiers, one secret) evaluated on victory, persisted locally, reported to Game Center with an offline queue; terminal toast on unlock and an achievement wall in the profile (#14)
- The sudoers joke: the first MASTER game opens with "<user> is not in the sudoers file. This incident will be reported." before the punchline grants root access — once ever, tap to skip, and it unlocks the secret INCIDENT_REPORTED achievement (#15)
- Phosphor pulse: completing a row, column, or box flashes a brief green glow over the unit with a medium haptic; one haptic per move with victory > unit > placement priority (#16)
- Streak indicator: five or more consecutive conflict-free placements show `streak: N ▲` in the game header; a conflict resets it silently (#17)
- `SudoSodokuTests` unit test target covering puzzle generation (solvability, unique solution, difficulty scoring), ELO rating (K-factor tiers, anti-smurfing), and storage (persistence roundtrip, legacy save migration)
- Shared `SudoSodoku` scheme with test action, enabling `xcodebuild test` and Xcode Cloud test workflows
- Product identity: slogan "sudo solve — root access for logical purists", four-pillar philosophy in the README, and the tagline on the landing screen
- Debug builds only: `$ rm -rf /user_data` factory reset in the profile (records, rating, achievements, sudoers-joke flag, and Game Center achievement progress via `resetAchievements`) for verifying first-run flows; compiled out of Release

### Changed

- Puzzles now read as hand-crafted: each board picks an aesthetic clue-pattern style at random (180° rotational, horizontal/vertical mirror, diagonal, anti-diagonal, or deliberately free — hand-made collections vary, symmetry is common but not universal), and every difficulty has a technique identity enforced at generation — EASY solves with singles and always offers parallel moves, MEDIUM never demands more than locked candidates / naked pairs, HARD is designed around a required intermediate "aha" (and never needs more — no guessing), MASTER resists intermediate techniques entirely (#39)
- Leaderboard submissions previously sent the puzzle difficulty index (0-100), which ranked players by generation luck; scores are now actual performance — solve time per difficulty, ELO on the global board (#11)
- Set minimum deployment target to iOS 17.0 (aligned project and target settings)
- iPhone-only app: removed iPad-specific views, routing, and orientation settings
- Updated documentation to reflect local-only persistence (no iCloud sync)
- Aligned Game Center leaderboard IDs with bundle prefix (`dev.kaichen.sudoku.app.leaderboard.*`)
- Moved `ContentView` into `Views/` and extracted shared utilities (`AppConstants`, `DateFormatting`, `RankTier`, `LogicalEfficiencyStyle`)
- Centralized rank tiers, date formatting, and efficiency colors; removed duplicate logic across views
- `StatisticsManager` now auto-refreshes when storage changes
- `StorageManager` uses atomic JSON writes; `SudokuGame` preserves session `startTime` across saves
- Game Center auth runs once at app root; removed duplicate `authenticateUser()` calls
- Rating anti-smurfing: zero gain when puzzle difficulty is far below player ELO
- Unified signing config, Swift 5.9, marketing version `1.0.0`, and `play.sh` bundle ID fallback
- Landing page version reads from app bundle instead of hardcoded string
- Fixed swapped section bodies in DEVELOPER.md (Achievement System / iPad Support) and aligned the roadmap tiers with the phased v1.1-v1.3 plan

### Fixed

- Profile (WHOAMI) statistics desynced from storage: `@Published` emits on willSet, and the stats refresh read the records back through the singleton — always one mutation behind. Zeros stuck on a fresh launch, numbers survived the debug wipe, and only playing a move "fixed" them. Stats now derive from the emitted value (#41)
- Achievement unlocks had no visible feedback: the toast raced the victory overlay and could expire unseen behind the matrix rain. Unlocks now render inside the victory sequence itself (`>> UNLOCKED: ...` under the ELO ticker), and the sudoers interstitial types out its own secret-achievement line — the separate toast and its cross-view choreography are gone
- Pinned `IPHONEOS_DEPLOYMENT_TARGET` back to the literal `17.0` on all targets: Xcode's "Update to recommended settings" had rewritten it to `$(RECOMMENDED_IPHONEOS_DEPLOYMENT_TARGET)`, which Xcode Cloud's toolchain resolves to nothing, dropping the deployment target to the SDK floor and failing builds with iOS 16/17 availability errors

### Removed

- `Views-iPad/` directory and `ViewRouter` platform routing
- Dead Game Center UI helpers, unused haptic methods, and unused statistics trend code
- Duplicate `run.sh` script (use `play.sh` as the canonical simulator runner)
- Committed build artifacts (`SudoSodoku.xcarchive/`, `IPA/`) from version control

---

## [1.0.0] - 2026-01-02

### 🎉 First Official Release

SudoSodoku v1.0.0 marks a major milestone - the first stable release of our terminal-style Sudoku experience. After months of development and beta testing, we're excited to share this polished, feature-complete game with the community.

**System Requirements (at release):**

- iOS 17.0 or later
- Minimal storage (~5MB)
- Optional internet (for Game Center)

**What's Next:**
See [DEVELOPER.md](DEVELOPER.md) for the current roadmap.

### ✨ Added

#### Core Gameplay

- **Procedural Puzzle Generation**: Real-time generation of unique, solvable Sudoku puzzles using backtracking algorithm
- **Four Difficulty Levels**: Easy, Medium, Hard, and Master with intelligent difficulty scoring (0-100)
- **Pencil Mode**: Toggle candidate notes for complex deduction strategies
- **Undo/Redo System**: Full history stack allowing fearless experimentation
- **Error Detection**: Real-time validation highlighting conflicts
- **Victory Detection**: Automatic completion detection with celebration animation

#### User Interface

- **Terminal Aesthetic**: Authentic green phosphor (#00FF00) on deep dark background (#0D121A)
- **Matrix Victory Animation**: Cyberpunk-style celebration overlay
- **Haptic Feedback**: Mechanical keyboard-like haptics for every interaction
- **Smooth Animations**: Bouncy button effects and cell selection animations
- **Progress Tracking**: Visual progress indicators for incomplete puzzles

#### Game Management

- **Smart Archives**: Automatic saving of unfinished sessions
- **Favorites System**: Mark and quickly access favorite puzzles
- **Archive Management**: Browse, filter, and manage game history
- **Batch Operations**: Multi-select for deleting or favoriting multiple records
- **Replay Functionality**: Restart completed puzzles or view solutions

#### Competitive Features

- **ELO Rating System**: Dynamic rating starting at 1200 (USER rank)
- **Rank Progression**: Six distinct ranks from SCRIPT_KIDDIE to THE_ARCHITECT
- **Adaptive K-Factor**: Rating changes stabilize at higher tiers
- **Anti-Smurfing**: High-level players gain minimal rating from easy puzzles
- **User Profile**: Comprehensive statistics and rank display

#### Data Persistence

- **iCloud Sync**: Automatic cloud synchronization across devices
- **Local Fallback**: Graceful degradation to local storage if iCloud unavailable
- **Data Migration**: Automatic migration from v2/v3/v4 save formats
- **JSON Serialization**: Codable structs ensuring backward compatibility

#### Game Center Integration

- **Seamless Authentication**: Password-less login via Game Center
- **Profile Management**: Display player name and photo
- **Cross-Device Sync**: Game state synchronization through iCloud

### 🏗️ Architecture

#### Code Organization

- **Modular Structure**: Refactored from single-file to organized multi-file architecture
- **MVVM Pattern**: Strict separation of Models, Views, and ViewModels
- **Component-Based UI**: Reusable SwiftUI components
- **Manager Classes**: Centralized management for haptics, storage, ratings, and Game Center

#### Directory Structure

```
SudoSodoku/
├── Models/          # Data models (GameRecord, SudokuCell, Difficulty, etc.)
├── ViewModels/      # Business logic (SudokuGame)
├── Managers/        # System managers (Storage, Rating, Haptic, GameCenter)
├── Views/           # UI components and screens
│   ├── Components/  # Reusable UI components
│   └── Styles/      # Custom styles and themes
└── Algorithms/      # Core puzzle generation logic
```

### 🛠️ Developer Experience

#### Build Tools

- **Build Scripts**: Command-line build scripts for Cursor/VS Code development
  - `build.sh`: Build project (Debug/Release/Clean)
  - `play.sh`: Build and run in iOS Simulator
- **Task Integration**: VS Code tasks for keyboard shortcuts (Cmd+Shift+B)
- **Documentation**: Comprehensive README with build instructions

### 📱 Platform Support

- **iOS 17.0+**: Minimum deployment target
- **iPhone**: Optimized for iPhone devices
- **iPad**: Universal app support
- **Simulator**: Full support for iOS Simulator testing

### 🔧 Technical Details

- **Language**: Swift 5.9
- **UI Framework**: SwiftUI (Declarative UI)
- **State Management**: ObservableObject + Combine
- **Persistence**: FileManager + iCloud Documents
- **Game Framework**: GameKit for Game Center integration

### 🐛 Fixed

- Fixed missing Combine import in MatrixVictoryOverlay
- Fixed missing SwiftUI import in StorageManager
- Resolved gesture conflicts between animations and cell selection
- Improved data migration logic for legacy save files

### 📝 Documentation

- Complete README with feature overview
- Build instructions for both Xcode and command-line
- Code organization documentation
- Architecture overview

---

## [0.5.0] - 2025-12-05 (Beta)

### Added

- Initial beta release
- Core gameplay mechanics
- Basic UI implementation
- Game Center integration
- Archive system

---

*For detailed feature descriptions, see [README.md](README.md)*
