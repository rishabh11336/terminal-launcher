#!/usr/bin/env bash
set -euo pipefail

FLUTTER="/Users/rishabhsingh/Developer/flutter/bin/flutter"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RELEASES_DIR="$SCRIPT_DIR/releases"
APK_SRC="$SCRIPT_DIR/build/app/outputs/flutter-apk/app-release.apk"
PUBSPEC="$SCRIPT_DIR/pubspec.yaml"

# Read current version e.g. "1.0.0+3"
CURRENT=$(grep '^version:' "$PUBSPEC" | awk '{print $2}')
SEMVER="${CURRENT%%+*}"   # e.g. "1.0.0"
BUILD="${CURRENT##*+}"    # e.g. "3"

# Bump build number
NEW_BUILD=$((BUILD + 1))
NEW_VERSION="${SEMVER}+${NEW_BUILD}"

# Write back to pubspec.yaml
sed -i '' "s/^version: .*/version: ${NEW_VERSION}/" "$PUBSPEC"

echo "==> Building Terminal Launcher v${NEW_VERSION} (arm64 release)"
"$FLUTTER" build apk --release --target-platform android-arm64

mkdir -p "$RELEASES_DIR"
DEST="$RELEASES_DIR/terminal_launcher_v${NEW_VERSION}.apk"
cp "$APK_SRC" "$DEST"

echo ""
echo "==> APK copied to: $DEST"
echo "==> Size: $(du -sh "$DEST" | cut -f1)"
echo ""
echo "Install:"
echo "  adb install \"$DEST\""
