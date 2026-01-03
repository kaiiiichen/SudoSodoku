# **SudoSodoku**

**A terminal-style Sudoku experience for iOS, designed for logical purists.**

**SudoSodoku** is a minimalist, keyboard-centric (conceptually) puzzle game that brings the Linux terminal aesthetic to your iPhone. It strips away the distractions of modern casual games, offering a raw, focus-driven environment powered by a robust algorithmic core.

### **🎉 v1.0.0 - First Official Release**

We are thrilled to announce the first stable release of SudoSodoku! This version represents a complete, polished game with all core features implemented and tested.

**Key Features:**

* **Procedural Puzzle Generation**: Real-time generation of unique, solvable puzzles
* **Four Difficulty Levels**: Easy, Medium, Hard, and Master with intelligent scoring
* **Pencil Mode**: Toggle candidate notes for complex deduction strategies
* **Undo/Redo System**: Full history stack for fearless experimentation
* **Smart Archives**: Automatic saving with favorites and replay functionality
* **ELO Rating System**: Competitive ranking from SCRIPT_KIDDIE to THE_ARCHITECT
* **Terminal Aesthetic**: Authentic green phosphor UI with haptic feedback
* **Modular Architecture**: Clean, maintainable codebase organized by feature

## **✨ Features**

### **🖥️ Immersive Terminal Aesthetic**

