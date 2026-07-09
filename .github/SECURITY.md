# Security Policy

## Supported Versions

We actively support security updates for the following versions:

| Version | Supported          |
| ------- | ------------------ |
| 2.0.x   | :white_check_mark: |
| < 2.0   | :x:                |

## Reporting a Vulnerability

We take security vulnerabilities seriously. If you discover a security vulnerability, please follow these steps:

### 🔒 How to Report

**Please do NOT** report security vulnerabilities through public GitHub issues.

Instead, please report them via one of the following methods:

1. **GitHub Security Advisory**: Use GitHub's [private vulnerability reporting](https://github.com/kaiiiichen/SudoSodoku/security/advisories/new) (recommended)
2. **Direct Contact**: Contact the maintainer directly through GitHub

### 📋 What to Include

When reporting a security vulnerability, please include:

* **Description**: Clear description of the vulnerability
* **Impact**: Potential impact of the vulnerability
* **Steps to Reproduce**: Detailed steps to reproduce (if applicable)
* **Proof of Concept**: If possible, include a proof of concept
* **Suggested Fix**: If you have ideas for a fix
* **Affected Versions**: Which versions are affected

### ⏱️ Response Timeline

* **Initial Response**: Within 48 hours
* **Status Update**: Within 7 days
* **Fix Timeline**: Depends on severity, but we aim for:
  * **Critical**: 7 days
  * **High**: 30 days
  * **Medium**: 90 days
  * **Low**: Next release cycle

### 🛡️ Security Best Practices

#### For Users

We care about your security. Here's how you can stay safe:

* **Keep Updated**: Always use the latest version of the app
* **Official Sources Only**: Download only from the App Store or GitHub releases
* **Report Issues**: If you notice anything suspicious, please report it immediately
* **Review Permissions**: The app requests minimal permissions (Game Center, optional)

#### For Contributors

If you're contributing code:

* Review code before submitting
* Follow secure coding practices
* Never commit sensitive information (API keys, passwords, etc.)
* Keep dependencies updated
* Report security concerns through the proper channels

### 🔐 Security Considerations

#### Data Privacy

* **Local Storage**: All game data — history, rating, achievements — lives in a single local JSON file on device (`StorageManager`, atomic writes). Nothing is uploaded by the app itself
* **No Data Collection**: No analytics, no tracking, no accounts, no third-party SDKs
* **Game Center (optional)**: Signing in submits leaderboard scores (solve times, ELO) and achievement unlocks through Apple's Game Center, subject to Apple's privacy policy. The app is fully playable as a guest without it

#### Permissions

SudoSodoku requests minimal permissions:

* **Game Center**: For user authentication, leaderboards, and achievements (optional — never presented at launch)

#### Third-Party Dependencies

Current dependencies:

* **SwiftUI**: Apple framework
* **GameKit**: Apple framework
* **Combine**: Apple framework

We aim to minimize third-party dependencies and only use trusted, well-maintained libraries.

### 🚨 Known Security Issues

None at this time. All known security issues will be listed here once resolved.

### 📝 Security Updates

Security updates will be:

* Documented in CHANGELOG.md
* Released as patch versions (e.g., 2.0.1, 2.0.2)
* Communicated through GitHub releases
* Prioritized over feature development

### 🏆 Recognition

We deeply appreciate responsible disclosure of security vulnerabilities. Security researchers and contributors who help keep SudoSodoku secure will be:

* Credited in security advisories (with your permission)
* Acknowledged in release notes
* Listed in this document (if you wish)

### 📚 Additional Resources

* [OWASP Mobile Top 10](https://owasp.org/www-project-mobile-top-10/)
* [Apple Security Documentation](https://developer.apple.com/security/)
* [Swift Security Best Practices](https://swift.org/security/)

---

**Thank you for helping keep SudoSodoku secure!** 🔒
