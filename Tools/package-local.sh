#!/bin/zsh
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Vorssaint

# Fork-local packaging: bump the app's patch version (independent of the
# upstream project's numbering), commit the bump, rebuild the release bundle
# and package a DMG. CI keeps calling make-dmg.sh directly and pins the tag
# to the committed version, so this wrapper never runs there.

set -euo pipefail
cd "$(dirname "$0")/.."

PLIST="Resources/Info.plist"

CURRENT="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$PLIST")"
MAJOR="${CURRENT%%.*}"
REST="${CURRENT#*.}"
MINOR="${REST%%.*}"
PATCH="${REST#*.}"
[[ "$PATCH" == "$REST" ]] && PATCH=0
NEXT="$MAJOR.$MINOR.$((PATCH + 1))"

/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $NEXT" "$PLIST"
git add "$PLIST"
git commit -m "chore(release): 版本号 $CURRENT → $NEXT" --quiet
echo "▸ Version: $CURRENT → $NEXT"

./build.sh
./Tools/make-dmg.sh

DMG="dist/Xorssaint-$NEXT.dmg"
[[ -f "$DMG" ]] && echo "✓ Ready: $DMG"
