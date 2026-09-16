#!/bin/bash
set -euo pipefail

# ─────────────────────────────────────────────────────────────
# build-app.sh — Build AI Credit Tracker as a macOS .app bundle
# Usage: ./scripts/build-app.sh
# Output: dist/AI Credit Tracker.app  and  dist/AI-Credit-Tracker-vX.Y.Z-macOS.zip
# ─────────────────────────────────────────────────────────────

APP_NAME="AI Credit Tracker"
BUNDLE_ID="com.aicredittracker.app"
VERSION="${1:-1.0.0}"
EXECUTABLE="QuotaBar"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
DIST_DIR="$PROJECT_DIR/dist"
APP_DIR="$DIST_DIR/$APP_NAME.app"

echo "🔨 Building AI Credit Tracker v${VERSION}..."
echo ""

# ── Step 1: Build release binary ──────────────────────────────
echo "→ Step 1/5: Compiling Swift (release mode)..."
cd "$PROJECT_DIR"
swift build -c release 2>&1 | tail -3

BINARY="$PROJECT_DIR/.build/release/$EXECUTABLE"
if [ ! -f "$BINARY" ]; then
    echo "❌ Build failed — binary not found at $BINARY"
    exit 1
fi
echo "  ✅ Binary compiled successfully"

# ── Step 2: Create .app bundle structure ──────────────────────
echo "→ Step 2/5: Creating .app bundle..."
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources/engine"

# Copy binary
cp "$BINARY" "$APP_DIR/Contents/MacOS/$EXECUTABLE"

# Copy engine
cp "$PROJECT_DIR/engine/index.js" "$APP_DIR/Contents/Resources/engine/index.js"

echo "  ✅ Bundle structure created"

# ── Step 3: Create Info.plist ─────────────────────────────────
echo "→ Step 3/5: Writing Info.plist..."
cat > "$APP_DIR/Contents/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleDisplayName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleVersion</key>
    <string>${VERSION}</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundleExecutable</key>
    <string>${EXECUTABLE}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsArbitraryLoads</key>
        <true/>
    </dict>
</dict>
</plist>
PLIST
echo "  ✅ Info.plist written"

# ── Step 4: Create PkgInfo ────────────────────────────────────
echo "→ Step 4/6: Writing PkgInfo..."
echo -n "APPL????" > "$APP_DIR/Contents/PkgInfo"
echo "  ✅ PkgInfo written"

# ── Step 5: Ad-hoc code sign ──────────────────────────────────
echo "→ Step 5/6: Ad-hoc code signing..."
codesign --force --deep -s - "$APP_DIR"
echo "  ✅ App signed (ad-hoc)"

# ── Step 6: Package as .zip ───────────────────────────────────
echo "→ Step 6/6: Creating distributable .zip..."
ZIP_NAME="AI-Credit-Tracker-v${VERSION}-macOS.zip"
cd "$DIST_DIR"
rm -f "$ZIP_NAME"
ditto -c -k --keepParent "$APP_NAME.app" "$ZIP_NAME"
ZIP_SIZE=$(du -h "$ZIP_NAME" | cut -f1)
echo "  ✅ Created: dist/$ZIP_NAME ($ZIP_SIZE)"

echo ""
echo "════════════════════════════════════════════════════════"
echo "  ✅ Build complete!"
echo ""
echo "  App:  dist/$APP_NAME.app"
echo "  Zip:  dist/$ZIP_NAME"
echo ""
echo "  To test locally:"
echo "    open \"dist/$APP_NAME.app\""
echo ""
echo "  To upload to GitHub Releases:"
echo "    1. Go to github.com/KhaledTheDeveloper/ai-credit-tracker/releases/new"
echo "    2. Tag: v${VERSION}"
echo "    3. Drag dist/$ZIP_NAME into the upload area"
echo "    4. Publish release"
echo "════════════════════════════════════════════════════════"
