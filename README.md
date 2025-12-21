# **SudoSodoku**

**A terminal-style Sudoku experience for iOS, designed for logical purists.**

**SudoSodoku** is a minimalist, keyboard-centric (conceptually) puzzle game that brings the Linux terminal aesthetic to your iPhone. It strips away the distractions of modern casual games, offering a raw, focus-driven environment powered by a robust algorithmic core.

### **🚀 What's New in v0.5.0 Beta**

We are thrilled to announce the first public beta release\! This version introduces the complete "Hacker" game loop:

* **New "Pencil Mode"**: Toggle candidate notes for complex deduction in Hard/Master difficulties.  
* **Undo/Redo Stack**: A robust history system allowing fearless experimentation.  
* **Smart Archives**: Automatically saves unfinished sessions; ability to "Favorite" and replay specific seeds.  
* **UI Polish**: Enhanced symmetry in the control panel and refined haptic feedback profiles.

## **✨ Features**

### **🖥️ Immersive Terminal Aesthetic**

* **Visuals**: Authentic Green Phosphor (\#00FF00) on Deep Dark Background (\#0D121A).  
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
  * \< 1200: SCRIPT\_KIDDIE  
  * 1200 \- 1400: USER  
  * ...  
  * 2000+: THE\_ARCHITECT

### **💾 Robust Persistence**

* **Game Center Integration**: Seamless, password-less login and user profile management.  
* **Cloud Sync**: Leveraging **iCloud Documents** to sync game states and archives across devices (automatically degrades to local storage if iCloud is unavailable).  
* **JSON Serialization**: All game records are stored as Codable JSON structs, ensuring backward compatibility and easy migration.

## **🛠️ Technical Architecture**

SudoSodoku is built with **pure SwiftUI**, following a strict **MVVM (Model-View-ViewModel)** pattern.

* **Language**: Swift 5.9  
* **UI Framework**: SwiftUI (Declarative UI)  
* **State Management**: ObservableObject \+ Combine pipelines for reactive UI updates.  
* **Persistence Layer**:  
  * Custom StorageManager handling atomic file writes.  
  * Automatic migration logic for schema updates (e.g., v3 \-\> v4 data migration).  
* **Input Handling**: Custom gesture recognizers to solve conflict issues between "Jelly" animations and selection logic.

## **🚀 Building the Project**

1. **Clone the repository**:  
  ```bash
  git clone https://github.com/kaiiiichen/SudoSodoku.git
  ```

2. Open in Xcode:  
   Double-click SudokuMVP.xcodeproj. Ensure you have Xcode 15.0+ installed.  
3. **Configure Signing**:  
   * Go to the Project Navigator (blue icon).  
   * Select the SudokuMVP target.  
   * Click **Signing & Capabilities**.  
   * Change the **Team** to your own Apple Developer account.  
   * *Note: If you are on a Free Developer Account, iCloud capabilities will be disabled. The app will automatically fallback to local storage.*  
4. Run:  
   Connect your iPhone or select a Simulator and press Cmd \+ R.

## **🤝 Contributing**

Contributions are welcome! Please feel free to submit a Pull Request.

```bash
git checkout -b feature/AmazingFeature
git commit -m "Add some AmazingFeature"
git push origin feature/AmazingFeature
```

Then open a Pull Request.

## **📄 License**

Distributed under the MIT License. See LICENSE for more information.

*Created with logic and ❤️ by \[Kai Chen].*
