# Account Switcher Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a "Switch Antigravity to this account" button on each account card so users can one-click switch Antigravity's active session when quota runs out.

**Architecture:** The engine gets a new `switch <email>` command that reads the target account's refresh token, refreshes it with full Antigravity scopes, and writes it to `~/.gemini/jetski-standalone-oauth-token`. The Swift UI adds a button to each expanded card that calls this engine command. The OAuth login flow gets expanded scopes so new logins are Antigravity-compatible.

**Tech Stack:** Node.js (engine), Swift/SwiftUI (app), Google OAuth2

**Spec:** [account-switching-feasibility.md](file:///Users/khaledmahmud/.gemini/antigravity/brain/d2e44a3c-a9ac-4434-8a9e-bc81cdf05895/account-switching-feasibility.md)

## Global Constraints

- macOS 13+ minimum
- Swift 5.9+ / Xcode 16+
- Node.js 18+
- CI runner: `macos-15`
- OAuth client ID: same as Antigravity CLI (hex-encoded in source)
- All 57 existing tests must continue to pass

---

### Task 1: Expand OAuth Scopes in Engine Login

**Files:**
- Modify: `engine/index.js:546` (scope string in `handleLogin`)

**Interfaces:**
- Consumes: nothing new
- Produces: tokens with Antigravity-compatible scopes for all new logins

- [ ] **Step 1: Update the OAuth scope string**

In `engine/index.js`, line 546 inside `handleLogin()`, change the scope to include Antigravity's required scopes.

- [ ] **Step 2: Verify syntax** — `node -c engine/index.js`

- [ ] **Step 3: Commit**

---

### Task 2: Add `switch` Engine Command + AccountSwitcher Service

**Files:**
- Modify: `engine/index.js` (add `switch` command handler in `main()`)
- Create: `Sources/QuotaBar/Services/AccountSwitcher.swift`

**Interfaces:**
- Consumes: refresh tokens from QuotaBar/antigravity-usage account dirs
- Produces: `AccountSwitcher.switchAccount(email:completion:)` — calls `node engine/index.js switch <email>`, returns `(Bool, String)` (success, message)

- [ ] **Step 1: Add `switch` command to engine** — reads target account's refresh token, refreshes it, writes jetski token file
- [ ] **Step 2: Verify engine syntax**
- [ ] **Step 3: Test the switch command manually**
- [ ] **Step 4: Create AccountSwitcher.swift** — Swift service that calls engine switch command
- [ ] **Step 5: Verify Swift builds**
- [ ] **Step 6: Commit**

---

### Task 3: Add "Switch Antigravity" Button to AccountCardView

**Files:**
- Modify: `Sources/QuotaBar/Views/AccountCardView.swift`

**Interfaces:**
- Consumes: `AccountSwitcher.switchAccount(email:completion:)`
- Produces: UI button in expanded card section with idle/switching/success/failed states

- [ ] **Step 1: Add SwitchStatus enum and @State property**
- [ ] **Step 2: Add switch button in expanded section**
- [ ] **Step 3: Verify Swift builds**
- [ ] **Step 4: Run all tests** — expect 57 pass
- [ ] **Step 5: Commit**

---

### Task 4: Rebuild, Push, and Update Release

**Files:**
- Modify: `README.md` (add v1.0.2 changelog entry)
- Build: `dist/AI-Credit-Tracker-v1.0.2-macOS.zip`

- [ ] **Step 1: Update README changelog**
- [ ] **Step 2: Push all commits**
- [ ] **Step 3: Rebuild .app**
- [ ] **Step 4: Create GitHub release v1.0.2**
