#!/bin/zsh
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Vorssaint

# Builds Xorssaint, assembles the .app bundle, signs it and (with --install)
# installs it into /Applications.
#
# The bundle is staged in a temporary directory outside ~/Documents: folders synced
# by File Provider gain xattrs (com.apple.provenance etc.) that invalidate codesign.
set -euo pipefail
cd "$(dirname "$0")"

# The icon catalog and the bundle are staged in temp dirs; sweep both however
# the script ends.
ICON_TMP=""
STAGE_TMP=""

cleanup() {
    [[ -n "$ICON_TMP" ]] && rm -rf "$ICON_TMP"
    [[ -n "$STAGE_TMP" ]] && rm -rf "$STAGE_TMP"
    return 0
}
trap cleanup EXIT
# zsh runs the EXIT trap when the script is hung up, but not when it is
# interrupted or terminated; route those through exit so a Ctrl-C partway
# into the build sweeps like any other ending.
trap 'exit 1' INT TERM HUP

# Flags: --dev builds the local-only "Xorssaint (Developer)" variant (its own
# bundle id, so it coexists with the official app); --install puts it in /Applications.
DEV=0
INSTALL=0
TEST=0
TEST_ARGS=()
for arg in "$@"; do
    case "$arg" in
        --dev)     DEV=1 ;;
        --install) INSTALL=1 ;;
        --test)    TEST=1 ;;
        --test-suite=*) TEST=1; TEST_ARGS+=("--suite=${arg#*=}") ;;
        --list-tests) TEST=1; TEST_ARGS+=(--list) ;;
    esac
done

if (( DEV )); then
    APP_NAME="Xorssaint (Developer)"
    EXECUTABLE="XorssaintDeveloper"
    APP_BUNDLE_ID="com.xorssaint.utils.dev"
    BUILD_VARIANT_FLAGS=(-D XORSSAINT_DEVELOPMENT)
    APP_OPTIMIZATION_FLAGS=(-Onone)
    BUILD_CONFIGURATION="debug"
else
    APP_NAME="Xorssaint"
    EXECUTABLE="Xorssaint"
    APP_BUNDLE_ID="com.xorssaint.utils"
    BUILD_VARIANT_FLAGS=()
    APP_OPTIMIZATION_FLAGS=(-O)
    BUILD_CONFIGURATION="release"
fi
FAN_HELPER_ID="$APP_BUNDLE_ID.fan-control"
# Now Playing is read through /usr/bin/perl loading this library; see
# Sources/NowPlayingAdapter. Staged under Contents/Frameworks, signed on its own.
NOW_PLAYING_ADAPTER_ID="$APP_BUNDLE_ID.now-playing"
NOW_PLAYING_ADAPTER="libXorssaintNowPlaying.dylib"
TARGET="arm64-apple-macosx14.0"
ENTITLEMENTS="Resources/Xorssaint.entitlements"
LEGACY_IDENTITY="Xorssaint Utils Signing"

developer_id_identity() {
    security find-identity -v -p codesigning 2>/dev/null \
        | grep 'Developer ID Application' \
        | head -1 \
        | sed -E 's/.*"(.*)".*/\1/' || true
}

# A find-identity listing also names certificates codesign then rejects (an
# expired one fails the build with errSecInternalComponent), and -v excludes
# every self-signed one; ask codesign itself with a throwaway copy of /bin/echo.
legacy_identity_installed() {
    local probe signed=1
    # A locked keychain still lists its identities but cannot sign with them,
    # and this one is locked after every reboot; unlock it before asking.
    security unlock-keychain -p xorssaint-signing \
        "$HOME/Library/Keychains/xorssaint-signing.keychain-db" 2>/dev/null || true
    probe="$(mktemp)"
    cp /bin/echo "$probe"
    /usr/bin/codesign --force --strip-disallowed-xattrs --sign "$LEGACY_IDENTITY" "$probe" \
        >/dev/null 2>&1 && signed=0
    rm -f "$probe"
    return $signed
}

# Any build that lands in /Applications needs a stable signature, not just the
# Developer one: macOS ties Accessibility and Screen Recording grants to the
# exact binary hash, so an ad-hoc rebuild orphans them while System Settings
# keeps showing them as granted, and no new prompt ever appears. A plain
# --install strands them under the released bundle id, on the app the user
# actually relies on. When no identity is installed, create the stable local one
# up front instead of falling through to ad-hoc — setup-signing.sh is free,
# offline and idempotent. Gating on the install rather than the variant keeps
# this off CI, where neither ci.yml nor release.yml passes --install.
if (( DEV || INSTALL )) && [[ -z "$(developer_id_identity)" ]] \
    && ! legacy_identity_installed; then
    echo "▸ No signing identity installed; creating the stable local one…"
    if ! ./Tools/setup-signing.sh; then
        echo "  ⚠ Tools/setup-signing.sh failed; signing ad-hoc instead." >&2
        echo "    Accessibility and Screen Recording grants will not survive rebuilds:" >&2
        echo "    System Settings will show them as granted while the app is not trusted." >&2
        echo "    After fixing the identity, clear the stale grant once with:" >&2
        echo "      tccutil reset Accessibility $APP_BUNDLE_ID" >&2
    fi
fi

codesign_with_timestamp_retry() {
    local attempt
    for attempt in 1 2 3; do
        if /usr/bin/codesign "$@"; then
            return 0
        fi
        if (( attempt < 3 )); then
            echo "  Developer ID signing failed; retrying ($((attempt + 1))/3)"
            sleep "$attempt"
        fi
    done
    return 1
}

write_swift_output_file_map() {
    local output_file="$1"
    local object_dir="$2"
    shift 2
    local source artifact

    {
        print -r -- "{"
        print -r -- "  \"\": {"
        print -r -- "    \"swift-dependencies\": \"$object_dir/master.swiftdeps\""
        print -r -- "  }"
        for source in "$@"; do
            artifact="${source//\//__}"
            artifact="${artifact%.swift}"
            print -r -- ","
            print -r -- "  \"$source\": {"
            print -r -- "    \"object\": \"$object_dir/$artifact.o\","
            print -r -- "    \"swift-dependencies\": \"$object_dir/$artifact.swiftdeps\""
            print -r -- "  }"
        done
        print -r -- "}"
    } > "$output_file"
}

finalize_installed_bundle_after_child() {
    local bundle="$1"
    local helper="$bundle/Contents/Library/LaunchServices/$FAN_HELPER_ID"
    local adapter="$bundle/Contents/Frameworks/$NOW_PLAYING_ADAPTER"
    local devid
    devid="$(developer_id_identity)"

    echo "▸ Finalizing installed signature…"
    sleep 3
    if [[ -n "$devid" ]]; then
        [[ -f "$helper" ]] && codesign_with_timestamp_retry --force --strip-disallowed-xattrs \
            --options runtime --timestamp --identifier "$FAN_HELPER_ID" --sign "$devid" "$helper"
        [[ -f "$adapter" ]] && codesign_with_timestamp_retry --force --strip-disallowed-xattrs \
            --options runtime --timestamp --identifier "$NOW_PLAYING_ADAPTER_ID" --sign "$devid" "$adapter"
        codesign_with_timestamp_retry --force --strip-disallowed-xattrs --options runtime --timestamp \
            --entitlements "$ENTITLEMENTS" --sign "$devid" "$bundle"
    elif legacy_identity_installed; then
        [[ -f "$helper" ]] && /usr/bin/codesign --force --strip-disallowed-xattrs \
            --identifier "$FAN_HELPER_ID" --sign "$LEGACY_IDENTITY" "$helper"
        [[ -f "$adapter" ]] && /usr/bin/codesign --force --strip-disallowed-xattrs \
            --identifier "$NOW_PLAYING_ADAPTER_ID" --sign "$LEGACY_IDENTITY" "$adapter"
        /usr/bin/codesign --force --strip-disallowed-xattrs --sign "$LEGACY_IDENTITY" "$bundle"
    else
        [[ -f "$helper" ]] && /usr/bin/codesign --force --strip-disallowed-xattrs \
            --identifier "$FAN_HELPER_ID" --sign - "$helper"
        [[ -f "$adapter" ]] && /usr/bin/codesign --force --strip-disallowed-xattrs \
            --identifier "$NOW_PLAYING_ADAPTER_ID" --sign - "$adapter"
        /usr/bin/codesign --force --strip-disallowed-xattrs --sign - "$bundle"
    fi
    [[ -f "$helper" ]] && /usr/bin/codesign --verify --strict "$helper"
    [[ -f "$adapter" ]] && /usr/bin/codesign --verify --strict "$adapter"
    /usr/bin/codesign --verify --deep --strict "$bundle"
    echo "✓ Signature ready: $bundle"
}

