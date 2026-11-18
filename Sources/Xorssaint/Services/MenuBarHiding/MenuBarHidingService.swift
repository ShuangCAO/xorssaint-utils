// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import AppKit
import Combine
import MenuBarVisibility
import os

/// Hides other apps' menu bar icons on macOS 27 by holding the system's
/// menu bar visibility restriction (the private MenuBarClientCore allow-list
/// behind assessment mode). The list allows every running app except the
/// ones picked in Settings, plus this app itself; macOS hides the rest and
/// reflows the bar on its own.
///
/// Fail-open by design: an unsupported OS, a missing framework, a build
/// outside an Applications folder or an activation error all end with
/// nothing held and a reason the Settings page can show — never a menu bar
/// that hides things the user cannot bring back. Quitting or crashing
/// releases the restriction automatically, because the assertion dies with
/// the process.
///
/// Main thread only, like the services it sits beside; every asynchronous
/// entry point (defaults writes, running-app changes, the shim's completion)
/// hops to the main queue before touching state.
final class MenuBarHidingService: ObservableObject {
    /// Why hiding cannot engage right now, shown in Settings.
    enum UnavailableReason: Equatable {
        case unsupportedOS
        case frameworkMissing
        case outsideApplicationsFolder
    }

    static let shared = MenuBarHidingService()

    /// True while the user lifted the restriction from the menu bar menu,
    /// so every icon shows until they toggle it back.
    @Published private(set) var isTemporarilyRevealed = false

    @Published private(set) var unavailableReason: UnavailableReason?

    /// True while a restriction is held, for the menu row's title.
    var isHidingActive: Bool { assertion != nil }

    private var assertion: AnyObject?
    /// What the held (or in-flight) restriction allows, so an unchanged list
    /// never re-activates and a swap always supersedes an older activation.
    private var heldAllowedBundles: [String]?
    private var generation = 0

    private var cancellables = Set<AnyCancellable>()
    private var syncScheduled = false

    private static let log = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "xorssaint",
        category: "MenuBarHiding"
    )

    private var ownBundleIdentifier: String? { Bundle.main.bundleIdentifier }

    private init() {
        // Settings writes (the toggle, the app list) resync on the next turn
        // of the run loop; a burst of writes collapses into one sync.
        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.scheduleSync() }
            .store(in: &cancellables)

        // Menu bar apps are usually agents (no Dock icon), and NSWorkspace
        // does not post launch notifications for those, so the running list
        // itself is watched. Debounced: a launch storm must not thrash the
        // restriction, and a new app needs the list rebuilt once, not per
        // intermediate state.
        NSWorkspace.shared.publisher(for: \.runningApplications)
            .receive(on: DispatchQueue.main)
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in self?.sync() }
            .store(in: &cancellables)

        // The assertion dies with the process anyway; quitting releases it
        // explicitly so the bar restores the moment we leave, not a beat later.
        NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.releaseAssertion() }
            .store(in: &cancellables)
    }

    /// Recomputes what should be held and makes the restriction match. Safe
    /// to call from anywhere, any number of times.
    func sync() {
        guard AppFeature.menuBarHiding.isAvailable else {
            unavailableReason = nil
            releaseAssertion()
            return
        }
        guard MenuBarHidingSupport.isSupportedOS() else {
            unavailableReason = .unsupportedOS
            releaseAssertion()
            return
        }
        guard MenuBarVisibilityIsAvailable() else {
            unavailableReason = .frameworkMissing
            releaseAssertion()
            return
        }
        guard MenuBarHidingSupport.runsFromApplicationsFolder(bundleURL: Bundle.main.bundleURL) else {
            unavailableReason = .outsideApplicationsFolder
            releaseAssertion()
            return
        }
        unavailableReason = nil

        let hidden = MenuBarHidingSupport.sanitizedHiddenApps(
            UserDefaults.standard.stringArray(forKey: DefaultsKey.menuBarHiddenApps),
            ownBundleIdentifier: ownBundleIdentifier
        )
        let running = NSWorkspace.shared.runningApplications.compactMap(\.bundleIdentifier)
        switch MenuBarHidingSupport.activation(
            hiddenApps: hidden,
            runningBundleIdentifiers: running,
            ownBundleIdentifier: ownBundleIdentifier,
            featureEnabled: UserDefaults.standard.bool(forKey: DefaultsKey.menuBarHidingEnabled),
            temporarilyRevealed: isTemporarilyRevealed
        ) {
        case .inactive:
            releaseAssertion()
        case .activate(let allowed):
            hold(allowed)
        }
    }

    /// The menu bar menu's row: lifts the restriction until toggled back.
    /// Does nothing while nothing is selected or the feature is off, so the
    /// row never appears to be broken.
    func toggleTemporaryReveal() {
        guard AppFeature.menuBarHiding.isAvailable,
              UserDefaults.standard.bool(forKey: DefaultsKey.menuBarHidingEnabled),
              !hiddenSelection().isEmpty
        else { return }
        isTemporarilyRevealed.toggle()
        sync()
    }

    /// The cleaned-up hidden selection, for the menu row's visibility gate.
    func hiddenSelection() -> [String] {
        MenuBarHidingSupport.sanitizedHiddenApps(
            UserDefaults.standard.stringArray(forKey: DefaultsKey.menuBarHiddenApps),
            ownBundleIdentifier: ownBundleIdentifier
        )
    }

    private func hold(_ allowed: [String]) {
        guard allowed != heldAllowedBundles || assertion == nil else { return }
        generation += 1
        let requestedGeneration = generation
        heldAllowedBundles = allowed
        Self.log.info("Holding a menu bar allow-list of \(allowed.count) apps")
        MenuBarVisibilityActivate(
            MenuBarHidingSupport.systemItemsToKeep.map { NSNumber(value: $0) },
            allowed
        ) { [weak self] handle, error in
            // The shim promises the main queue; the hop keeps that promise
            // true even if a future shim revision changes it.
            DispatchQueue.main.async {
                self?.activationCompleted(generation: requestedGeneration,
                                          handle: handle,
                                          error: error,
                                          allowed: allowed)
            }
        }
    }

    private func activationCompleted(generation requestedGeneration: Int,
                                     handle: Any?,
                                     error: Error?,
                                     allowed: [String]) {
        guard requestedGeneration == generation else {
            // A newer wish superseded this one: release the stale handle
            // instead of letting two restrictions race.
            if let handle = handle as? AnyObject {
                MenuBarVisibilityInvalidate(handle)
            }
            return
        }
        if let handle = handle as? AnyObject {
            releaseAssertion()
            assertion = handle
            heldAllowedBundles = allowed
        } else {
            Self.log.error("Menu bar visibility activation failed: \(error.map(String.init(describing:)) ?? "unknown error")")
            unavailableReason = .frameworkMissing
            releaseAssertion()
        }
    }

    private func releaseAssertion() {
        heldAllowedBundles = nil
        guard let assertion else { return }
        MenuBarVisibilityInvalidate(assertion)
        self.assertion = nil
    }

    private func scheduleSync() {
        guard !syncScheduled else { return }
        syncScheduled = true
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.syncScheduled = false
            self.sync()
        }
    }
}
