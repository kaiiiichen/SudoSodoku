# Contributing to SudoSodoku

Thank you for your interest in contributing! This document describes how this repository actually works — read it before opening a PR.

## 🎯 What We Welcome

* 🐛 **Bug reports** — especially consistency bugs (stats, archives, achievements disagreeing with each other)
* 💡 **Feature requests** — measured against the four-pillar philosophy in the [README](README.md)
* 📝 **Documentation** improvements
* ⚡ **Performance** work (the generator's dig loop is the hot path)
* 🧪 **Tests** — generator, rating, and storage logic must stay covered

### 🚫 What we will decline

* Ads, paywalls, lives, guilt mechanics, or anything that violates "pure logic, zero noise"
* iPad or macOS support (deferred indefinitely — iPhone only, `TARGETED_DEVICE_FAMILY = 1`)
* Animations that ignore Reduce Motion, or sounds that force themselves on
* Telemetry, analytics, or anything that moves user data off the device
* Closed-source dependencies

## 🚀 Getting Started

### Prerequisites

* macOS 13.0+, Xcode 15.0+ with Command Line Tools, Git

### Setup

1. **Fork and clone**

   ```bash
   git clone https://github.com/YOUR_USERNAME/SudoSodoku.git
   cd SudoSodoku
   ```

2. **Open `SudoSodoku.xcodeproj`**, set your own Team under Signing & Capabilities.

3. **Build and run**: `Cmd + R` in Xcode, or `./build.sh` / `./play.sh` from the terminal.

## ⚠️ Project-Specific Rules (the ones that bite)

These are the non-obvious constraints; violating them breaks CI or the App Store build:

1. **Never commit directly to `main`.** Every change — including docs-only — goes through a feature branch and a pull request.

2. **`IPHONEOS_DEPLOYMENT_TARGET` must stay the literal `17.0`** in `project.pbxproj`. Do **not** accept Xcode's "Update to recommended settings" suggestion that rewrites it to `$(RECOMMENDED_IPHONEOS_DEPLOYMENT_TARGET)` — Xcode Cloud resolves that macro to nothing and the build fails with iOS 16/17 availability errors.

3. **Don't hand-register files in `project.pbxproj`.** The project uses Xcode's synchronized folder groups: new files under `SudoSodoku/` or `SudoSodokuTests/` are picked up automatically. (Corollary: files that must *not* be bundled as resources — like the merged `Info.plist` — live outside those folders, e.g. `Config/`.)

4. **Update `CHANGELOG.md` (`[Unreleased]` section) in the same PR** as the change it describes.

5. **Run the full test suite before every PR**:

   ```bash
   xcodebuild test -project SudoSodoku.xcodeproj -scheme SudoSodoku \
     -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
   ```

   New generator, rating, or storage logic needs matching unit tests in `SudoSodokuTests/`.

## 📋 Workflow

### 1. Branch

```bash
git checkout -b feature/your-feature-name   # or fix/, docs/, refactor/, test/
```

### 2. Commit — Conventional Commits

```
<type>: <subject>
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`. Examples from this repo's history:

```
feat: landing terminal boots in on launch
fix: solved records are immutable history
refactor: rename command-line branding to `sudo sudosodoku`
```

### 3. Pull Request

* Clear title and description; reference related issues (`Closes #N`)
* Screenshots or screen recordings for UI changes
* State how you tested (suite results, device/simulator)

## 🎨 Code & Design Style

### Swift

* Follow the [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/)
* MVVM: views render, `SudokuGame` owns game logic, managers own their domain (storage, rating, haptics, Game Center)
* All code comments and documentation in **English**; explain *why*, not *what*
* Prefer `let`, `guard` for early returns, small focused functions

### The Terminal Aesthetic (UI copy)

* Monospaced everywhere, `UPPER_SNAKE` labels (`SYSTEM_OVERVIEW:`, `NO_RECORDS_FOUND`)
* Shell-flavored strings (`cat /leaderboard`, `$ rm -rf /user_data`, `# awaiting command`)
* The navigation fiction is one accumulating command line (`root@ios:~$ sudo sudosodoku …`) — new screens should extend it, not break it

### Accessibility & Feel (non-negotiable)

* **Every animation must respect Reduce Motion** — provide an instant path
* Sounds are never forced on
* Haptics go through `HapticManager`'s semantic vocabulary — views express intent, never raw generators

### Data Integrity Invariants

* **A solved record is immutable history**: restarts/replays fork a new record; viewing never writes
* Persistence goes through `StorageManager` (single JSON file, atomic writes); new fields need decode defaults so old saves keep loading (see `GameRecord.init(from:)`)
* Statistics derive from emitted values, not singleton read-backs (`@Published` emits on *willSet*)

## 🐛 Reporting Bugs

Use the issue templates. Include: description, steps to reproduce, expected vs. actual, iOS version, device/simulator, app version, and screenshots where useful.

## 💡 Suggesting Features

Explain the use case and how it fits the philosophy. Features are evaluated on user value, alignment with the terminal fantasy, complexity, and maintenance burden — subtraction wins ties.

## ❓ Getting Help

* **GitHub Issues** for bugs and feature requests
* **GitHub Discussions** for questions
* Check code comments — invariants are documented where they live

## 📜 License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

**Thank you for contributing to SudoSodoku!** 🎉
