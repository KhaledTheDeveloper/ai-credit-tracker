# Contributing to AI Credit Tracker

Thank you for your interest in contributing! This project welcomes contributions from everyone, whether you're fixing a typo, adding a feature, or building the Windows or Linux version.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup (macOS)](#development-setup-macos)
- [Project Structure](#project-structure)
- [Making Changes](#making-changes)
- [Pull Request Process](#pull-request-process)
- [Contributing to Windows / Linux Ports](#contributing-to-windows--linux-ports)
- [Style Guidelines](#style-guidelines)

## Code of Conduct

This project follows the [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md). By participating, you agree to uphold a welcoming, respectful environment.

## Getting Started

1. **Fork** the repository on GitHub.
2. **Clone** your fork locally:
   ```bash
   git clone https://github.com/YOUR_USERNAME/ai-credit-tracker.git
   cd ai-credit-tracker
   ```
3. **Create a branch** for your changes:
   ```bash
   git checkout -b feat/your-feature-name
   ```

## Development Setup (macOS)

### Prerequisites

| Tool | Version | Install |
|------|---------|---------|
| Xcode | 15+ | [Mac App Store](https://apps.apple.com/us/app/xcode/id497799835) |
| Swift | 5.9+ | Included with Xcode |
| Node.js | 18+ | `brew install node` or [nodejs.org](https://nodejs.org) |

### Build & Test

```bash
# Build the app
swift build

# Run all tests (57 tests across 12 suites)
swift test

# Run the engine directly to verify quota fetching
node engine/index.js

# Launch the app
.build/debug/QuotaBar &
```

### Project Structure

```
ai-credit-tracker/
├── Sources/
│   ├── QuotaBar/                   # macOS SwiftUI app
│   │   ├── QuotaBarApp.swift       # App entry point
│   │   ├── Views/                  # SwiftUI views
│   │   │   ├── MenuBarContentView.swift
│   │   │   ├── AccountCardView.swift
│   │   │   ├── AccountsView.swift
│   │   │   ├── QuotaBarRow.swift
│   │   │   └── SettingsView.swift
│   │   └── Services/
│   │       └── AccountManager.swift
│   └── QuotaBarCore/               # Platform-independent business logic
│       ├── Models/                  # Data models (AccountUsage, QuotaPool, etc.)
│       ├── Services/                # EngineBridge, UsageFetcher, UsageCache, etc.
│       └── ViewModels/             # QuotaViewModel, SortingLogic, CountdownFormatter
├── Tests/
│   └── QuotaBarCoreTests/          # Unit & integration tests
├── engine/
│   └── index.js                    # Cross-platform Node.js engine
├── assets/                         # Screenshots and media
├── .github/
│   ├── workflows/ci.yml            # GitHub Actions CI
│   └── ISSUE_TEMPLATE/             # Issue templates
└── docs files (README, LICENSE, CONTRIBUTING, etc.)
```

## Making Changes

### For bug fixes and small improvements

1. Write or update tests in `Tests/QuotaBarCoreTests/`.
2. Make your changes.
3. Run `swift test` and ensure all tests pass.
4. Run `swift build` and ensure it compiles cleanly.
5. Commit with a descriptive message following [Conventional Commits](https://www.conventionalcommits.org/):
   ```
   fix: correct weekly reset countdown calculation
   feat: add haptic feedback on quota threshold alert
   docs: improve Windows setup instructions
   ```

### For new features

1. **Open an issue first** to discuss the feature and get feedback.
2. Follow the bug fix workflow above.
3. Add tests for new functionality.
4. Update documentation as needed.

## Pull Request Process

1. Ensure `swift test` passes with **zero failures**.
2. Ensure `swift build` completes with **exit code 0**.
3. Update `README.md` if your change affects user-facing behavior.
4. Fill out the PR template describing what changed and why.
5. Request a review from a maintainer.

## Contributing to Windows / Linux Ports

We're actively looking for contributors to build native system tray applications for **Windows** and **Linux**!

### How it works

The Node.js engine (`engine/index.js`) is the **universal backend**. It:
- Discovers OAuth tokens from platform-specific directories
- Refreshes expired tokens automatically
- Queries Google's quota API
- Outputs a standardized JSON array to stdout

Your job is to build a native **system tray UI** that:
1. Spawns `node engine/index.js` as a subprocess
2. Parses the JSON output
3. Displays account cards with quota bars and countdowns
4. Polls on a configurable interval

See [ARCHITECTURE.md](ARCHITECTURE.md) for the complete engine JSON contract and token discovery paths.

### Recommended tech stacks

| Platform | Recommended | Alternative |
|----------|-------------|-------------|
| Windows | C# WinUI 3 / WPF (.NET 8) | Tauri (Rust + HTML) |
| Linux | GTK4 + AppIndicator (Python or Rust) | Tauri (Rust + HTML) |

### Getting started with a port

1. Open an issue titled `[Platform Port] Windows` or `[Platform Port] Linux`.
2. Create your UI in a `windows/` or `linux/` subdirectory.
3. Add platform-specific setup instructions to the README.
4. The engine JSON contract is your API — see [ARCHITECTURE.md](ARCHITECTURE.md).

## Style Guidelines

### Swift

- Follow [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/).
- Use `SwiftFormat` defaults where possible.
- Keep files focused — if a file exceeds ~300 lines, consider splitting it.

### JavaScript (Engine)

- Use `const` / `let` (no `var`).
- Use `async` / `await` for asynchronous operations.
- No external npm dependencies — the engine uses only Node.js built-in modules.

### Commits

- Use [Conventional Commits](https://www.conventionalcommits.org/) format.
- Keep commits atomic — one logical change per commit.
