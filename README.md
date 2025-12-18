# **SudoSodoku**

A terminal-style Sudoku experience for iOS, designed for logical purists.

**SudoSodoku** is a minimalist, keyboard-centric (conceptually) puzzle game that brings the Linux terminal aesthetic to your iPhone. It features a robust puzzle generator, an ELO rating system, and a "Juice" interaction model with haptic feedback.

## **✨ Features**

* **Terminal Aesthetic**: Green phosphor look on deep dark background (\#0D121A).  
* **Infinite Puzzles**: Real-time Sudoku generator with unique solutions.  
* **ELO Rating System**:  
  * **Dynamic Difficulty**: Easy, Medium, Hard, Master.  
  * **Ranking Titles**: From SCRIPT\_KIDDIE to THE\_ARCHITECT.  
  * **Anti-Smurfing**: Intelligent score calculation.  
* **Advanced Tools**:  
  * **Pencil Mode**: For candidate notes.  
  * **Undo/Redo Stack**: Fearless experimentation.  
  * **Archives**: Save unfinished games automatically; Favorite your best runs.  
* **Native Integration**:  
  * **Game Center**: Seamless login and user profile.  
  * **iCloud Sync**: (Optional) Cross-device save data synchronization.  
  * **Haptics**: Satisfying mechanical feedback.

## **🛠️ Architecture**

* **Language**: Swift 5  
* **UI Framework**: SwiftUI  
* **Data Flow**: ObservableObject \+ Combine  
* **Persistence**: Codable \-\> JSON (Local/iCloud Documents)  
* **Algorithm**: Backtracking solver & Human-like difficulty evaluator.

## **🚀 Building the Project**

1. Clone the repository:  
   git clone [https://github.com/kaiiiichen/SudoSodoku.git](https://github.com/kaiiiichen/SudoSodoku.git)

2. Open SudokuMVP.xcodeproj in Xcode 15+.  
3. Change the **Bundle Identifier** and **Team** in "Signing & Capabilities" to your own Apple Developer account.  
   * *Note: iCloud capabilities require a paid developer account. If you are on a free account, the app will automatically fallback to local storage.*  
4. Build and run on your iPhone or Simulator (Cmd \+ R).

## **🤝 Contributing**

Contributions are welcome\! Please feel free to submit a Pull Request.

1. Fork the Project  
2. Create your Feature Branch (git checkout \-b feature/AmazingFeature)  
3. Commit your Changes (git commit \-m 'Add some AmazingFeature')  
4. Push to the Branch (git push origin feature/AmazingFeature)  
5. Open a Pull Request

## **📄 License**

Distributed under the MIT License. See LICENSE for more information.

*Created with logic and ❤️.*
