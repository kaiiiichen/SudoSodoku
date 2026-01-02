# Contributing to SudoSodoku

Thank you for your interest in contributing to SudoSodoku! This document provides guidelines and instructions for contributing to the project.

## 🎯 How to Contribute

We welcome contributions of all kinds:

* 🐛 **Bug Reports**: Help us identify and fix issues
* 💡 **Feature Requests**: Suggest new features or improvements
* 📝 **Documentation**: Improve documentation and code comments
* 🎨 **UI/UX Improvements**: Enhance the user interface
* ⚡ **Performance**: Optimize code and algorithms
* 🧪 **Testing**: Add tests or improve test coverage
* 🌍 **Localization**: Translate the app to other languages

## 🚀 Getting Started

### Prerequisites

* macOS 13.0+ (for iOS development)
* Xcode 15.0+ with Command Line Tools
* iOS 17.0+ deployment target
* Git

### Setting Up the Development Environment

1. **Fork the repository**

   ```bash
   # Fork on GitHub, then clone your fork
   git clone https://github.com/YOUR_USERNAME/SudoSodoku.git
   cd SudoSodoku
   ```

2. **Open in Xcode**

   ```bash
   open SudoSodoku.xcodeproj
   ```

3. **Configure Signing**
   * Select the SudoSodoku target
   * Go to Signing & Capabilities
   * Set your development team
   * Note: iCloud capabilities require a paid Apple Developer account

4. **Build and Run**

   ```bash
   # Using build script
   ./build.sh
   
   # Or in Xcode: Cmd+B to build, Cmd+R to run
   ```

## 📋 Development Workflow

### 1. Create a Branch

```bash
git checkout -b feature/your-feature-name
# or
git checkout -b fix/your-bug-fix
```

**Branch Naming Convention:**

* `feature/` - New features
* `fix/` - Bug fixes
* `docs/` - Documentation updates
* `refactor/` - Code refactoring
* `test/` - Test additions/updates

### 2. Make Your Changes

* Follow the existing code style
* Write clear, self-documenting code
* Add comments for complex logic (in English)
* Follow the MVVM architecture pattern
* Keep functions focused and small

### 3. Test Your Changes

* Test on iOS Simulator
* Test on physical device if possible
* Ensure no regressions
* Test edge cases

### 4. Commit Your Changes

```bash
git add .
git commit -m "feat: Add detailed statistics feature"
```

**Commit Message Format:**
Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**

* `feat`: New feature
* `fix`: Bug fix
* `docs`: Documentation
* `style`: Code style (formatting, etc.)
* `refactor`: Code refactoring
* `test`: Adding tests
* `chore`: Maintenance tasks

**Examples:**

```
feat(Statistics): Add completion time tracking
fix(GameView): Resolve cell selection animation issue
docs(README): Update build instructions
```

### 5. Push and Create Pull Request

```bash
git push origin feature/your-feature-name
```

Then create a Pull Request on GitHub with:

* Clear title and description
* Reference related issues
* Screenshots/GIFs for UI changes
* Testing notes

## 🎨 Code Style Guidelines

### Swift Style

* Follow [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/)
* Use meaningful variable and function names
* Keep functions under 50 lines when possible
* Use `guard` statements for early returns
* Prefer `let` over `var` when possible

### Architecture

* **MVVM Pattern**: Maintain separation of Models, Views, and ViewModels
* **Single Responsibility**: Each class/struct should have one clear purpose
* **Dependency Injection**: Use shared instances (like `StorageManager.shared`) appropriately
* **ObservableObject**: Use `@Published` properties for reactive updates

### File Organization

```
SudoSodoku/
├── Models/          # Data models
├── ViewModels/      # Business logic
├── Managers/        # System managers
├── Views/           # UI components
│   ├── Components/  # Reusable components
│   └── Styles/      # Custom styles
└── Algorithms/      # Core algorithms
```

### Comments

* All comments must be in **English**
* Use `// MARK:` comments to organize code sections
* Document complex algorithms
* Explain "why" not just "what"

### Example

```swift
// MARK: - Game Generation

/// Generates a new Sudoku puzzle for the specified difficulty level.
/// - Parameter difficulty: The target difficulty (Easy, Medium, Hard, Master)
/// - Returns: A tuple containing (puzzle, solution, difficultyScore)
func generateGame(for difficulty: Difficulty) {
    // Implementation
}
```

## 🐛 Reporting Bugs

### Before Submitting

1. Check if the bug has already been reported
2. Test on the latest version
3. Try to reproduce the issue

### Bug Report Template

When creating an issue, include:

* **Description**: Clear description of the bug
* **Steps to Reproduce**: Detailed steps to reproduce
* **Expected Behavior**: What should happen
* **Actual Behavior**: What actually happens
* **Screenshots**: If applicable
* **Environment**:
  * iOS version
  * Device/Simulator
  * App version
* **Additional Context**: Any other relevant information

## 💡 Suggesting Features

### Feature Request Template

* **Feature Description**: Clear description of the feature
* **Use Case**: Why is this feature needed?
* **Proposed Solution**: How should it work?
* **Alternatives**: Other solutions considered
* **Additional Context**: Screenshots, mockups, etc.

### Feature Evaluation

Features are evaluated based on:

* Alignment with project goals
* User value
* Implementation complexity
* Maintenance burden
* Open source compatibility

## 🔍 Code Review Process

1. **Automated Checks**: CI/CD will run basic checks
2. **Review**: Maintainers will review your PR
3. **Feedback**: Address any feedback or requested changes
4. **Approval**: Once approved, your PR will be merged

### Review Criteria

* Code quality and style
* Architecture adherence
* Test coverage
* Documentation
* Performance considerations

## 📝 Documentation

### Code Documentation

* Document public APIs
* Explain complex algorithms
* Add inline comments for non-obvious code
* Update README for user-facing changes

### Pull Request Documentation

* Describe what changed and why
* Include screenshots for UI changes
* Update CHANGELOG.md for user-visible changes
* Update DEVELOPER.md for architecture changes

## 🧪 Testing

### Manual Testing

* Test on iOS Simulator
* Test on physical device
* Test different iOS versions
* Test edge cases

### Test Checklist

* [ ] App builds without errors
* [ ] App runs without crashes
* [ ] New features work as expected
* [ ] Existing features still work
* [ ] No performance regressions
* [ ] UI looks correct on different screen sizes

## 🎯 Good First Issues

Look for issues labeled `good first issue` if you're new to the project. These are:

* Well-defined
* Small in scope
* Good learning opportunities
* Clearly documented

## ❓ Getting Help

* **GitHub Discussions**: For questions and discussions
* **GitHub Issues**: For bugs and feature requests
* **Code Comments**: Check code comments for implementation details

## 📜 License

By contributing, you agree that your contributions will be licensed under the MIT License.

## 🙏 Recognition

Contributors will be:

* Listed in CONTRIBUTORS.md (if we create one)
* Credited in release notes
* Acknowledged in the project

## 🚫 What Not to Contribute

* Features that add ads or paywalls
* Code that compromises user privacy
* Changes that break the open source nature
* Features that require closed-source dependencies
* Code that doesn't follow the project's architecture

---

**Thank you for contributing to SudoSodoku!** 🎉

Your contributions help make this project better for everyone. We appreciate your time and effort!
