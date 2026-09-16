# AI Credit Tracker

> Track your Google AI Pro credits across multiple accounts from your macOS menu bar.
>
> *Never run out of AI credits again.*

<!-- Badges -->
[![Download](https://img.shields.io/github/v/release/KhaledTheDeveloper/ai-credit-tracker?label=download&color=blue)](https://github.com/KhaledTheDeveloper/ai-credit-tracker/releases/latest)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform: macOS](https://img.shields.io/badge/Platform-macOS%2013%2B-black?logo=apple)](https://www.apple.com/macos/)
[![Swift 5.9+](https://img.shields.io/badge/Swift-5.9%2B-orange?logo=swift)](https://swift.org)
[![Node.js 18+](https://img.shields.io/badge/Node.js-18%2B-green?logo=node.js)](https://nodejs.org)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)

> **Disclaimer**: AI Credit Tracker is an independent, community-driven open-source project. It is **NOT** affiliated with, sponsored by, or endorsed by Google LLC, Alphabet Inc., or Anthropic PBC. "Google", "Gmail", "Gemini", and related marks are registered trademarks of Google LLC. "Claude" is a registered trademark of Anthropic PBC. See [DISCLAIMER.md](DISCLAIMER.md) for full details.

---

## What Is This?

AI Credit Tracker is a **native macOS menu bar app** that monitors your Google AI Pro subscription quotas in real time. If you have one or more Google accounts with AI Pro, this app shows you exactly how much credit you have left — across both **Gemini Models** and **Claude & GPT Models** — without needing to open any IDE or browser.

<p align="center">
  <img src="assets/menu-bar-overview.png" alt="AI Credit Tracker Menu Bar" width="280" />
  &nbsp;&nbsp;
  <img src="assets/add-account.png" alt="Add Account Flow" width="280" />
  &nbsp;&nbsp;
  <img src="assets/settings.png" alt="Settings" width="280" />
</p>

### Why?

- Google AI Pro subscriptions have **two independent quota pools**: Gemini Models and Claude & GPT Models.
- Each pool has a **5-hour rolling window** and a **weekly cap**.
- When the weekly cap hits 0%, the 5-hour window is suspended until the weekly resets.
- If you use multiple Google accounts, there is no easy way to see which account has credits available **right now**.

AI Credit Tracker solves this by showing all your accounts at a glance, sorted by who has the most headroom.

---

## Features

- 🔄 **Real-time quota monitoring** — Live percentages and countdown timers for both 5-hour and weekly windows
- 👥 **Multi-account support** — Track unlimited Google accounts simultaneously
- 🏆 **Smart ranking** — Accounts are automatically sorted by available credits (most headroom first)
- 🃏 **Compact accordion cards** — Expandable `#1`, `#2`, `#3` cards with quick-glance quota capsules
- 🔔 **Notifications** — Get alerted when credits drop below your threshold or reset
- 🔒 **100% local & private** — Zero telemetry, zero analytics, zero third-party servers. See [SECURITY.md](SECURITY.md)
- 🌐 **Cross-platform engine** — The Node.js engine works on macOS, Windows, and Linux (native UI is macOS-only for now)

---

## Requirements

| Requirement | Version |
|-------------|---------|
| macOS | 13 (Ventura) or later |
| Swift | 5.9+ (included with Xcode 15+) |
| Node.js | 18+ |
| Google Account | With [Google AI Pro](https://ai.google.dev/) subscription |

## Installation

### Option A — Download the App (Recommended)

1. **Download** the latest `.zip` from the [Releases page](https://github.com/KhaledTheDeveloper/ai-credit-tracker/releases/latest)
2. **Unzip** — double-click the downloaded file. You'll see `AI Credit Tracker.app`
3. **Drag** `AI Credit Tracker.app` into your `/Applications` folder
4. **First launch** — since this app is not signed with an Apple Developer certificate, macOS will show a security warning:

   > ⚠️ **"AI Credit Tracker" can't be opened because Apple cannot check it for malicious software.**

   **To bypass this (required on first launch only):**
   - **Method 1:** Right-click (or Control-click) the app → click **"Open"** → click **"Open"** again in the dialog
   - **Method 2:** Go to **System Settings → Privacy & Security** → scroll down to find the blocked app → click **"Open Anyway"**

   After the first launch, macOS will remember your choice and the app will open normally from then on.

5. The app appears as a ⚡ icon in your **menu bar** (top-right of your screen). Click it to see your credit cards.

> **Note:** This app requires [Node.js 18+](https://nodejs.org) to be installed on your system for the quota-fetching engine.

### Option B — Build from Source

If you prefer to compile it yourself (requires Xcode 15+ and Swift 5.9+):

```bash
# Clone the repository
git clone https://github.com/KhaledTheDeveloper/ai-credit-tracker.git
cd ai-credit-tracker

# Build the .app bundle
./scripts/build-app.sh

# Launch it
open "dist/AI Credit Tracker.app"
```

Or build and run directly from the terminal:

```bash
swift build
.build/debug/QuotaBar &
```

### Adding Your Google Accounts

The app discovers accounts from your local Gemini CLI / Antigravity IDE session automatically. To add additional accounts:

**Browser OAuth (recommended):**

Click the **`+`** button in the menu bar → **"+ Add Account (Browser)"** → sign in with your Google account.

**If you already use Gemini CLI or Antigravity IDE:**

Accounts logged into Gemini CLI or Antigravity IDE are automatically discovered. No extra setup needed.

---

## How It Works

```
┌─────────────────────────────────────────────────┐
│              macOS Menu Bar UI                   │
│         (SwiftUI · Sources/QuotaBar)             │
│                                                  │
│  #1 user@gmail.com          Claude: 45%  ▸       │
│  #2 work@gmail.com          Claude: 0%   ▸       │
│  #3 alt@gmail.com           Claude: 0%   ▸       │
└──────────────────────┬──────────────────────────┘
                       │ JSON over stdout
┌──────────────────────▼──────────────────────────┐
│           Engine Bridge (Node.js)                │
│            (engine/index.js)                     │
│                                                  │
│  • Discovers local OAuth tokens automatically    │
│  • Refreshes expired tokens via Google OAuth     │
│  • Queries Google quota API                      │
│  • Returns standardized JSON array               │
└──────────────────────┬──────────────────────────┘
                       │ HTTPS (user's own credentials)
┌──────────────────────▼──────────────────────────┐
│        Google Cloud Code API                     │
│  googleapis.com/v1internal:retrieveUserQuota...  │
└─────────────────────────────────────────────────┘
```

See [ARCHITECTURE.md](ARCHITECTURE.md) for the full technical deep-dive, including the engine JSON contract and cross-platform token discovery paths.

---

## Configuration

Click **"Settings…"** in the menu bar footer to configure:

| Setting | Default | Description |
|---------|---------|-------------|
| Refresh Interval | 15 minutes | How often to poll for updated quotas |
| Primary Pool | Claude and GPT models | Which pool drives ranking and notifications |
| Sort Order | Soonest Reset | How accounts are ranked (`Soonest Reset`, `Most Remaining`, `Alphabetical`) |
| Alert Threshold | 10% | Notify when credits drop below this percentage |
| Launch at Login | Off | Start AI Credit Tracker when you log in |

---

## Contributing

We welcome contributions! Whether you're fixing bugs, improving documentation, or building the **Windows or Linux version**, check out [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Wanted: Windows & Linux Contributors! 🖥️🐧

The Node.js engine (`engine/index.js`) already works cross-platform. We need help building native system tray UIs for:

- **Windows** — WinUI 3, WPF (.NET 8), or Tauri
- **Linux** — AppIndicator, GTK, or Tauri

See [ARCHITECTURE.md](ARCHITECTURE.md) for the engine JSON contract and integration blueprint.

---

## Security & Privacy

- **Zero telemetry** — No data is ever sent to any server besides Google's own API endpoints.
- **Zero analytics** — No tracking, no metrics collection, no crash reporting.
- **Local-only storage** — Credentials are stored in your OS-protected user directories.
- **Read-only** — This tool only *reads* quota information. It never modifies anything.

See [SECURITY.md](SECURITY.md) for the full security model and vulnerability disclosure policy.

---

## FAQ

**Q: Do I need Antigravity or Gemini CLI installed?**
No. You can add accounts directly through the app's browser-based OAuth flow. Antigravity/Gemini CLI accounts are auto-discovered as a convenience, but they are not required.

**Q: Is this an official Google product?**
No. This is an independent open-source project. See [DISCLAIMER.md](DISCLAIMER.md).

**Q: What happens if Google changes or blocks the API?**
The tool uses an internal Google API endpoint that could change at any time. If that happens, we'll update the engine. See the [API Notice in DISCLAIMER.md](DISCLAIMER.md) for details.

**Q: Can I use my own OAuth client ID?**
Yes. Set the `ANTIGRAVITY_OAUTH_CLIENT_ID` and `ANTIGRAVITY_OAUTH_CLIENT_SECRET` environment variables before running.

**Q: Does this work on Windows or Linux?**
The engine (`node engine/index.js`) works on all platforms. The menu bar UI is macOS-only for now. We're looking for contributors to build Windows and Linux UIs — see [CONTRIBUTING.md](CONTRIBUTING.md).

---

## License

[MIT](LICENSE) © Khaled Mahmud
