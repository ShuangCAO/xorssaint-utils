// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import AppKit
import Foundation

/// macOS 27 owns menu bar icon hiding. This fork no longer holds a private
/// assessment-mode assertion; the settings page only explains where the system
/// control lives and opens it.
enum MenuBarHidingSupport {
    /// The first macOS release with the menu bar management this page points
    /// at. Older systems still show the page, but the button stays disabled.
    static let requiredMacOSMajorVersion = 27

    /// The Menu Bar pane is the direct destination. Control Center is the
    /// fallback for builds that file the same controls under its older pane,
    /// and the Settings root is the final safety net.
    static let systemSettingsURLs: [URL] = [
        URL(string: "x-apple.systempreferences:com.apple.MenuBar-Settings.extension")!,
        URL(string: "x-apple.systempreferences:com.apple.ControlCenter-Settings.extension")!,
        URL(string: "x-apple.systempreferences:")!,
    ]

    static func isSupportedOS(
        majorVersion: Int = ProcessInfo.processInfo.operatingSystemVersion.majorVersion
    ) -> Bool {
        majorVersion >= requiredMacOSMajorVersion
    }

    /// Opens the first Settings destination macOS accepts.
    @discardableResult
    static func openSystemSettings() -> Bool {
        for url in systemSettingsURLs where NSWorkspace.shared.open(url) {
            return true
        }
        return false
    }
}