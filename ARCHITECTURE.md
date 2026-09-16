# Architecture

This document describes the technical architecture of AI Credit Tracker, with a focus on the **engine JSON contract** — the interface between the cross-platform Node.js engine and platform-specific native UIs.

## System Overview

```
┌─────────────────────────────────────────────────────┐
│                    UI Layer                          │
│                                                     │
│  macOS: SwiftUI MenuBarExtra (Sources/QuotaBar)     │
│  Windows: [Your contribution here]                   │
│  Linux: [Your contribution here]                     │
└───────────────────────┬─────────────────────────────┘
                        │ Subprocess: node engine/index.js
                        │ Communication: JSON over stdout
┌───────────────────────▼─────────────────────────────┐
│               Engine (engine/index.js)               │
│                                                     │
│  1. Discover OAuth tokens from local filesystem      │
│  2. Refresh expired access tokens via Google OAuth   │
│  3. Query Google quota API for each account          │
│  4. Emit standardized JSON array to stdout           │
└───────────────────────┬─────────────────────────────┘
                        │ HTTPS (user's own credentials)
┌───────────────────────▼─────────────────────────────┐
│           Google Cloud Code API                      │
│  daily-cloudcode-pa.googleapis.com                   │
│  POST /v1internal:retrieveUserQuotaSummary           │
└─────────────────────────────────────────────────────┘
```

## Engine JSON Contract

When you run `node engine/index.js`, it outputs a JSON array to stdout. This is the **universal interface** that all platform UIs consume.

### Output Schema

```json
[
  {
    "email": "user@gmail.com",
    "pools": [
      {
        "displayName": "Gemini Models",
        "buckets": [
          {
            "remainingFraction": 0.89,
            "resetTime": "2026-09-23T07:23:03Z",
            "window": "weekly"
          },
          {
            "remainingFraction": 0.91,
            "resetTime": "2026-09-16T17:23:03Z",
            "window": "5h"
          }
        ]
      },
      {
        "displayName": "Claude and GPT models",
        "buckets": [
          {
            "remainingFraction": 0.0,
            "resetTime": "2026-09-21T14:21:41Z",
            "window": "weekly"
          },
          {
            "remainingFraction": 1.0,
            "resetTime": "2026-09-16T17:21:25Z",
            "window": "5h"
          }
        ]
      }
    ],
    "fetchedAt": "2026-09-16T12:39:54.820Z",
    "isStale": false
  }
]
```

### Field Reference

| Field | Type | Description |
|-------|------|-------------|
| `email` | string | The Google account email address |
| `pools` | array | Array of quota pool objects |
| `pools[].displayName` | string | Pool name: `"Gemini Models"` or `"Claude and GPT models"` |
| `pools[].buckets` | array | Array of quota window objects |
| `pools[].buckets[].remainingFraction` | number | Remaining quota as a fraction (0.0 to 1.0). Multiply by 100 for percentage. |
| `pools[].buckets[].resetTime` | string | ISO 8601 UTC timestamp when this window resets |
| `pools[].buckets[].window` | string | Window type: `"weekly"` or `"5h"` |
| `fetchedAt` | string | ISO 8601 UTC timestamp of when the data was fetched |
| `isStale` | boolean | `true` if the fetch failed and this is cached/stale data |

### Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success (JSON array on stdout, may be empty `[]`) |
| 1 | Fatal error (error message on stderr) |

### No accounts found

When no accounts are discovered, the engine outputs `[]` and exits with code 0.

## Token Discovery

The engine discovers OAuth tokens from these locations, in order of priority:

### 1. Local Antigravity / Gemini CLI Session

| Platform | Path |
|----------|------|
| All | `~/.gemini/jetski-standalone-oauth-token` |

This is the active session token from the locally-running Antigravity IDE or Gemini CLI.

### 2. Antigravity-Usage Accounts

| Platform | Path |
|----------|------|
| macOS | `~/Library/Application Support/antigravity-usage/accounts/*/tokens.json` |
| Windows | `%APPDATA%\antigravity-usage\accounts\*\tokens.json` |
| Linux | `$XDG_CONFIG_HOME/antigravity-usage/accounts/*/tokens.json` |

### 3. AI Credit Tracker Accounts

| Platform | Path |
|----------|------|
| macOS | `~/Library/Application Support/QuotaBar/accounts/*/tokens.json` |
| Windows | `%APPDATA%\QuotaBar\accounts\*\tokens.json` |
| Linux | `$XDG_CONFIG_HOME/QuotaBar/accounts/*/tokens.json` |

### Token File Format

Each `tokens.json` file contains:

```json
{
  "email": "user@gmail.com",
  "accessToken": "ya29.a0...",
  "refreshToken": "1//0e..."
}
```

The engine also supports legacy formats with `access_token` / `refresh_token` (snake_case) and nested `{ "token": { ... } }` structures.

## Token Refresh

When an access token is expired (HTTP 401), the engine automatically:

1. Uses the refresh token to obtain a new access token via `https://oauth2.googleapis.com/token`.
2. Retries the quota API request with the fresh token.
3. Persists the new token back to the original `tokens.json` file.

## Sorting Logic

The macOS UI sorts accounts using the "Claude and GPT models" pool as the **primary pool**:

1. **Most weekly quota remaining** comes first.
2. **Tie-breaker (both exhausted)**: Soonest weekly reset wins.
3. **Tie-breaker (both active)**: Soonest 5-hour reset wins.
4. **Final tie-breaker**: Alphabetical by email.

## Building a Platform UI

To build a UI for Windows or Linux:

1. **Spawn** `node engine/index.js` as a subprocess.
2. **Capture** stdout and parse the JSON array.
3. **Render** account cards with:
   - Email address
   - Per-pool quota bars (remaining %) with color coding
   - Countdown timers to reset (computed from `resetTime`)
   - "Weekly supersedes 5h" indicator when weekly hits 0%
4. **Poll** by re-running the engine on a configurable interval (default: 15 minutes).
5. **Add account** by writing a `tokens.json` to the platform-appropriate directory.

See [CONTRIBUTING.md](CONTRIBUTING.md) for recommended tech stacks and how to get started.
