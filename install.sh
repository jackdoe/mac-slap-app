#!/bin/bash
set -euo pipefail

APP="SlapMe"
SOURCE="$(cd "$(dirname "$0")" && pwd)/$APP.app"
TARGET="$([ -w /Applications ] && echo /Applications || echo "$HOME/Applications")"

[ -d "$SOURCE" ] || { echo "$APP.app is not next to this script." >&2; exit 1; }

pkill -x "$APP" || true
mkdir -p "$TARGET"
rm -rf "$TARGET/$APP.app"
ditto "$SOURCE" "$TARGET/$APP.app"
xattr -dr com.apple.quarantine "$TARGET/$APP.app"
open "$TARGET/$APP.app"

echo "$APP is running from $TARGET. Look for the hand in your menu bar."