if (( INSTALL && ! TEST )) && [[ "${XORSSAINT_INSTALL_CHILD:-0}" != "1" ]]; then
    XORSSAINT_INSTALL_CHILD=1 "$0" "$@"
    child_status=$?
    if (( child_status != 0 )); then
        exit "$child_status"
    fi
    finalize_installed_bundle_after_child "/Applications/$APP_NAME.app"
    exit 0
fi

# Prefer the macOS 26 SDK when present: the 27 SDK turns SwiftUI property wrappers
# into macros (SwiftUIMacros plugin) that the Command Line Tools cannot load yet.
PINNED_SDK="/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk"
if [[ -n "${DEVELOPER_DIR:-}" ]]; then
    SDK="$(xcrun --show-sdk-path)"
elif [[ -d "$PINNED_SDK" ]]; then
    SDK="$PINNED_SDK"
else
    SDK="$(xcrun --show-sdk-path)"
fi
SDK_COMPAT_FLAGS=()
VM_STATISTICS_COMPAT_FLAGS=(-I Sources/VMStatisticsCompat)
HID_EVENT_SYSTEM_FLAGS=(-I Sources/HIDEventSystem)
CORE_AUDIO_TAP_FLAGS=(-I Sources/CoreAudioTapCompat)
GIF_CODEC_FLAGS=(-I Sources/RecorderGIFCodec)
GIF_CODEC_OBJECTS=(build/objects/recorder-gif-codec/RecorderGIFCodec.o
                   build/objects/recorder-gif-codec/cgif_raw.o)
if [[ "$SDK" == "$PINNED_SDK" ]]; then
    # Swift 6.4 can read the SDK 26 interfaces when given their compiler version.
    SDK_COMPAT_FLAGS=(-Xfrontend -interface-compiler-version -Xfrontend 6.3.2)
fi

# The defaults migrations under test need a real UserDefaults suite, and every
# suite leaves an empty plist in ~/Library/Preferences. The tests already clear
# the domains, but cfprefsd writes the emptied file back out around the time the
# process that owned it exits, so only a caller that outlives the run can remove
# them. `PreferenceNamespaceTests` scans every compiled Swift test file against
# these namespaces, which keeps this sweep complete without a second list.
discard_test_preferences() {
    local preferences="${1:-$HOME/Library/Preferences}" name attempt
    local survivors=0 quiet_passes=0
    # cfprefsd can recreate an emptied domain after the first removal. Require
    # two quiet checks, but keep a hard limit so persistent failures still fail CI.
    for attempt in {1..10}; do
        for name in "vorss.tests." "com.xorssaint.tests."; do
            rm -f "$preferences"/$name*.plist(N)
        done
        rm -f "$preferences/metrics-tests.plist"
        sleep 0.2
        survivors=$(find "$preferences" -maxdepth 1 \
            \( -name "vorss.tests.*.plist" -o -name "com.xorssaint.tests.*.plist" \
               -o -name "metrics-tests.plist" \) 2>/dev/null | wc -l | tr -d ' ')
        if [[ "$survivors" == "0" ]]; then
            quiet_passes=$((quiet_passes + 1))
            if (( quiet_passes == 2 )); then return 0; fi
        else
            quiet_passes=0
        fi
    done
    echo "✗ test preferences did not settle in $preferences ($survivors remaining)" >&2
    return 1
}

# Standalone automated tests: pure contracts plus isolated disk, subprocess,
# keyboard-data and media fixtures. No application windows or device capture.
mkdir -p build/objects/recorder-gif-codec
xcrun clang -O3 -std=c99 -target "$TARGET" -isysroot "$SDK" \
    -c Sources/RecorderGIFCodec/RecorderGIFCodec.c -o "$GIF_CODEC_OBJECTS[1]"
xcrun clang -O3 -std=c99 -target "$TARGET" -isysroot "$SDK" \
    -c Sources/RecorderGIFCodec/vendor/cgif/cgif_raw.c -o "$GIF_CODEC_OBJECTS[2]"
