// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import AppKit

/// The editor's own colour scheme.
///
/// Following the app is not the same as following the system: the app can be
/// pinned to light or dark while the system is the other, and the editor
/// follows the app.
enum ScreenshotEditorAppearance: String, CaseIterable, Identifiable {
    case followApp
    case light
    case dark

    var id: String { rawValue }

    static let fallback: ScreenshotEditorAppearance = .followApp

    /// A stored value from an older or hand-edited preference never breaks the
    /// picker; anything unknown falls back to following the app.
    static func sanitized(_ raw: String?) -> ScreenshotEditorAppearance {
        guard let raw, let value = ScreenshotEditorAppearance(rawValue: raw) else { return fallback }
        return value
    }

    /// The window appearance this choice asks for. Nil leaves the window on
    /// whatever the app applies.
    var nsAppearance: NSAppearance? {
        switch self {
        case .followApp: return nil
        case .light: return NSAppearance(named: .aqua)
        case .dark: return NSAppearance(named: .darkAqua)
        }
    }

    static var current: ScreenshotEditorAppearance {
        sanitized(UserDefaults.standard.string(forKey: DefaultsKey.screenshotEditorAppearance))
    }
}
