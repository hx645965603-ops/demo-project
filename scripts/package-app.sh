#!/bin/bash
# Builds a local 今日待办.app with SwiftPM. Full Xcode is not required.
# The ad-hoc signature is not notarized. The App Sandbox entitlement is omitted
# here because ad-hoc signed sandboxed apps are rejected by macOS; the Xcode
# project still enables the sandbox for a development-signed run.
set -euo pipefail
cd "$(dirname "$0")/.."

swift build -c release --product TodayTodo

APP="dist/今日待办.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

cp ".build/release/TodayTodo" "$APP/Contents/MacOS/今日待办"
chmod +x "$APP/Contents/MacOS/今日待办"

sed \
  -e 's/$(EXECUTABLE_NAME)/今日待办/g' \
  -e 's/$(PRODUCT_BUNDLE_IDENTIFIER)/com.hx645965603.TodayTodo/g' \
  Config/Info.plist > "$APP/Contents/Info.plist"

# Ad-hoc signature so the bundle can launch on this Mac. Not notarized.
codesign --force --sign - --timestamp=none "$APP"

echo "Built $APP"
codesign -dv --verbose=2 "$APP" 2>&1 | sed -n '1,20p'