if (( TEST )); then
    python3 Tests/generate_sources.py
    TEST_OBJECT_DIR="build/objects/tests"
    mkdir -p "$TEST_OBJECT_DIR"
    TEST_SOURCES=(
        Sources/Xorssaint/Services/Media/MediaSupport.swift
        Sources/Xorssaint/Core/QuitProtectionSupport.swift
        Sources/Xorssaint/Core/QuitProtectionStrings.swift
        Sources/Xorssaint/Core/Defaults.swift
        Sources/Xorssaint/Core/MenuBarHidingSupport.swift
        Sources/Xorssaint/Core/ScreenshotEditorAppearance.swift
        Sources/Xorssaint/Core/MenuBarHidingStrings.swift
        Sources/Xorssaint/Core/NotchStrings.swift
        Sources/Xorssaint/Core/NotchTourStrings.swift
        Sources/Xorssaint/Core/NotchEditorStrings.swift
        Sources/Xorssaint/UI/Settings/NotchSettingsTabRow.swift
        Sources/Xorssaint/Core/NotchActivityStrings.swift
        Sources/Xorssaint/Services/Notch/NotchTimerSupport.swift
        Sources/Xorssaint/Services/Notch/NotchAppFullscreen.swift
        Sources/Xorssaint/Services/Notch/NotchTimerAlert.swift
        Sources/Xorssaint/UI/Notch/NotchIslandAlert.swift
        Sources/Xorssaint/Services/Notch/NotchAccessorySupport.swift
        Sources/Xorssaint/Services/Notch/NotchAccessoryConnectionMonitor.swift
        Sources/Xorssaint/Services/QuickTools/CameraPreviewSupport.swift
        Sources/Xorssaint/Core/NotchMusicExtrasStrings.swift
        Sources/Xorssaint/Core/NotchClipboardSizeStrings.swift
        Sources/Xorssaint/Services/Notch/NotchLyricsSupport.swift
        Sources/Xorssaint/Services/Notch/NotchQueueSupport.swift
        Sources/Xorssaint/Services/Notch/NotchPreferredPlayer.swift
        Sources/Xorssaint/Core/NotchFilesStrings.swift
        Sources/Xorssaint/Core/NotchWatchStrings.swift
        Sources/Xorssaint/Services/Notch/NotchWatchSupport.swift
        Sources/Xorssaint/Core/NotchMascotStrings.swift
        Sources/Xorssaint/Services/Notch/NotchMascotSupport.swift
        Sources/Xorssaint/Services/CommandBar/CommandBarDropletMotion.swift
        Sources/Xorssaint/Services/Notch/NotchFileToolsSupport.swift
        Sources/Xorssaint/Services/Notch/NotchDownloadSupport.swift
        Sources/Xorssaint/Services/Notch/NotchDownloadProgressObserver.swift
        Sources/Xorssaint/Core/NotchCalendarStrings.swift
        Sources/Xorssaint/Core/NotchNotificationStrings.swift
        Sources/Xorssaint/Core/NotchGestureStrings.swift
        Sources/Xorssaint/Core/NotchAgentStrings.swift
        Sources/Xorssaint/Core/CodexAccountStrings.swift
        Sources/Xorssaint/Core/ClaudeAccountStrings.swift
        Sources/Xorssaint/Services/Notch/NotchAgentSupport.swift
        Sources/Xorssaint/Core/NotchLockScreenStrings.swift
        Sources/Xorssaint/Services/Notch/NotchLockScreenSupport.swift
        Sources/Xorssaint/Services/AgentUsage/AgentUsageModels.swift
        Sources/Xorssaint/Services/AgentUsage/AgentPricing.swift
        Sources/Xorssaint/Services/AgentUsage/AgentLogObject.swift
        Sources/Xorssaint/Services/AgentUsage/AgentLogParser.swift
        Sources/Xorssaint/Services/AgentUsage/Harness/AgentHarnessReader.swift
        Sources/Xorssaint/Services/AgentUsage/Harness/ClaudeReader.swift
        Sources/Xorssaint/Services/AgentUsage/Harness/CodexReader.swift
        Sources/Xorssaint/Services/AgentUsage/Harness/OpenCodeReader.swift
        Sources/Xorssaint/Services/AgentUsage/Harness/CopilotReader.swift
        Sources/Xorssaint/Services/AgentUsage/AgentUsageSummary.swift
        Sources/Xorssaint/Services/AgentUsage/AgentUsageStore.swift
        Sources/Xorssaint/Services/AgentUsage/AgentUsageArchive.swift
        Sources/Xorssaint/Services/AgentUsage/AgentClaudeAppUsage.swift
        Sources/Xorssaint/Services/AgentUsage/AgentCLIConversation.swift
        Sources/Xorssaint/Services/AgentUsage/AgentClaudeServer.swift
        Sources/Xorssaint/Services/AgentUsage/ClaudeAccountProfile.swift
        Sources/Xorssaint/Services/AgentUsage/AgentCodexServer.swift
        Sources/Xorssaint/Services/AgentUsage/CodexAccountLimits.swift
        Sources/Xorssaint/Services/AgentUsage/CodexProfileLimitsService.swift
        Sources/Xorssaint/Services/AgentUsage/AgentOpenCodeReader.swift
        Sources/Xorssaint/Services/Notch/NotchGestureSupport.swift
        Sources/Xorssaint/Services/Notch/NotchSectionPaging.swift
        Sources/Xorssaint/Services/Notch/NotchSliderEditing.swift
        Sources/Xorssaint/Services/Notch/NotchNotificationSupport.swift
        Sources/Xorssaint/Services/Notch/NotchNotificationReaderCore.swift
        Sources/Xorssaint/Services/Notch/NotchCalendarSupport.swift
        Sources/Xorssaint/Services/Notch/NotchKeepAwakeSupport.swift
        Sources/Xorssaint/Services/Notch/NotchSupport.swift
        Sources/Xorssaint/Services/Notch/NotchMenuBarSpace.swift
        Sources/Xorssaint/Services/Notch/NotchAudioLevelSupport.swift
        Sources/Xorssaint/Services/Notch/NotchVolumeKeyGate.swift
        Sources/Xorssaint/Services/Notch/NotchMusicSupport.swift
        Sources/Xorssaint/UI/Notch/NotchDecorativeClock.swift
        Sources/Xorssaint/Services/Notch/NotchBrowserArtworkSupport.swift
        Sources/Xorssaint/UI/Notch/NotchEqualizerBars.swift
        Sources/Xorssaint/UI/Notch/NotchScrollEdgeFade.swift
        Sources/Xorssaint/UI/Notch/NotchAgentAnimationView.swift
        Sources/Xorssaint/UI/WindowVisibilityReader.swift
        Sources/Xorssaint/Services/Notch/NotchMusicAutomationSupport.swift
        Sources/Xorssaint/Services/Notch/NotchMusicAutomation.swift
        Sources/Xorssaint/Services/Notch/NotchPlaybackSource.swift
        Sources/Xorssaint/Services/Notch/NotchPlaybackCommand.swift
        Sources/Xorssaint/Services/Notch/NotchMusicCommandWriter.swift
        Sources/Xorssaint/Core/FeatureCatalog.swift
        Sources/Xorssaint/Core/FeaturePresets.swift
        Sources/Xorssaint/Core/FeatureHubStrings.swift
        Sources/Xorssaint/Core/MixerScreenSharingStrings.swift
        Sources/Xorssaint/Core/ShortcutSettingsStrings.swift
        Sources/Xorssaint/Core/SwitcherShortcutStrings.swift
        Sources/Xorssaint/Core/SettingsBackupSupport.swift
        Sources/Xorssaint/Core/BackupStrings.swift
        Sources/Xorssaint/Core/SnippetStrings.swift
        Sources/Xorssaint/Core/AlertSoundStrings.swift
        Sources/Xorssaint/Core/BrightnessStrings.swift
        Sources/Xorssaint/Core/MediaImageStrings.swift
        Sources/Xorssaint/Core/QuickToggleStrings.swift
        Sources/Xorssaint/Core/ScreenshotStrings.swift
        Sources/Xorssaint/Core/RecentCaptureStrings.swift
        Sources/Xorssaint/Core/RecorderStrings.swift
        Sources/Xorssaint/Core/RecorderShareStrings.swift
        Sources/Xorssaint/Core/CameraPreviewStrings.swift
        Sources/Xorssaint/Core/WallpaperStrings.swift
        Sources/Xorssaint/Services/Wallpaper/WallpaperSupport.swift
        Sources/Xorssaint/UI/MenuPanel/WallpaperThumbnailView.swift
        Sources/Xorssaint/Core/ScratchpadStrings.swift
        Sources/Xorssaint/Core/FinderRenameStrings.swift
        Sources/Xorssaint/Core/CommandBarStrings.swift
        Sources/Xorssaint/Core/FeedbackStrings.swift
        Sources/Xorssaint/Core/RadialMenuStrings.swift
        Sources/Xorssaint/Core/MenuBarAppearanceStrings.swift
        Sources/Xorssaint/Core/AppAppearance.swift
        Sources/Xorssaint/Core/AppearanceStrings.swift
        Sources/Xorssaint/Core/GeneralSettingsStrings.swift
        Sources/Xorssaint/Core/CalendarStrings.swift
        Sources/Xorssaint/Core/ClipyStrings.swift
        Sources/Xorssaint/Core/SettingsPageStrings.swift
        Sources/Xorssaint/Core/BatteryTimeStrings.swift
        Sources/Xorssaint/Core/CPUCoreStrings.swift
        Sources/Xorssaint/Core/MonitorLayoutStrings.swift
        Sources/Xorssaint/Core/KeepAwakeStrings.swift
        Sources/Xorssaint/Core/BluetoothSleepStrings.swift
        Sources/Xorssaint/Core/PermissionGuideStrings.swift
        Sources/Xorssaint/Core/FanControlStrings.swift
        Sources/Xorssaint/Core/ConnectedDevicesStrings.swift
        Sources/Xorssaint/Services/FanControl/FanControlSupport.swift
        Sources/Xorssaint/Services/FanControl/FanControlResumeSupport.swift
        Sources/Xorssaint/Services/Snippets/TextSnippetSupport.swift
        Sources/Xorssaint/Services/RadialMenu/RadialMenuSupport.swift
        Sources/Xorssaint/Services/QuickTools/ScratchpadSupport.swift
        Sources/Xorssaint/Services/QuickTools/ScratchpadStore.swift
        Sources/Xorssaint/Services/KillProcess/KillProcessSupport.swift
        Sources/Xorssaint/Services/Recorder/RecorderSupport.swift
        Sources/Xorssaint/Services/Recorder/RecorderSampleTiming.swift
        Sources/Xorssaint/Services/Recorder/RecorderWriter.swift
        Sources/Xorssaint/Services/Recorder/RecorderCaptureEngine.swift
        Sources/Xorssaint/Core/RecorderExportStrings.swift
        Sources/Xorssaint/Core/RecorderExportFormatStrings.swift
        Sources/Xorssaint/Services/Recorder/RecorderComposer.swift
        Sources/Xorssaint/Services/Recorder/RecorderComposerPlan.swift
        Sources/Xorssaint/Services/Recorder/RecorderCursorSprite.swift
        Sources/Xorssaint/Services/Recorder/RecorderTextRenderer.swift
        Sources/Xorssaint/Services/Recorder/RecorderImageRenderer.swift
        Sources/Xorssaint/Services/Recorder/RecorderExporter.swift
        Sources/Xorssaint/Services/Recorder/RecorderGIFClipboard.swift
        Sources/Xorssaint/Services/Recorder/RecorderGIFWriter.swift
        Sources/Xorssaint/Services/Recorder/RecorderFastGIFWriter.swift
        Sources/Xorssaint/Services/Recorder/RecorderGIFWorkspace.swift
        Sources/Xorssaint/Services/Recorder/RecorderComposition.swift
        Sources/Xorssaint/Services/Recorder/RecordingSharingSupport.swift
        Sources/Xorssaint/Services/PrivateFileStore.swift
        Sources/Xorssaint/Core/ClipySupport.swift
        Sources/Xorssaint/Services/Clipy/ClipyStore.swift
        Sources/Xorssaint/Services/Clipy/ClipyCapture.swift
        Sources/Xorssaint/Services/Recorder/RecorderTakeStore.swift
        Sources/Xorssaint/Services/Recorder/RecorderPresetImageStore.swift
        Sources/Xorssaint/Services/Recorder/RecorderMotion.swift
        Sources/Xorssaint/Services/Recorder/RecorderPointerTrack.swift
        Sources/Xorssaint/Services/Recorder/RecorderTypingTrack.swift
        Sources/Xorssaint/Services/Recorder/RecorderTimeline.swift
        Sources/Xorssaint/Services/Recorder/RecorderTextOverlay.swift
        Sources/Xorssaint/Services/Recorder/RecorderImageOverlay.swift
        Sources/Xorssaint/Services/Recorder/RecorderBlurRegion.swift
        Sources/Xorssaint/Services/Recorder/RecorderEditDocument.swift
        Sources/Xorssaint/Core/AppInfo.swift
        Sources/Xorssaint/Core/GlobalShortcut.swift
        Sources/Xorssaint/Core/SymbolicHotKeys.swift
        Sources/Xorssaint/Services/SystemShortcutTakeoverSupport.swift
        Sources/Xorssaint/Core/Localization.swift
        Sources/Xorssaint/Core/Localizations/Strings+*.swift
        Sources/Xorssaint/Core/FeatureStrings.swift
        Sources/Xorssaint/Core/KillProcessStrings.swift
        Sources/Xorssaint/Core/PortManagerStrings.swift
        Sources/Xorssaint/Core/WhatsAppDownloadStrings.swift
        Sources/Xorssaint/Core/WhatsAppOrganizerStrings.swift
        Sources/Xorssaint/Core/ReleaseNotes.swift
        Sources/Xorssaint/Core/ReleaseDigest.swift
        Sources/Xorssaint/Core/ReleaseChangeAliases.swift
        Sources/Xorssaint/Core/WhatsNewStrings.swift
        Sources/Xorssaint/Core/URLCleaning.swift
        Sources/Xorssaint/Services/URLCleanerLinkMetadata.swift
        Sources/Xorssaint/Services/GeneralPasteboardAccess.swift
        Sources/Xorssaint/Services/Clipboard/ClipboardHistoryWrite.swift
        Sources/Xorssaint/Services/Audio/AirPlayRouteManager.swift
        Sources/Xorssaint/Services/Audio/MixerRoutingSupport.swift
        Sources/Xorssaint/Services/Audio/MusicLaunchSupport.swift
        Sources/Xorssaint/Services/Bluetooth/BluetoothSleepSupport.swift
        Sources/Xorssaint/UI/MenuPanel/MixerPercentNativeTextField.swift
        Sources/Xorssaint/UI/MenuPanel/MixerAppDragSource.swift
        Sources/Xorssaint/Services/Audio/BoostLimiter.swift
        Sources/Xorssaint/Services/Audio/MixerRender.swift
        Sources/Xorssaint/Services/Audio/PreciseVolumeRollerSupport.swift
        Sources/Xorssaint/Services/DockPreview/DockPreviewSupport.swift
        Sources/Xorssaint/Services/DockPreview/DockAutohideHold.swift
        Sources/Xorssaint/Services/SpacesOrder/SpacesOrderHold.swift
        Sources/Xorssaint/Services/Homebrew/HomebrewSupport.swift
        Sources/Xorssaint/Services/Homebrew/HomebrewEnvironment.swift
        Sources/Xorssaint/Services/Homebrew/HomebrewManager.swift
        Sources/Xorssaint/UI/HomebrewOperationStatusView.swift
        Sources/Xorssaint/Services/AppUpdates/AppUpdatesSupport.swift
        Sources/Xorssaint/Services/AppUpdates/AppUpdateFeedSupport.swift
        Sources/Xorssaint/Core/AppUpdateStrings.swift
        Sources/Xorssaint/Core/DiskImageInstallerStrings.swift
        Sources/Xorssaint/Services/DiskImageInstaller/DiskImageInstallerSupport.swift
        Sources/Xorssaint/UI/NonModalAlert.swift
        Sources/Xorssaint/Services/Clipboard/ClipboardHistorySupport.swift
        Sources/Xorssaint/Core/ColorValue.swift
        Sources/Xorssaint/Services/Clipboard/ClipboardAutoClearSupport.swift
        Sources/Xorssaint/Services/AutoQuit/AutoQuitSupport.swift
        Sources/Xorssaint/Core/AutoQuitDockAppsStrings.swift
        Sources/Xorssaint/Services/Shelf/ShelfSupport.swift
        Sources/Xorssaint/Services/Shelf/ShelfFilePromiseTransfer.swift
        Sources/Xorssaint/Core/ShelfPromiseDeliveryStrings.swift
        Sources/Xorssaint/Services/Finder/FinderRenameSupport.swift
        Sources/Xorssaint/Services/Update/UpdateInstallerSupport.swift
        Sources/Xorssaint/Services/Update/UpdateServiceSupport.swift
        Sources/Xorssaint/Services/InstalledApps.swift
        Sources/Xorssaint/Services/LaunchAtLoginSupport.swift
        Sources/Xorssaint/UI/Settings/SettingsSearchSupport.swift
        Sources/Xorssaint/UI/Settings/SettingsSidebarSupport.swift
        Sources/Xorssaint/UI/Settings/FeatureVisibilitySupport.swift
        Sources/Xorssaint/UI/Onboarding/WhatsNewSupport.swift
        Sources/Xorssaint/UI/Settings/SettingsWindow.swift
        Sources/Xorssaint/Core/SettingsNavigationStrings.swift
        Sources/Xorssaint/App/MenuBarSpacingSupport.swift
        Sources/Xorssaint/Core/MenuBarClockSupport.swift
        Sources/Xorssaint/Core/CalendarSupport.swift
        Sources/Xorssaint/Core/HolidayStore.swift
        Sources/Xorssaint/App/MenuBarAllowanceSupport.swift
        Sources/Xorssaint/App/ReopenRequestSupport.swift
        Sources/Xorssaint/App/StatusItemAnchorSupport.swift
        Sources/Xorssaint/Services/DockClick/DockClickSupport.swift
        Sources/Xorssaint/Services/Finder/CutPasteProgressSupport.swift
        Sources/Xorssaint/Services/Finder/CutPastePrivilegeSupport.swift
        Sources/Xorssaint/Services/Finder/FinderPasteImageSupport.swift
        Sources/Xorssaint/Services/MiddleClick/MiddleClickSupport.swift
        Sources/Xorssaint/Services/MouseNavigation/MouseNavigationSupport.swift
        Sources/Xorssaint/Services/MouseNavigation/MouseNavigationKeys.swift
        Sources/Xorssaint/Services/MouseButtons/MouseButtonShortcutSupport.swift
        Sources/Xorssaint/Services/MouseButtons/MouseSpacesGestureSupport.swift
        Sources/Xorssaint/Services/MouseClickDebounce/MouseClickDebounceSupport.swift
        Sources/Xorssaint/Services/MouseExceptions/MouseAppExceptionSupport.swift
        Sources/Xorssaint/Services/MouseExceptions/MouseAppExceptions.swift
        Sources/Xorssaint/Services/WindowServerSupport.swift
        Sources/Xorssaint/Services/WindowMaximizerSupport.swift
        Sources/Xorssaint/Core/MouseButtonStrings.swift
        Sources/Xorssaint/Core/MouseClickDebounceStrings.swift
        Sources/Xorssaint/Core/MouseExceptionStrings.swift
        Sources/Xorssaint/Core/ClipboardIgnoredAppsStrings.swift
        Sources/Xorssaint/Core/ClipboardRetentionStrings.swift
        Sources/Xorssaint/Core/WindowLayoutIgnoredAppsStrings.swift
        Sources/Xorssaint/Services/WindowLayout/WindowLayoutIgnoredApps.swift
        Sources/Xorssaint/Core/WindowPreviewExclusionStrings.swift
        Sources/Xorssaint/Core/WindowMaximizerExclusionStrings.swift
        Sources/Xorssaint/Core/DiskExclusionStrings.swift
        Sources/Xorssaint/Core/SwitcherAppRulesStrings.swift
        Sources/Xorssaint/Services/QuickTools/QuickToolsSupport.swift
        Sources/Xorssaint/Services/CommandBar/CommandBarSupport.swift
        Sources/Xorssaint/Services/CommandBar/CommandBarPreferences.swift
        Sources/Xorssaint/Services/CommandBar/CommandBarMath.swift
        Sources/Xorssaint/Services/CommandBar/CommandBarUnits.swift
        Sources/Xorssaint/Services/CommandBar/CommandBarColors.swift
        Sources/Xorssaint/Services/CommandBar/CommandBarEmoji.swift
        Sources/Xorssaint/Services/CommandBar/CommandBarLinks.swift
        Sources/Xorssaint/Services/CommandBar/CommandBarDates.swift
        Sources/Xorssaint/Services/CommandBar/CommandBarRowShortcuts.swift
        Sources/Xorssaint/Services/CommandBar/CommandBarSystemSettingsSupport.swift
        Sources/Xorssaint/Services/CommandBar/CommandBarFileSearchSupport.swift
        Sources/Xorssaint/Services/CommandBar/CommandBarQueryMemory.swift
        Sources/Xorssaint/Services/SpotlightNamesSupport.swift
        Sources/Xorssaint/Services/QuickTools/MicMuteSupport.swift
        Sources/Xorssaint/Services/QuickTools/QuickTogglesSupport.swift
        Sources/Xorssaint/Services/QuickTools/ScreenshotCapturePolicy.swift
        Sources/Xorssaint/Services/QuickTools/ScreenshotSupport.swift
        Sources/Xorssaint/Services/QuickTools/ScreenshotCanvasSupport.swift
        Sources/Xorssaint/Services/QuickTools/ScreenshotImageImport.swift
        Sources/Xorssaint/Services/Media/MediaImageProcessing.swift
        Sources/Xorssaint/Services/QuickTools/ScreenshotImageFile.swift
        Sources/Xorssaint/UI/Settings/ScreenCaptureToolPicker.swift
        Sources/Xorssaint/UI/Settings/MonitorToken.swift
        Sources/Xorssaint/Services/QuickTools/ScreenshotRenderer.swift
        Sources/Xorssaint/Services/QuickTools/ScreenshotImageLayerRendering.swift
        Sources/Xorssaint/Services/QuickTools/RecentCaptureStore.swift
        Sources/Xorssaint/Services/QuickTools/ScreenshotSharingSupport.swift
        Sources/Xorssaint/Services/QuickTools/WindowActivationPolicy.swift
        Sources/Xorssaint/Services/KeyboardDebounce/KeyboardDebounceSupport.swift
        Sources/Xorssaint/Services/SuperKey/SuperKeySupport.swift
        Sources/Xorssaint/Services/SuperKey/SuperKeyMappingGuard.swift
        Sources/Xorssaint/Core/SuperKeyStrings.swift
        Sources/Xorssaint/Core/InputSourceSelection.swift
        Sources/Xorssaint/Services/SessionActivity.swift
        Sources/Xorssaint/Services/SessionActivitySupport.swift
        Sources/Xorssaint/Services/EventTimestamp.swift
        Sources/Xorssaint/Services/OwnKeyEvent.swift
        Sources/Xorssaint/Services/ScrollWheelSupport.swift
        Sources/Xorssaint/Services/HorizontalWheelScrolling.swift
        Sources/Xorssaint/Services/SmoothScrollSupport.swift
        Sources/Xorssaint/Services/MouseAcceleration/MouseAccelerationSupport.swift
        Sources/Xorssaint/Services/FocusFollowsMouse/FocusFollowsMouseSupport.swift
        Sources/Xorssaint/Services/AssistiveKeyboard.swift
        Sources/Xorssaint/Services/Switcher/SwitcherModels.swift
        Sources/Xorssaint/Services/Switcher/WindowServerCaptureQueue.swift
        Sources/Xorssaint/Services/Switcher/SwitcherSupport.swift
        Sources/Xorssaint/Services/Switcher/SpaceHopSupport.swift
        Sources/Xorssaint/Services/Switcher/WindowUseOrder.swift
        Sources/Xorssaint/Services/Switcher/WindowEnumeratorAccessibilityPrefetch.swift
        Sources/Xorssaint/Services/Metrics/MetricFormat.swift
        Sources/Xorssaint/Services/Metrics/VMStatisticsDecoder.swift
        Sources/Xorssaint/Services/KeepAwakeAutomationSupport.swift
        Sources/Xorssaint/Services/SudoersSupport.swift
        Sources/Xorssaint/Services/Metrics/BatteryTimeSupport.swift
        Sources/Xorssaint/Services/Metrics/BatteryPowerSupport.swift
        Sources/Xorssaint/Services/BoundedProcessRunner.swift
        Sources/Xorssaint/Services/DetachedProcess.swift
        Sources/Xorssaint/Services/ShellSupport.swift
        Sources/Xorssaint/Services/PortManager/PortManagerSupport.swift
        Sources/Xorssaint/Services/Metrics/NetworkProcessSupport.swift
        Sources/Xorssaint/Services/Metrics/NetworkSampler.swift
        Sources/Xorssaint/Services/Metrics/NetworkAddressService.swift
        Sources/Xorssaint/Services/Metrics/SpeedTest.swift
        Sources/Xorssaint/Services/Metrics/PeripheralBatterySampler.swift
        Sources/Xorssaint/Services/Metrics/PeripheralBatterySupport.swift
        Sources/Xorssaint/Services/Metrics/DiskSupport.swift
        Sources/Xorssaint/Services/Metrics/MonitorSamplingPolicy.swift
        Sources/Xorssaint/Services/Metrics/USBDeviceSampler.swift
        Sources/Xorssaint/Services/Metrics/CPUCoreSampler.swift
        Sources/Xorssaint/Services/Metrics/MaxCapacityProbe.swift
        Sources/Xorssaint/Services/Metrics/TemperatureSensorSelector.swift
        Sources/Xorssaint/Services/Metrics/SustainedAlertGate.swift
        Sources/Xorssaint/Services/WindowLayout/WindowLayoutSupport.swift
        Sources/Xorssaint/Services/WindowLayout/WindowStageManagerSupport.swift
        Sources/Xorssaint/Core/WindowStageManagerStrings.swift
        Sources/Xorssaint/Core/WindowEdgeSnapRestoreStrings.swift
        Sources/Xorssaint/Services/WindowLayout/WindowGestureSupport.swift
        Sources/Xorssaint/Core/WindowDirectionalStrings.swift
        Sources/Xorssaint/Core/PointerDisplayStrings.swift
        Sources/Xorssaint/Core/GraphScaleStrings.swift
        Sources/Xorssaint/Core/NotchLowBatteryStrings.swift
        Sources/Xorssaint/Services/CleaningMode/CleaningUnlockCounter.swift
        Sources/Xorssaint/Services/CleaningMode/CleaningMouseReleaseGate.swift
        Sources/Xorssaint/Services/Display/ExtraBrightnessSupport.swift
        Sources/Xorssaint/Services/Display/BrightnessSupport.swift
        Sources/Xorssaint/Services/Display/MonitorVolumeKeySettings.swift
        Sources/Xorssaint/Services/Display/LidDimmingSupport.swift
        Sources/Xorssaint/Services/Cleaner/CleanerSupport.swift
        Sources/Xorssaint/Services/Cleaner/CleanerPolicy.swift
        Sources/Xorssaint/Services/Cleaner/CleanerSchedule.swift
        Sources/Xorssaint/Services/Uninstall/UninstallerSupport.swift
        Sources/Xorssaint/Services/ManagedDownloads/WhatsAppDownloadSupport.swift
        Sources/Xorssaint/Core/SecureInputSupport.swift
        Tests/*.swift
        build/generated-tests/*.swift
    )
    TEST_OUTPUT_FILE_MAP="$TEST_OBJECT_DIR/output-file-map.json"
    write_swift_output_file_map "$TEST_OUTPUT_FILE_MAP" "$TEST_OBJECT_DIR" "${TEST_SOURCES[@]}"
    echo "▸ Building & running tests against $(basename "$SDK")…"
    swiftc -Onone -incremental -enable-batch-mode -j "$(sysctl -n hw.logicalcpu)" \
        -module-name XorssaintTests -output-file-map "$TEST_OUTPUT_FILE_MAP" \
        -target "$TARGET" -sdk "$SDK" "${SDK_COMPAT_FLAGS[@]}" \
        "${VM_STATISTICS_COMPAT_FLAGS[@]}" "${CORE_AUDIO_TAP_FLAGS[@]}" "${GIF_CODEC_FLAGS[@]}" \
        "${TEST_SOURCES[@]}" "${GIF_CODEC_OBJECTS[@]}" -o build/metrics-tests
    test_status=0
    ./build/metrics-tests "${TEST_ARGS[@]}" || test_status=$?
    if (( ${#TEST_ARGS} == 0 )); then
        ./Tests/PreferenceCleanupTests.sh || test_status=1
        ./Tests/UninstallSpacesTests.sh || test_status=1
        ./Tests/DeveloperInstallIsolationTests.sh || test_status=1
    fi
    discard_test_preferences || test_status=1
    exit $test_status
fi

echo "▸ Compiling ($BUILD_CONFIGURATION) against $(basename "$SDK")…"
APP_SOURCES=(Sources/Xorssaint/**/*.swift)
if (( ! DEV )); then
    # A release starts from an empty build directory, so nothing an earlier
    # build left behind (an old icon catalog, a staged bundle) can reach it.
    # Only the compiler's incremental records stay: they rebuild whatever
    # changed since, and a fresh checkout has none.
    find build -mindepth 1 -maxdepth 1 ! -name objects -exec rm -rf {} + 2>/dev/null || true