* **Visuals**: Authentic Green Phosphor (#00FF00) on Deep Dark Background (#0D121A).  
* **Feedback**: "Juice" interaction model with UIImpactFeedbackGenerator providing mechanical-keyboard-like haptics for every input.  
* **Animations**: Matrix-style victory effects and CRT-like glow pulses.

### **♾️ Infinite Procedural Generation**

* **Real-time Engine**: Generates unique, solvable puzzles on-the-fly using a randomized **Backtracking Algorithm**.  
* **Human-like Grading**: Difficulty is not determined by random holes, but by a **Logical Solver** that simulates human techniques (Naked Singles, Hidden Singles, etc.) to assign a precise difficulty score (0-100).

### **🏆 Competitive ELO System**

* **Dynamic Rating**: Starts at 1200 (USER). Beats puzzles to rank up.  
* **Adaptive K-Factor**: Rating changes stabilize as you reach higher tiers (Master/Grandmaster).  
* **Anti-Smurfing**: High-level players gain zero rating from solving low-level puzzles.  
* **Rank Titles**:  
  * < 1200: SCRIPT_KIDDIE  
  * 1200 - 1400: USER  
  * 1400 - 1600: SUDOER
  * 1600 - 1800: SYS_ADMIN
  * 1800 - 2000: KERNEL_HACKER
  * 2000+: THE_ARCHITECT

### **💾 Robust Persistence**

* **Game Center Integration**: Seamless, password-less login and user profile management.  
* **Cloud Sync**: Leveraging **iCloud Documents** to sync game states and archives across devices (automatically degrades to local storage if iCloud is unavailable).  
* **JSON Serialization**: All game records are stored as Codable JSON structs, ensuring backward compatibility and easy migration.

## **🛠️ Technical Architecture**

SudoSodoku is built with modern iOS technologies, designed for maintainability and performance:

* **Language**: Swift 5.9  
* **UI Framework**: SwiftUI (Apple's modern declarative UI framework)  
* **Architecture**: MVVM (Model-View-ViewModel) pattern for clean code organization  
* **State Management**: Reactive updates using Combine framework  
* **Data Persistence**:  
  * Automatic cloud sync via iCloud (with local fallback)  
  * Safe file operations with atomic writes  
  * Backward-compatible data migration  
* **User Experience**: Custom animations and haptic feedback for a polished feel

### **Directory Structure**

```
SudoSodoku/
├── Models/
│   ├── GameRecord.swift          # Codable save data structure
│   ├── SudokuCell.swift          # Unit cell model
│   ├── MoveHistory.swift         # Move history for undo/redo
│   └── Difficulty.swift          # Enum with rating ranges
├── ViewModels/
│   └── SudokuGame.swift          # Core game logic & state machine
├── Managers/
│   ├── GameCenterManager.swift   # GameKit authentication
│   ├── RatingManager.swift       # ELO calculation algorithms
│   ├── HapticManager.swift      # Haptic feedback engine
│   └── StorageManager.swift      # File I/O & Cloud syncing
├── Views/
│   ├── ContentView.swift         # Main entry & NavigationStack
│   ├── LandingView.swift         # Landing page
│   ├── GameView.swift            # The game board
│   ├── UserProfileView.swift     # User profile & statistics
│   ├── ArchiveView.swift         # History & Favorites list
│   ├── ModeSelectionView.swift   # Difficulty selection
│   ├── BoardView.swift           # Sudoku board rendering
│   ├── ControlPanelView.swift    # Game controls (undo/redo/numpad)
│   ├── Components/
│   │   ├── TerminalBackground.swift    # Terminal-style background
│   │   ├── MatrixVictoryOverlay.swift  # Victory animation
│   │   ├── NoteGridView.swift          # Note display grid
│   │   ├── GridLinesOverlay.swift      # Board grid lines
│   │   ├── StatCard.swift              # Statistics card component
│   │   ├── RankRow.swift               # Rank display row
│   │   └── RecordRow.swift             # Archive record row
│   └── Styles/
│       └── BouncyButtonStyle.swift     # Button animation style
└── Algorithms/
    └── SudokuGenerator.swift     # Backtracking & Digging logic
```

## **🚀 Building the Project**

### **Method 1: Using Xcode (Traditional)**

1. **Clone the repository**:  

  ```bash
  git clone https://github.com/kaiiiichen/SudoSodoku.git
  ```

1. **Open in Xcode**:  
   Double-click `SudoSodoku.xcodeproj`. Ensure you have Xcode 15.0+ installed.

2. **Configure Signing**:  
   * Go to the Project Navigator (blue icon).  
   * Select the SudoSodoku target.  
   * Click **Signing & Capabilities**.  
   * Change the **Team** to your own Apple Developer account.  
   * *Note: If you are on a Free Developer Account, iCloud capabilities will be disabled. The app will automatically fallback to local storage.*

3. **Run**:  
   Connect your iPhone or select a Simulator and press `Cmd + R`.

### **Method 2: Using Command Line (Cursor/VS Code)**

We provide convenient build scripts for command-line development:

#### **Build Scripts**

* **`build.sh`** - Build the project (similar to Xcode's Cmd+B)

  ```bash
  ./build.sh          # Debug build (default)
  ./build.sh release  # Release build
  ./build.sh clean    # Clean build artifacts
  ```

* **`play.sh`** - Build and run in iOS Simulator

  ```bash
  ./play.sh
  ```

  This script will:
  1. Find an available iPhone simulator
  2. Boot the simulator
  3. Build the project
  4. Install and launch the app

* **`run.sh`** - Alternative run script with more detailed output

  ```bash
  ./run.sh
  ```

#### **Using Keyboard Shortcuts in Cursor**

1. Press `Cmd+Shift+B` (macOS) to trigger the default build task
2. Use `Cmd+Shift+P` → "Tasks: Run Task" to access all build tasks

### **Build Requirements**

* macOS 13.0+ (for iOS development)
* Xcode 15.0+ with Command Line Tools
* iOS 17.0+ deployment target

## **📱 Running in Simulator**

After building, you can run the app in the iOS Simulator:

```bash
# Quick way: Use the play script
./play.sh

# Or manually:
# 1. Build first
./build.sh

# 2. Open Simulator
open -a Simulator

# 3. Install and run (see play.sh for details)
```

## **🤝 Contributing**

Contributions are welcome! We appreciate your help in making SudoSodoku better.

**Getting Started:**

1. Read our [Contributing Guidelines](CONTRIBUTING.md)
2. Check our [Code of Conduct](CODE_OF_CONDUCT.md)
3. Look for issues labeled `good first issue`
4. Fork, make changes, and submit a Pull Request

**Quick Start:**

```bash
git checkout -b feature/AmazingFeature
git commit -m "feat: Add some AmazingFeature"
git push origin feature/AmazingFeature
```

Then open a Pull Request. See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

### **Code Style Guidelines**

* All code comments and documentation should be in English
* Follow Swift naming conventions
* Maintain MVVM architecture pattern
* Add appropriate MARK comments for code organization

## **📚 Additional Documentation**

* **[CHANGELOG.md](CHANGELOG.md)** - Version history and release notes
* **[DEVELOPER.md](DEVELOPER.md)** - Feature roadmap, testing checklist, and development guidelines
* **[CONTRIBUTING.md](CONTRIBUTING.md)** - Guidelines for contributing to the project
* **[CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md)** - Community code of conduct
* **[SECURITY.md](.github/SECURITY.md)** - Security policy and vulnerability reporting

## **📄 License**

Distributed under the MIT License. See [LICENSE](.github/LICENSE) for more information.

*Created with logic and ❤️ by Kai Chen.*
