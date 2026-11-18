// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

/// The pure decisions behind hiding other apps' menu bar icons: the allow-list
/// the macOS 27 restriction holds, the stored selection's cleanup, what the
/// settings page lists, and where the feature lives in Settings.
enum MenuBarHidingTests {
    static func run(_ suite: TestSuite) {
        suite.run("menu bar hiding allow-list") {
            allowListDecisions(suite)
        }
        suite.run("menu bar hiding stored selection") {
            storedSelectionDecisions(suite)
        }
        suite.run("menu bar hiding listing and gates") {
            listingAndGates(suite)
        }
        suite.run("menu bar hiding catalog placement") {
            catalogPlacement(suite)
        }
    }

    private static func allowListDecisions(_ suite: TestSuite) {
        let own = "com.xorssaint.utils"
        let running = ["alpha", "beta", own, "gamma"]

        func activation(hidden: [String], enabled: Bool = true, revealed: Bool = false)
            -> MenuBarHidingSupport.Activation {
            MenuBarHidingSupport.activation(
                hiddenApps: hidden,
                runningBundleIdentifiers: running,
                ownBundleIdentifier: own,
                featureEnabled: enabled,
                temporarilyRevealed: revealed
            )
        }

        suite.expect(activation(hidden: ["alpha"], enabled: false) == .inactive,
               "a switched-off feature holds nothing")
        suite.expect(activation(hidden: []) == .inactive,
               "an empty selection never enters assessment mode, whose side effects buy nothing")
        suite.expect(activation(hidden: ["alpha"], revealed: true) == .inactive,
               "a temporary reveal releases the restriction")

        // The restriction is assessment mode: holding it while it hides
        // nothing still costs the clock-click and recording-capsule behavior,
        // so the empty-selection guard above is the contract that matters most.
        if case .activate(let allowed) = activation(hidden: ["alpha", "not.running.app"]) {
            suite.expect(allowed == ["beta", "com.xorssaint.utils", "gamma"],
                   "the allow-list keeps every running app except the selection, plus this app")
        } else {
            suite.expect(false, "a selection over running apps activates")
        }
        if case .activate(let allowed) = activation(hidden: [own]) {
            suite.expect(allowed == ["alpha", "beta", "com.xorssaint.utils", "gamma"],
                   "this app's own bundle id stays allowed even when selected")
        } else {
            suite.expect(false, "selecting this app's own bundle id still activates")
        }
        if case .activate(let allowed) = activation(hidden: ["alpha", "beta"]) {
            suite.expect(allowed.sorted() == allowed,
                   "the allow-list is sorted, so an unchanged selection compares equal across syncs")
        } else {
            suite.expect(false, "a two-app selection activates")
        }
    }

    private static func storedSelectionDecisions(_ suite: TestSuite) {
        let own = "com.xorssaint.utils"
        suite.expect(MenuBarHidingSupport.sanitizedHiddenApps(
            ["beta", "", "alpha", "beta", own, "alpha"], ownBundleIdentifier: own)
            == ["alpha", "beta"],
               "the stored selection drops empties, duplicates and this app's own bundle id")
        suite.expect(MenuBarHidingSupport.sanitizedHiddenApps(nil, ownBundleIdentifier: own) == [],
               "a missing stored selection reads as empty")
        suite.expect(MenuBarHidingSupport.sanitizedHiddenApps(["beta"], ownBundleIdentifier: nil)
            == ["beta"],
               "a missing own bundle id only stops the self-exclusion")
    }

    private static func listingAndGates(_ suite: TestSuite) {
        let own = "com.xorssaint.utils"
        suite.expect(!MenuBarHidingSupport.isListableApp(bundleIdentifier: nil, ownBundleIdentifier: own),
               "an app without a bundle id cannot be picked")
        suite.expect(!MenuBarHidingSupport.isListableApp(bundleIdentifier: "", ownBundleIdentifier: own),
               "an empty bundle id cannot be picked")
        suite.expect(!MenuBarHidingSupport.isListableApp(bundleIdentifier: own, ownBundleIdentifier: own),
               "this app never lists itself")
        suite.expect(!MenuBarHidingSupport.isListableApp(
            bundleIdentifier: "com.apple.controlcenter", ownBundleIdentifier: own),
               "Apple's own apps stay off the list: the restriction hides apps, not system items")
        suite.expect(MenuBarHidingSupport.isListableApp(
            bundleIdentifier: "dev.example.menuapp", ownBundleIdentifier: own),
               "a third-party app is listable")

        let applications = [URL(fileURLWithPath: "/Applications")]
        suite.expect(MenuBarHidingSupport.runsFromApplicationsFolder(
            bundleURL: URL(fileURLWithPath: "/Applications/Xorssaint.app"),
            applicationFolders: applications),
               "an app inside an Applications folder passes the location gate")
        suite.expect(!MenuBarHidingSupport.runsFromApplicationsFolder(
            bundleURL: URL(fileURLWithPath: "/Users/dev/Build/Xorssaint.app"),
            applicationFolders: applications),
               "a build-folder app fails the location gate: macOS would not match its allow-list")
        suite.expect(MenuBarHidingSupport.runsFromApplicationsFolder(
            bundleURL: URL(fileURLWithPath: "/System/Applications/Notes.app"),
            applicationFolders: applications),
               "system locations are exempt from the Applications-folder check")
        suite.expect(!MenuBarHidingSupport.runsFromApplicationsFolder(
            bundleURL: nil, applicationFolders: applications),
               "a missing bundle URL fails the location gate")

        suite.expect(!MenuBarHidingSupport.isSupportedOS(majorVersion: 26),
               "macOS 26 predates the visibility restriction")
        suite.expect(MenuBarHidingSupport.isSupportedOS(majorVersion: 27),
               "macOS 27 carries the visibility restriction")
        suite.expect(MenuBarHidingSupport.isSupportedOS(majorVersion: 28),
               "a newer macOS stays supported")
        suite.expect(MenuBarHidingSupport.systemItemsToKeep == Array(0..<64),
               "every known system item identifier stays visible")
    }

    private static func catalogPlacement(_ suite: TestSuite) {
        suite.expect(AppFeature.menuBarHiding.group == .tools,
               "menu bar hiding lives in the tools hub section")
        suite.expect(AppFeature.menuBarHiding.enabledKeys == [DefaultsKey.menuBarHidingEnabled],
               "menu bar hiding engages through its master switch")
        suite.expect(!AppFeature.menuBarHiding.installedByDefault,
               "menu bar hiding waits on the Features page instead of installing itself")
        suite.expect(AppFeature.menuBarHiding.permissions.isEmpty,
               "menu bar hiding needs no TCC permission")
        suite.expect(AppFeature.menuBarHiding.settingsDestination.page == .menuBarHiding,
               "menu bar hiding's settings destination is its own page")
        suite.expect(FeatureVisibilitySupport.features(for: .menuBarHiding) == [.menuBarHiding],
               "the settings page is gated on the feature alone")
        suite.expect(Defaults.registeredDefaults[DefaultsKey.menuBarHidingEnabled] as? Bool == false,
               "the master switch registers off")
    }
}