fi
APP_OBJECT_DIR="build/objects/$EXECUTABLE"
mkdir -p build "$APP_OBJECT_DIR"
APP_OUTPUT_FILE_MAP="$APP_OBJECT_DIR/output-file-map.json"
write_swift_output_file_map "$APP_OUTPUT_FILE_MAP" "$APP_OBJECT_DIR" "${APP_SOURCES[@]}"
# Without -j the driver compiles one file at a time, and without batch mode
# each file's compiler parses the whole module again: a clean release took a
# quarter of an hour. Batches share that work and run on every core, and the
# optimization stays per file, as before.
swiftc "${APP_OPTIMIZATION_FLAGS[@]}" -incremental -enable-batch-mode -j "$(sysctl -n hw.logicalcpu)" \
    -output-file-map "$APP_OUTPUT_FILE_MAP" \
    -target "$TARGET" -sdk "$SDK" "${SDK_COMPAT_FLAGS[@]}" "${VM_STATISTICS_COMPAT_FLAGS[@]}" "${HID_EVENT_SYSTEM_FLAGS[@]}" \
    "${CORE_AUDIO_TAP_FLAGS[@]}" "${GIF_CODEC_FLAGS[@]}" \
    "${BUILD_VARIANT_FLAGS[@]}" \
    "${APP_SOURCES[@]}" "${GIF_CODEC_OBJECTS[@]}" -o "build/$EXECUTABLE"
