#!/bin/zsh
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Vorssaint

# Packages the built app into a styled, distributable DMG
# (dist/Xorssaint-<version>.dmg): a window with the app icon, an arrow and
# the Applications folder for drag-and-drop install. Run ./build.sh first.
set -euo pipefail
cd "$(dirname "$0")/.."

APP_NAME="Xorssaint"
APP="build/stage/$APP_NAME.app"
VOLUME="$APP_NAME"
STAGING=""
WORK=""
MOUNT=""

cleanup() {
    if [[ -n "$MOUNT" ]]; then
        hdiutil detach "$MOUNT" -quiet 2>/dev/null \
            || hdiutil detach "$MOUNT" -force -quiet 2>/dev/null \
            || true
    fi
    [[ -n "$STAGING" ]] && rm -rf "$STAGING"
    [[ -n "$WORK" ]] && rm -rf "$WORK"
}
trap cleanup EXIT

if [[ ! -d "$APP" ]]; then
    echo "✗ $APP not found — run ./build.sh first" >&2
    exit 1
fi
xattr -cr "$APP"
codesign --verify --deep --strict "$APP"

VERSION="$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$APP/Contents/Info.plist")"
OUT="dist/Xorssaint-$VERSION.dmg"

echo "▸ Rendering installer background…"
swift Tools/MakeDMGBackground.swift build/dmg-background.png

echo "▸ Staging DMG contents…"
STAGING="$(mktemp -d)"
ditto "$APP" "$STAGING/$APP_NAME.app"
xattr -cr "$STAGING/$APP_NAME.app"
codesign --verify --deep --strict "$STAGING/$APP_NAME.app"
ln -s /Applications "$STAGING/Applications"
mkdir "$STAGING/.background"
cp build/dmg-background.png "$STAGING/.background/background.png"

# Gatekeeper rejects the locally signed build, so keep the first-launch steps
# beside the app instead of relying on a chat message that gets lost.
cat > "$STAGING/安装说明.txt" <<'EOF'
Xorssaint 安装说明
==================

这是非官方 Xorssaint fork，与上游 Vorssaint 项目没有隶属关系。

安装
----
1. 将 Xorssaint.app 拖到 Applications 文件夹。
2. 打开 Applications 里的 Xorssaint。
3. 如果 macOS 拦截：
   打开“系统设置 → 隐私与安全性”，在底部点击“仍要打开”，然后再次启动。
   如果提示“已损坏”，确认文件来源可信后，在终端执行：
   xattr -dr com.apple.quarantine /Applications/Xorssaint.app
4. 首次启动后按提示授予辅助功能、屏幕录制、麦克风等权限。

系统要求
--------
- Apple Silicon Mac
- macOS 14 Sonoma 或更新版本

说明
----
- 本版本未经过 Apple 公证，使用本地签名。
- 自动更新、截图/录屏分享链接和反馈上传已禁用。
- 从旧 Vorssaint 升级时，会复制旧设置和 CCClip 历史；
  系统权限与 Bundle ID 绑定，需要重新授权。
- Fan Control 的 XPC 校验仍绑定上游 Apple Team ID，release 版可能不可用。

English
-------
1. Drag Xorssaint.app to Applications.
2. If macOS blocks it, open System Settings → Privacy & Security and choose Open Anyway.
3. If macOS says the app is damaged, verify the source and run:
   xattr -dr com.apple.quarantine /Applications/Xorssaint.app
4. Grant Accessibility, Screen Recording and Microphone permissions when prompted.

Requires Apple Silicon and macOS 14 or newer. This build is not notarized.
Automatic updates, sharing links and feedback uploads are disabled.
EOF

echo "▸ Creating writable image…"
WORK="$(mktemp -d)"
RW="$WORK/rw.dmg"
# Clear any stale mount left by a previous attempt on the same runner.
hdiutil detach "/Volumes/$VOLUME" -force 2>/dev/null || true
# hdiutil can fail transiently on CI runners; retry a few times. No -quiet, so a
# real error is visible in the build log rather than swallowed.
created=0
for attempt in 1 2 3; do
    if hdiutil create -volname "$VOLUME" -srcfolder "$STAGING" -fs HFS+ -format UDRW -ov "$RW"; then
        created=1
        break
    fi
    echo "  hdiutil create failed (attempt $attempt of 3), retrying…" >&2
    rm -f "$RW"
    sleep 3
done
if [[ $created -ne 1 ]]; then
    echo "✗ Could not create the disk image after 3 attempts" >&2
    exit 1
fi
ATTACH_OUTPUT="$(hdiutil attach "$RW" -nobrowse)"
MOUNT="$(printf '%s\n' "$ATTACH_OUTPUT" | awk '/\/Volumes\// {print substr($0, index($0, "/Volumes/")); exit}')"
if [[ -z "$MOUNT" || ! -d "$MOUNT" ]]; then
    echo "✗ Could not find mounted volume in hdiutil output" >&2
    printf '%s\n' "$ATTACH_OUTPUT" >&2
    exit 1
fi

echo "▸ Arranging window (icons, arrow, background)…"
# Finder automation lays out the window; best-effort so a headless hiccup never
# fails the release (the DMG is still valid, just unstyled that once).
osascript <<APPLESCRIPT &
tell application "Finder"
    tell disk "$VOLUME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {200, 120, 800, 520}
        set theOptions to the icon view options of container window
        set arrangement of theOptions to not arranged
        set icon size of theOptions to 128
        set text size of theOptions to 13
        set background picture of theOptions to file ".background:background.png"
        set position of item "$APP_NAME.app" of container window to {150, 200}
        set position of item "Applications" of container window to {450, 200}
        update without registering applications
        delay 1
        close
    end tell
end tell
APPLESCRIPT
STYLE_PID=$!
STYLE_STATUS=0
STYLE_TIMED_OUT=0
for _ in {1..25}; do
    if ! kill -0 "$STYLE_PID" 2>/dev/null; then
        wait "$STYLE_PID" || STYLE_STATUS=$?
        break
    fi
    sleep 1
done
if kill -0 "$STYLE_PID" 2>/dev/null; then
    STYLE_TIMED_OUT=1
    kill "$STYLE_PID" 2>/dev/null || true
    sleep 1
    kill -9 "$STYLE_PID" 2>/dev/null || true
    wait "$STYLE_PID" 2>/dev/null || true
fi
if (( STYLE_TIMED_OUT )); then
    echo "  (window styling timed out; continuing with a valid unstyled DMG)"
elif (( STYLE_STATUS != 0 )); then
    echo "  (window styling skipped)"
fi

sync
hdiutil detach "$MOUNT" -quiet \
    || hdiutil detach "$MOUNT" -force -quiet
MOUNT=""

echo "▸ Compressing…"
mkdir -p dist
rm -f "$OUT"
hdiutil convert "$RW" -format UDZO -imagekey zlib-level=9 -o "$OUT" -quiet

echo "✓ DMG ready: $OUT"
