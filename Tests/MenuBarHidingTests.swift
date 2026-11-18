// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

/// The settings page now only points at macOS 27's own menu bar controls.
/// These checks pin the OS gate, the Settings links and the page's visibility.
enum MenuBarHidingTests {
    static func run(_ suite: TestSuite) {
        suite.run("menu bar hiding system settings") {
            suite.expect(!MenuBarHidingSupport.isSupportedOS(majorVersion: 26),
                   "macOS 26 predates the system menu bar controls")
            suite.expect(MenuBarHidingSupport.isSupportedOS(majorVersion: 27),
                   "macOS 27 carries the system menu bar controls")
            suite.expect(MenuBarHidingSupport.isSupportedOS(majorVersion: 28),
                   "a newer macOS stays supported")

            suite.expect(MenuBarHidingSupport.systemSettingsURLs.count == 3,
                   "the page keeps a direct pane and two fallbacks")
            suite.expect(MenuBarHidingSupport.systemSettingsURLs.allSatisfy {
                $0.scheme == "x-apple.systempreferences"
            }, "every destination is a System Settings deep link")
            suite.expect(MenuBarHidingSupport.systemSettingsURLs.first?
                .absoluteString.contains("MenuBar-Settings.extension") == true,
                   "the direct link opens the Menu Bar pane")

            suite.expect(AppFeature.menuBarHiding.group == .tools
                    && AppFeature.menuBarHiding.enabledKeys.isEmpty
                    && !AppFeature.menuBarHiding.installedByDefault
                    && AppFeature.menuBarHiding.permissions.isEmpty,
                   "menu bar hiding is an opt-in informational tool with no switch or permission")
            suite.expect(AppFeature.menuBarHiding.settingsDestination.page == .menuBarHiding,
                   "the feature owns its settings page")
            suite.expect(FeatureVisibilitySupport.features(for: .menuBarHiding) == [.menuBarHiding],
                   "the settings page appears only while the feature is installed")
            suite.expect(!FeatureStrings.menuBarHiding(.enUS).unavailableOS.isEmpty,
                   "the page can explain the OS requirement")
        }
    }
}