xcrun dyld_info -imports "build/$EXECUTABLE" | awk -f Tests/AudioTapImports.awk

echo "▸ Compiling protected fan helper…"
swiftc -O -target "$TARGET" -sdk "$SDK" "${SDK_COMPAT_FLAGS[@]}" "${BUILD_VARIANT_FLAGS[@]}" \
    Sources/Xorssaint/Services/FanControl/FanControlSupport.swift \
    Sources/Xorssaint/Services/FanControl/FanControlXPC.swift \
    Sources/Xorssaint/Services/SystemMonitor/SMCClient.swift \
    Sources/Xorssaint/Services/Metrics/TemperatureSensorSelector.swift \
    Sources/Xorssaint/Services/FanControl/FanControlHardware.swift \
    Sources/FanControlHelper/main.swift \
    -o "build/$FAN_HELPER_ID"
"build/$FAN_HELPER_ID" --selftest

echo "▸ Compiling Now Playing adapter…"
swiftc -O -target "$TARGET" -sdk "$SDK" "${SDK_COMPAT_FLAGS[@]}" -emit-library \
    -module-name XorssaintNowPlaying \
    Sources/NowPlayingAdapter/NowPlayingAdapter.swift \
    Sources/NowPlayingAdapter/NowPlayingQueue.swift \
    Sources/NowPlayingAdapter/NowPlayingSelection.swift \
    Sources/Xorssaint/Services/Notch/NotchPlaybackSource.swift \
    Sources/Xorssaint/Services/Notch/NotchPlaybackCommand.swift \
    -o "build/$NOW_PLAYING_ADAPTER"

