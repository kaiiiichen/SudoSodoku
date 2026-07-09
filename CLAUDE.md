# CLAUDE.md — Agent Guidelines for SudoSodoku

## Git Workflow (IMPORTANT)

- **Never commit directly to `main`.** All changes go through a feature branch
  and a pull request, no exceptions — including docs-only and config-only changes.
- Branch naming: `feature/<name>`, `fix/<name>`, `docs/<name>` (see CONTRIBUTING.md).
- Commit messages follow Conventional Commits (`feat:`, `fix:`, `test:`, `docs:`, `refactor:`, `chore:`).
- Update `CHANGELOG.md` (`[Unreleased]` section) in the same PR as the change.
- Work items are tracked as GitHub issues; reference them in PRs (`Closes #N`).
  Kai mirrors GitHub issues into Linear — keep issue state accurate.
- **Assign every new issue to `kaiiiichen`** (sole owner; there is no other
  agent/boss account).
- **Every issue must carry at least one label.** Pick from the repo's existing
  labels (`bug`, `enhancement`, `feature`, `documentation`, `game-center`,
  `ux-*`, `release`, …); create a new label only when none fits.

## Project Facts

- iPhone-only iOS app (`TARGETED_DEVICE_FAMILY = 1`), iOS 17.0+, SwiftUI + MVVM,
  Swift 5.9. **No iPadOS or macOS work** — deferred indefinitely.
- `IPHONEOS_DEPLOYMENT_TARGET` must stay the literal `17.0` in project.pbxproj.
  Do not accept Xcode's "Update to recommended settings" suggestion that rewrites
  it to `$(RECOMMENDED_IPHONEOS_DEPLOYMENT_TARGET)` — Xcode Cloud resolves that
  macro to nothing and builds fail with iOS 16/17 availability errors.
- Bundle ID `dev.kaichen.sudoku.app`; Game Center leaderboard IDs live in
  `SudoSodoku/Utils/AppConstants.swift`.
- Persistence is a single local JSON file managed by `StorageManager`
  (`save_data_v4.json`, atomic writes, legacy migration chain).
- `DEVLOG.md` is a local-only development journal (gitignored) — newest entry on
  top. Record significant decisions and completed work there; never commit it.

## Build & Test

- CLI builds need the full Xcode: `export DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer`
  (the local `xcode-select` points at Command Line Tools).
- Run tests before every PR:
  `xcodebuild test -project SudoSodoku.xcodeproj -scheme SudoSodoku -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`
- The `SudoSodoku` scheme is shared and runs `SudoSodokuTests` in its Test action
  (Xcode Cloud runs it too). Keep new logic covered: generator/rating/storage
  changes need matching unit tests.
- The project uses Xcode's synchronized folder groups — new files under
  `SudoSodoku/` or `SudoSodokuTests/` are picked up automatically; do not hand-edit
  `project.pbxproj` to register individual files.

## Code Style

- All code comments and documentation in English.
- Match the existing terminal aesthetic in UI copy (monospaced, `UPPER_SNAKE`
  labels, shell-flavored strings like `cat /stats`).
- Every animation must respect Reduce Motion; sounds are never forced on.
