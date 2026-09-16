# Security Policy

## Security Model

AI Credit Tracker is designed with a **100% local-first, zero-telemetry** security model.

### What we guarantee:

| Principle | Details |
|-----------|---------|
| **Zero telemetry** | No analytics, metrics, crash reporting, or usage tracking of any kind. |
| **Zero third-party servers** | The app never communicates with any server other than Google's official API endpoints (`*.googleapis.com`). |
| **Local-only credential storage** | All OAuth tokens and credentials are stored exclusively in your OS-protected user directories. |
| **Read-only operation** | The app only reads quota information from Google's API. It never creates, modifies, or deletes any data on any service. |
| **No credential sharing** | Your credentials are never transmitted to any developer, contributor, or third party. |

### Network traffic

The **only** network connections made by this application are:

1. **`daily-cloudcode-pa.googleapis.com`** — Primary quota API endpoint (Google-owned)
2. **`cloudcode-pa.googleapis.com`** — Fallback quota API endpoint (Google-owned)
3. **`oauth2.googleapis.com`** — Token refresh endpoint (Google-owned)
4. **`accounts.google.com`** — OAuth sign-in flow (Google-owned, only during "Add Account")

No other network connections are made. Ever.

### Credential storage locations

| Platform | Directory |
|----------|-----------|
| macOS | `~/Library/Application Support/QuotaBar/` |
| macOS (Antigravity) | `~/.gemini/jetski-standalone-oauth-token` |
| Windows | `%APPDATA%\QuotaBar\` |
| Linux | `$XDG_CONFIG_HOME/QuotaBar/` or `~/.config/QuotaBar/` |

All directories use the operating system's standard user-level file permissions. Credentials are accessible only to your user account.

## Supported Versions

| Version | Supported |
|---------|-----------|
| v1.x (current) | ✅ Yes |
| < v1.0 | ❌ No |

## Reporting a Vulnerability

If you discover a security vulnerability, please report it responsibly:

1. **Do NOT open a public GitHub issue** for security vulnerabilities.
2. **Email**: Send a detailed report to the repository owner via the email listed in their GitHub profile.
3. **Include**: A clear description of the vulnerability, steps to reproduce, and potential impact.
4. **Response time**: We will acknowledge receipt within 48 hours and aim to provide a fix within 7 days for critical issues.

## OAuth Client Credentials

The engine script includes a hardcoded OAuth client ID and secret. These are the **publicly-known credentials from the official Antigravity CLI** (already published in the CLI's own source code and dozens of open-source projects). They are not private secrets.

If you prefer to use your own OAuth credentials, set these environment variables:

```bash
export ANTIGRAVITY_OAUTH_CLIENT_ID="your-client-id"
export ANTIGRAVITY_OAUTH_CLIENT_SECRET="your-client-secret"
```