echo "▸ Generating app icon…"
swift Tools/MakeIcon.swift build/AppIcon.iconset
xattr -c -r build/AppIcon.iconset build/AppIcon.icns build/MenuBarIcon.png build/MenuBarIcon@2x.png build/BrandMark.png 2>/dev/null || true
ACTOOL_BIN="$(xcrun --find actool 2>/dev/null || true)"
ICON_TMP="$(mktemp -d)"
ADAPTIVE_SKIP=""
if [[ -z "$ACTOOL_BIN" ]]; then
    ADAPTIVE_SKIP="actool not found (adaptive icons need Xcode 26+)"
else
    echo "▸ Compiling adaptive icon catalog…"
    # actool crashes on File Provider-synced paths, so compile a local copy.
    ditto "Resources/Brand/AppIcon.icon" "$ICON_TMP/AppIcon.icon"
    # Xcode 27 beta actool requires the --compile target directory to already exist.
    mkdir -p "$ICON_TMP/catalog"
    if "$ACTOOL_BIN" "$ICON_TMP/AppIcon.icon" \
            --compile "$ICON_TMP/catalog" \
            --app-icon AppIcon \
            --platform macosx \
            --target-device mac \
            --minimum-deployment-target 14.0 \
            --enable-on-demand-resources NO \
            --output-partial-info-plist "$ICON_TMP/partial-info.plist" \
            >"$ICON_TMP/actool.log" 2>&1 && [[ -s "$ICON_TMP/catalog/Assets.car" ]]; then
        mv "$ICON_TMP/catalog/Assets.car" build/Assets.car
    else
        ADAPTIVE_SKIP="actool could not compile the catalog"
    fi
