#!/bin/bash
# Renders SwiftUI view screenshots via ImageRenderer and saves to Screenshots/.
# Usage: bash scripts/capture-screenshots.sh
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCHEME="TeslaCare"
DESTINATION="platform=iOS Simulator,name=iPhone 17e"

# Point xcodebuild at the full Xcode app, not just CommandLineTools.
# Match "Xcode.app" or "Xcode <version>.app" but NOT "Xcodes.app".
XCODE_APP="$(find /Applications -maxdepth 1 -name 'Xcode.app' -o -name 'Xcode [0-9]*.app' | sort | tail -1)"
export DEVELOPER_DIR="$XCODE_APP/Contents/Developer"

echo "Building and running screenshot tests..."
xcodebuild test \
  -scheme "$SCHEME" \
  -destination "$DESTINATION" \
  -only-testing:TeslaCareTests/ScreenshotTests \
  -project "$REPO_ROOT/TeslaCare.xcodeproj" \
  2>&1 | grep -E "✓|FAILED|error:|warning: |Saved|Test.*passed|Test.*failed" || true

echo ""
echo "Screenshots saved to $REPO_ROOT/Screenshots/"
ls "$REPO_ROOT/Screenshots/"
