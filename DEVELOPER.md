# Development & Roadmap

Welcome! This document provides transparency into SudoSodoku's development process, upcoming features, and how we ensure quality. Whether you're a user curious about what's coming next, or a contributor looking to help, this is the place to find information.

---

## 📋 Table of Contents

1. [Feature Roadmap](#feature-roadmap)
2. [Feature Priority](#feature-priority)
3. [Release Checklist](#release-checklist)
4. [Implementation Guidelines](#implementation-guidelines)

---

## 🗺️ Feature Roadmap

### Planned Features (post-2.0)

1. **Hint System** 💡
2. **Tutorial Mode** 📚
3. **Swift Charts Enhancements** 📊
4. **CRT scanlines + vignette** 📺 (#18, deferred from v2.0 by subtraction)
5. **Mechanical keyboard sounds, opt-in** ⌨️ (#19, deferred from v2.0 by subtraction)
6. **iPad Support** 📱 (Deferred indefinitely)
7. **macOS Version** 💻 (Deferred indefinitely)
8. **Custom Themes** 🎨
9. **Variant Sudoku** 🔀
10. **AI Features** 🤖

### Shipped Features

#### v2.0 — the ladder, the feel, the fantasy

**Status**: Shipped (see [CHANGELOG.md](CHANGELOG.md) `[2.0.0]` for the full list)

- **Achievement system** 🏅 — twelve binary unlocks incl. one secret, Game Center reporting with an offline queue (`AchievementManager`)
- **Game Center leaderboards** 🌍 — global ELO plus per-difficulty fastest-time boards; guest play fully supported
- **Hand-crafted-feel generator** — aesthetic clue patterns + per-difficulty technique identity
- **Completion time tracking** — active-time play clock, personal bests by fastest solve
- **Streak indicator**, semantic haptics, breach-log loading, matrix-rain victory sequence
- **Honest statistics** — no win rate in a no-fail game; SOLVED / ELO / FASTEST / HARDEST
- **One continuous command line** — accumulating `sudo sudosodoku` navigation with a boot-in on launch

#### Detailed Statistics 📊 (v1.0)

**Status**: Shipped (baseline)

- `StatisticsManager` with personal bests, difficulty distribution, recent completions
- `StatsView` dashboard
- Logical efficiency scoring based on undo count

### Feature Details

#### 1. Achievement System 🏅

**Status**: ✅ Shipped in v2.0 — `AchievementManager` + `Achievement` model, twelve binary unlocks (completion counts, first MASTER, zero-undo, sub-3-minute, rank tiers, one secret), Game Center reporting with an offline queue, unlocks rendered inside the victory sequence.

---

#### 2. iPad Support 📱

**Priority**: Deferred | **Version**: TBD | **Complexity**: Medium

**Status:** The app currently targets iPhone only. iPad-optimized layouts were removed to reduce maintenance overhead during early development.

**Future features (when revisited):**

- Adaptive layout for larger screens
- Split view support
- Keyboard shortcuts
- Trackpad/mouse support
- Stage Manager support

---

#### 3. Global Leaderboard 🌍

**Status**: ✅ Shipped in v2.0 — Game Center global ELO ranking plus per-difficulty fastest-time boards, terminal-styled `LeaderboardView` (`cat /leaderboard`), `GKAccessPoint` fallback, guest sign-in notice. No CloudKit needed. Friend/regional/historical rankings remain future ideas.

---

#### 4. Hint System 💡

**Priority**: Medium | **Version**: v1.2 | **Complexity**: Medium-High

**Features:**

- Cell hints
- Candidate hints
- Technique hints
- Step-by-step guidance
- Hint cost/limit system

**Implementation:**

- New `HintManager` class
- Hint generation algorithms
- Technique detection
- Cost system

---

#### 5. Tutorial Mode 📚

**Priority**: Medium | **Version**: v1.2 | **Complexity**: Medium

**Features:**

- Interactive tutorials
- Solving techniques guide
- Progressive learning
- Practice puzzles
- Progress tracking

**Implementation:**

- New `TutorialManager` class
- Tutorial content system
- Interactive overlay
- Step-by-step guidance

---

#### 6. macOS Version 💻

**Priority**: Low | **Version**: v2.0 | **Complexity**: High

**Features:**

- Native macOS app
- Window management
- Menu bar integration
- Keyboard navigation
- Trackpad gestures

**Implementation:**

- New macOS target
- Platform-specific UI
- Shared codebase
- macOS-specific features

---

#### 7. Custom Themes 🎨

**Priority**: Low | **Version**: v1.4 | **Complexity**: Medium

**Features:**

- Multiple theme options
- Theme customization
- Theme preview
- Theme persistence

**Implementation:**

- New `ThemeManager` class
- Theme definitions
- Color scheme system
- Theme storage

---

#### 8. Variant Sudoku 🔀

**Priority**: Low | **Version**: v1.5 | **Complexity**: High

**Features:**

- Diagonal Sudoku
- Irregular Sudoku
- Hyper Sudoku
- Windoku
- Killer Sudoku
- Samurai Sudoku

**Implementation:**

- New `VariantSudokuGenerator`
- Variant rule definitions
- Variant-specific validation
- UI adaptations

---

#### 9. AI Features 🤖

**Priority**: Low | **Version**: v2.0+ | **Complexity**: Very High

**Features:**

- AI hints
- Difficulty prediction
- Solving strategy analysis
- Personalized recommendations
- AI solver demonstration

**Implementation:**

- Core ML integration
- Model training
- AI hint generation
- Pattern analysis

---

## 🎯 Feature Priority

> **Note (July 2026):** Paid Apple Developer membership is now active, unlocking
> Game Center leaderboards/achievements and CloudKit. The next App Store release
> is **v2.0**: Game Center features plus a full UX & delight pass. Work items are
> tracked as GitHub issues under the `v2.0` milestone.

### v2.0 — Next App Store Release

**Foundation (done / in progress):**

1. **Unit Test Target** ✅ (`SudoSodokuTests`: generator, rating, storage migration)
2. **Completion Time Tracking** ⏱️ (prerequisite for time leaderboards & speed achievements)

**Game Center:**

3. **Global Leaderboard** 🌍 (ELO board + per-difficulty fastest-time boards)
4. **Achievement System** 🏅

**UX & Delight (three tiers, all in scope):**

5. **Tier A — Fluidity**: auto-clear peer notes (compound undo), numpad digit
   strike-out when exhausted, no-selection affordance, haptic hierarchy
   (`.sensoryFeedback` + CoreHaptics), error shake, sliding selection frame
6. **Tier B — Signature moments**: `sudoers` joke on first MASTER entry,
   breach-log loading screen, unit-completion phosphor pulse, victory sequence
   rework (matrix rain + typewriter + ELO count-up), streak indicator
7. **Tier C — Ambience**: CRT scanlines + vignette (toggleable), mechanical key
   sounds (opt-in), cold-launch boot sequence (skippable)

**Accessibility baseline:** every animation must respect Reduce Motion; error
states never rely on color alone; sounds are never forced on.

### v2.1 — Cloud Sync

8. **iCloud Sync** ☁️ (CloudKit private database + `CKSyncEngine`)

### v2.2 — Statistics

9. **Swift Charts Enhancements** 📊 (rating trend, solve-time trend, streaks)

### Later (v2.3+)

10. **Hint System** 💡
11. **Tutorial Mode** 📚
12. **Custom Themes** 🎨
13. **Variant Sudoku** 🔀

### Deferred (not planned)

- **iPad Support** 📱 / **macOS Version** 💻 — iPhone-only for the foreseeable future
- **AI Features** 🤖

---

## ✅ Quality Assurance

We take quality seriously. Before every release, we thoroughly test all features to ensure you have the best possible experience. Here's what we check:

### Pre-Release Testing

#### Functionality Tests

- [ ] **Game Generation**
  - [ ] All difficulty levels generate correctly
  - [ ] All puzzles are solvable
  - [ ] Difficulty scores are within expected ranges

- [ ] **Gameplay**
  - [ ] Number input works correctly
  - [ ] Pencil mode toggles properly
  - [ ] Notes display correctly
  - [ ] Undo/Redo functions properly
  - [ ] Clear cell works
  - [ ] Error detection highlights conflicts
  - [ ] Victory detection triggers correctly
  - [ ] Victory animation displays

- [ ] **Archive System**
  - [ ] Games auto-save during play
  - [ ] Archive view displays all records
  - [ ] Favorites system works
  - [ ] Filter by favorites works
  - [ ] Batch operations work
  - [ ] Replay functionality works

- [ ] **Rating System**
  - [ ] Rating increases on completion
  - [ ] Rating calculation is correct
  - [ ] Rank titles display correctly
  - [ ] User profile shows correct statistics
  - [ ] Anti-smurfing works

- [ ] **Data Persistence**
  - [ ] Games save/load correctly
  - [ ] Local storage works reliably
  - [ ] Data migration works

#### UI/UX Tests

- [ ] Terminal aesthetic is consistent
- [ ] All text is readable
- [ ] Icons display correctly
- [ ] Animations are smooth
- [ ] Haptic feedback works
- [ ] Navigation works correctly

#### Platform Tests

- [ ] App runs on iPhone simulator
- [ ] App runs on physical iPhone (if available)
- [ ] Performance is acceptable
- [ ] No crashes during extended play

#### Build Tests

- [ ] Debug build succeeds
- [ ] Release build succeeds
- [ ] Clean build works
- [ ] No warnings (or acceptable warnings)
- [ ] Unit tests pass (`SudoSodokuTests` via Cmd+U or `xcodebuild test`)

### Code Quality

- [ ] All code comments are in English
- [ ] Code follows Swift conventions
- [ ] MVVM pattern is maintained
- [ ] Error handling is appropriate
- [ ] Memory management is correct

### Documentation

- [ ] README.md is up to date
- [ ] CHANGELOG.md is updated
- [ ] Code comments are clear

### Version Management

- [ ] Version number updated
- [ ] Version displayed in app
- [ ] All version references updated

### Assets

- [ ] App icon is set
- [ ] All assets are included
- [ ] No missing images

---

## 🛠️ For Contributors

If you're interested in contributing code, here are our development guidelines:

### Code Organization

We follow these principles:
- **MVVM Pattern**: Maintain clear separation between Models, Views, and ViewModels
- **File Structure**: Place files in appropriate directories (Models, Views, Managers, etc.)
- **Dependency Injection**: Use shared instances appropriately
- **Backward Compatibility**: Ensure updates don't break existing functionality

### Testing

We test thoroughly:
- Unit tests for core logic
- UI tests for new features
- Performance testing
- User acceptance testing

### Documentation

We maintain documentation:
- Update README for user-facing changes
- Add clear code comments (in English)
- Update CHANGELOG for releases
- Create guides for complex features

### Git Workflow

Our contribution process:
- Create feature branches (`feature/your-feature`)
- Write descriptive commit messages (see CONTRIBUTING.md)
- Update CHANGELOG before merging
- Tag releases appropriately

---

## 📝 Dependencies & Requirements

### External Dependencies

- **Game Center**: For achievements and leaderboards
- **CloudKit**: For global leaderboard data (future)
- **Core ML**: For AI features
- **Swift Charts**: For statistics visualization

### Apple Developer Requirements

- Paid Apple Developer Account ($99/year) — **active since July 2026**
- Game Center configuration (leaderboards & achievements in App Store Connect)
- CloudKit container setup
- App Store Connect configuration

### Technical Requirements

- iOS 17.0+ (current)
- macOS 14.0+ (for macOS version)
- Xcode 15.0+
- Swift 5.9+

---

*Last Updated: July 5, 2026*  
*Current Version: 1.0.0*