fi
if [[ -n "$ADAPTIVE_SKIP" ]]; then
    cp "$ICON_TMP/actool.log" build/actool-failure.log 2>/dev/null || true
    echo "  adaptive icon skipped: $ADAPTIVE_SKIP (Dock falls back to AppIcon.icns)"
fi
echo "▸ Assembling and signing bundle…"
STAGE_TMP="$(mktemp -d)"
STAGE="$STAGE_TMP/$APP_NAME.app"
mkdir -p "$STAGE/Contents/MacOS" "$STAGE/Contents/Resources" \
    "$STAGE/Contents/Library/LaunchDaemons" "$STAGE/Contents/Library/LaunchServices"
cp "build/$EXECUTABLE" "$STAGE/Contents/MacOS/$EXECUTABLE"
cp "build/$FAN_HELPER_ID" "$STAGE/Contents/Library/LaunchServices/$FAN_HELPER_ID"
mkdir -p "$STAGE/Contents/Frameworks"
cp "build/$NOW_PLAYING_ADAPTER" "$STAGE/Contents/Frameworks/$NOW_PLAYING_ADAPTER"
cp Resources/now-playing.pl "$STAGE/Contents/Resources/now-playing.pl"
cp Resources/agent-prices.json "$STAGE/Contents/Resources/agent-prices.json"
cp Resources/holidays-cn.json "$STAGE/Contents/Resources/holidays-cn.json"
cp Resources/com.xorssaint.utils.fan-control.plist \
    "$STAGE/Contents/Library/LaunchDaemons/$FAN_HELPER_ID.plist"
