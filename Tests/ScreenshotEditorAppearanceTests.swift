// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import AppKit
import Foundation

/// The editor's own appearance setting. Following the app must leave the
/// window on the app's appearance, while the two fixed choices pin it.
enum ScreenshotEditorAppearanceTests {
    static func run(_ suite: TestSuite) {
        values(suite)
        wiring(suite)
    }

    private static func values(_ suite: TestSuite) {
        suite.expect(ScreenshotEditorAppearance.fallback == .followApp,
                     "the editor follows the app until the user says otherwise")
        suite.expect(ScreenshotEditorAppearance.sanitized("light") == .light
                     && ScreenshotEditorAppearance.sanitized("dark") == .dark
                     && ScreenshotEditorAppearance.sanitized("followApp") == .followApp,
                     "a stored choice reads back as itself")
        suite.expect(ScreenshotEditorAppearance.sanitized(nil) == .followApp
                     && ScreenshotEditorAppearance.sanitized("nonsense") == .followApp
                     && ScreenshotEditorAppearance.sanitized("") == .followApp,
                     "an unknown or missing value falls back to following the app")
        suite.expect(ScreenshotEditorAppearance.allCases.count == 3,
                     "the picker offers exactly three choices")

        // Following the app must not pin the window: a nil appearance leaves
        // it on whatever NSApp applies, which is the app's own choice.
        suite.expect(ScreenshotEditorAppearance.followApp.nsAppearance == nil,
                     "following the app leaves the window unpinned")
        suite.expect(ScreenshotEditorAppearance.light.nsAppearance
                        == NSAppearance(named: .aqua),
                     "the light choice pins the window to aqua")
        suite.expect(ScreenshotEditorAppearance.dark.nsAppearance
                        == NSAppearance(named: .darkAqua),
                     "the dark choice pins the window to dark aqua")
    }

    private static func wiring(_ suite: TestSuite) {
        suite.expect(Defaults.registeredDefaults[DefaultsKey.screenshotEditorAppearance]
                        as? String == ScreenshotEditorAppearance.fallback.rawValue,
                     "the preference is registered with the fallback value")
        // The key is registered, so a backup carries it without an extra list.
        suite.expect(SettingsBackupSupport.exportKeys().contains(DefaultsKey.screenshotEditorAppearance),
                     "a settings backup carries the editor appearance")

        let settings = (try? String(contentsOfFile:
                "Sources/Xorssaint/UI/Settings/ScreenshotSettings.swift", encoding: .utf8)) ?? ""
        suite.expect(settings.contains("@AppStorage(DefaultsKey.screenshotEditorAppearance)"),
                     "the screenshot settings page reads the preference")
        suite.expect(settings.contains("Text(appearanceStrings.editorFollowApp)")
                     && settings.contains("Text(appearanceStrings.light)")
                     && settings.contains("Text(appearanceStrings.dark)"),
                     "the picker offers following the app, light and dark")

        let controller = (try? String(contentsOfFile:
                "Sources/Xorssaint/Services/QuickTools/ScreenshotEditorController.swift",
                                   encoding: .utf8)) ?? ""
        suite.expect(controller.contains("window?.appearance = choice.nsAppearance"),
                     "the editor applies the chosen appearance to its window")
        suite.expect(controller.contains("UserDefaults.didChangeNotification"),
                     "an open editor notices a change in Settings")

        let strings = (try? String(contentsOfFile:
                "Sources/Xorssaint/Core/AppearanceStrings.swift", encoding: .utf8)) ?? ""
        suite.expect(strings.components(separatedBy: "editorFollowApp: \"").count - 1 == 15,
                     "every language carries the editor appearance strings")
    }
}