cp Resources/Info.plist "$STAGE/Contents/Info.plist"
cp CHANGELOG.md "$STAGE/Contents/Resources/CHANGELOG.md"
for lproj in Resources/*.lproj(N); do
    cp -R "$lproj" "$STAGE/Contents/Resources/"
done
if (( DEV )); then
    # A distinct identity so the Developer build installs and runs next to the
    # official app, with its own permissions, preferences and login item.
    /usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $APP_BUNDLE_ID" "$STAGE/Contents/Info.plist"
    /usr/libexec/PlistBuddy -c "Set :CFBundleName $APP_NAME" "$STAGE/Contents/Info.plist"
    /usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName $APP_NAME" "$STAGE/Contents/Info.plist"
    /usr/libexec/PlistBuddy -c "Set :CFBundleExecutable $EXECUTABLE" "$STAGE/Contents/Info.plist"
    FAN_PLIST="$STAGE/Contents/Library/LaunchDaemons/$FAN_HELPER_ID.plist"
    /usr/libexec/PlistBuddy -c "Set :Label $FAN_HELPER_ID" "$FAN_PLIST"
    /usr/libexec/PlistBuddy -c "Set :BundleProgram Contents/Library/LaunchServices/$FAN_HELPER_ID" "$FAN_PLIST"
    /usr/libexec/PlistBuddy -c "Delete :MachServices:com.xorssaint.utils.fan-control" "$FAN_PLIST"
    /usr/libexec/PlistBuddy -c "Add :MachServices:$FAN_HELPER_ID bool true" "$FAN_PLIST"
    # Stamp the source commit + build time so the running dev app shows (in About)
    # exactly which code it was compiled from. Lets you verify it matches HEAD before
    # testing, instead of unknowingly running a stale build. Dev-only; never shipped.
    SHA="$(git rev-parse --short HEAD 2>/dev/null || echo unknown)"
    [[ -n "$(git status --porcelain 2>/dev/null)" ]] && SHA="$SHA-dirty"
    /usr/libexec/PlistBuddy -c "Add :XorssaintBuildCommit string '$SHA · $(date '+%Y-%m-%d %H:%M')'" "$STAGE/Contents/Info.plist"
    echo "  stamped dev build: $SHA"
fi
FAN_HELPER_VERSION="$(
    export LC_ALL=C
    /usr/bin/shasum -a 256 \
        "$STAGE/Contents/Library/LaunchServices/$FAN_HELPER_ID" \
        "$STAGE/Contents/Library/LaunchDaemons/$FAN_HELPER_ID.plist" \
        | /usr/bin/awk '{print $1}' | /usr/bin/shasum -a 256 \
        | /usr/bin/awk '{print $1}'
)"
/usr/libexec/PlistBuddy -c "Add :XorssaintFanControlHelperVersion string '$FAN_HELPER_VERSION'" \
    "$STAGE/Contents/Info.plist"
printf 'APPL????' > "$STAGE/Contents/PkgInfo"
cp build/AppIcon.icns "$STAGE/Contents/Resources/AppIcon.icns"
cp Sources/RecorderGIFCodec/vendor/cgif/LICENSE "$STAGE/Contents/Resources/cgif-LICENSE.txt"
cp build/MenuBarIcon.png build/MenuBarIcon@2x.png build/BrandMark.png "$STAGE/Contents/Resources/"
if [[ -f build/Assets.car ]]; then
    cp build/Assets.car "$STAGE/Contents/Resources/Assets.car"
fi
if [[ -d Resources/Gifs ]]; then
    mkdir -p "$STAGE/Contents/Resources/Gifs"
    cp Resources/Gifs/*.gif "$STAGE/Contents/Resources/Gifs/"
fi
if ! cmp -s Resources/Gifs/highlights-notch.gif "$STAGE/Contents/Resources/Gifs/highlights-notch.gif"; then
    echo "Dynamic Island tour GIF is missing or differs from the bundled copy" >&2
    exit 1
fi
if [[ -d Resources/Images ]]; then
    mkdir -p "$STAGE/Contents/Resources/Images"
    cp Resources/Images/* "$STAGE/Contents/Resources/Images/"
fi
xattr -c -r "$STAGE" 2>/dev/null || true

# Signing, in order of preference:
#   1. Developer ID Application — the real, Apple-issued identity used for
#      notarized releases. Signed with the hardened runtime (required for
#      notarization), the app's entitlements and a secure timestamp. Gives a
#      stable, team-based designated requirement, so permissions persist across
#      updates AND Gatekeeper shows no "unverified developer" warning.
#   2. "Xorssaint Utils Signing" — the legacy stable self-signed identity, kept
#      as a fallback so contributors without a Developer ID still get a constant
#      designated requirement across their local builds.
#   3. Ad-hoc — fresh clone with no identity at all.
DEVID="$(developer_id_identity)"
codesign_app() {
    local target="$1"
    if [[ -n "$DEVID" ]]; then
        codesign_with_timestamp_retry --force --strip-disallowed-xattrs --options runtime --timestamp \
            --entitlements "$ENTITLEMENTS" --sign "$DEVID" "$target"
    elif legacy_identity_installed; then
        codesign --force --strip-disallowed-xattrs --sign "$LEGACY_IDENTITY" "$target"
    else
        codesign --force --strip-disallowed-xattrs --sign - "$target"
    fi
}

codesign_fan_helper() {
    local target="$1"
    if [[ -n "$DEVID" ]]; then
        codesign_with_timestamp_retry --force --strip-disallowed-xattrs --options runtime --timestamp \
            --identifier "$FAN_HELPER_ID" --sign "$DEVID" "$target"
    elif legacy_identity_installed; then
        codesign --force --strip-disallowed-xattrs --identifier "$FAN_HELPER_ID" \
            --sign "$LEGACY_IDENTITY" "$target"
    else
        codesign --force --strip-disallowed-xattrs --identifier "$FAN_HELPER_ID" --sign - "$target"
    fi
}

codesign_now_playing_adapter() {
    local target="$1"
    if [[ -n "$DEVID" ]]; then
        codesign_with_timestamp_retry --force --strip-disallowed-xattrs --options runtime --timestamp \
            --identifier "$NOW_PLAYING_ADAPTER_ID" --sign "$DEVID" "$target"
    elif legacy_identity_installed; then
        codesign --force --strip-disallowed-xattrs --identifier "$NOW_PLAYING_ADAPTER_ID" \
            --sign "$LEGACY_IDENTITY" "$target"
    else
        codesign --force --strip-disallowed-xattrs --identifier "$NOW_PLAYING_ADAPTER_ID" --sign - "$target"
    fi
}

sign_bundle() {
    local bundle="$1"
    local executable="$bundle/Contents/MacOS/$EXECUTABLE"
    local helper="$bundle/Contents/Library/LaunchServices/$FAN_HELPER_ID"
    local adapter="$bundle/Contents/Frameworks/$NOW_PLAYING_ADAPTER"

    if [[ -n "$DEVID" ]]; then
        echo "  signing with Developer ID (hardened runtime): $DEVID"
    elif legacy_identity_installed; then
        echo "  signing with legacy self-signed identity: $LEGACY_IDENTITY"
    else
        echo "  signing ad-hoc (no identity installed — run Tools/setup-signing.sh)"
    fi
    [[ -f "$helper" ]] && codesign_fan_helper "$helper"
    [[ -f "$adapter" ]] && codesign_now_playing_adapter "$adapter"
    codesign_app "$bundle"

    # If local filesystem metadata invalidates the first signature, sign once
    # more. The installed Developer bundle is signed again after the final copy.
    if ! codesign --verify --deep --strict "$bundle" >/dev/null 2>&1; then
        echo "  re-signing after filesystem metadata settled"
        xattr -c -r "$bundle" 2>/dev/null || true
        [[ -f "$helper" ]] && codesign_fan_helper "$helper"
        [[ -f "$adapter" ]] && codesign_now_playing_adapter "$adapter"
        codesign_app "$bundle"
    fi
    [[ -f "$executable" ]] && codesign --verify --strict "$executable"
    [[ -f "$helper" ]] && codesign --verify --strict "$helper"
    [[ -f "$adapter" ]] && codesign --verify --strict "$adapter"
    codesign --verify --deep --strict "$bundle"
}

sign_installed_bundle() {
    local bundle="$1"
    wait_for_install_metadata "$bundle"
    sign_bundle "$bundle"
}

sign_bundle "$STAGE"

process_is_running() {
    local proc="$1"
    if (( ${#proc} > 15 )); then
        pgrep -f "/Contents/MacOS/$proc" >/dev/null 2>&1
    else
        pgrep -x "$proc" >/dev/null 2>&1
    fi
}

stop_process() {
    local proc="$1"
    if (( ${#proc} > 15 )); then
        pkill -f "/Contents/MacOS/$proc" 2>/dev/null || true
    else
        pkill -x "$proc" 2>/dev/null || true
    fi
    for _ in {1..50}; do
        if ! process_is_running "$proc"; then
            return 0
        fi
        sleep 0.1
    done
    echo "✗ $proc is still running — quit it and retry" >&2
    return 1
}

wait_for_install_metadata() {
    local bundle="$1"
    local missing
    for _ in {1..50}; do
        missing=0
        while IFS= read -r file; do
            if ! xattr -p com.apple.provenance "$file" >/dev/null 2>&1; then
                missing=1
                break
            fi
        done < <(find "$bundle/Contents" -type f ! -path "*/_CodeSignature/*")
        if (( missing == 0 )); then
            return 0
        fi
        sleep 0.1
    done
}

# Installed development builds only need the copy in /Applications. Retaining
# another app in each checkout pollutes application search with stale builds.
if (( DEV )); then
    for old_bundle in "build/stage/$APP_NAME.app" "build/stage.noindex/$APP_NAME.app"; do
        if [[ -d "$old_bundle" ]]; then
            /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
                -u "$PWD/$old_bundle" >/dev/null 2>&1 || true
            rm -rf "$old_bundle"
        fi
    done
fi

if (( !DEV || !INSTALL )); then
    STAGE_DIRECTORY="build/stage"
    (( DEV )) && STAGE_DIRECTORY="build/stage.noindex"
    mkdir -p "$STAGE_DIRECTORY"
    BUILD_STAGE="$STAGE_DIRECTORY/$APP_NAME.app"
    rm -rf "$BUILD_STAGE"
    ditto --noextattr --noqtn "$STAGE" "$BUILD_STAGE"
    xattr -c -r "$BUILD_STAGE" 2>/dev/null || true
    if ! codesign --verify --deep --strict "$BUILD_STAGE" >/dev/null 2>&1; then
        if xattr -lr "$BUILD_STAGE" 2>/dev/null | grep -Eq 'com\.apple\.(FinderInfo|ResourceFork|provenance|fileprovider)'; then
            echo "  staging copy has local filesystem metadata; temp bundle was verified"
        else
            codesign --verify --deep --strict "$BUILD_STAGE"
        fi
    fi
    echo "✓ Bundle ready: $BUILD_STAGE"
fi

if (( INSTALL )); then
    echo "▸ Installing into /Applications…"
    stop_process "$EXECUTABLE"
    # Only an official install replaces the pre-rename official apps. The
    # Developer variant must coexist with them just as it does with Xorssaint.
    if (( ! DEV )); then
        for legacy in "Vorss:Vorss" "Vorssaint Utils:VorssaintUtils"; do
            name="${legacy%%:*}"; proc="${legacy##*:}"
            if [[ -d "/Applications/$name.app" ]]; then
                stop_process "$proc"
                rm -rf "/Applications/$name.app"
                echo "  (legacy $name.app removed)"
            fi
        done
    fi
    INSTALL_DEST="/Applications/$APP_NAME.app"
    rm -rf "$INSTALL_DEST"
    ditto --noextattr --noqtn "$STAGE" "$INSTALL_DEST"
    sign_installed_bundle "$INSTALL_DEST"
    echo "✓ Installed: $INSTALL_DEST"
fi
