// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

/// Pure decisions for hiding other apps' menu bar icons on macOS 27.
///
/// macOS offers no public API to hide another app's status item. macOS 27's
/// private MenuBarClientCore framework (the assessment-mode restriction)
/// hides every app the allow-list does not name and reflows the bar itself,
/// so hiding here means "hold an allow-list", never touching another app.
/// The list allows every running app except the ones the user picked, plus
/// this app itself; the system's own items (clock, Wi-Fi, Control Center...)
/// are covered by separate numeric identifiers and always stay visible.
enum MenuBarHidingSupport {
    /// System item identifiers the restriction keeps visible. Unknown
    /// identifiers are ignored, so the range covers items a given Mac does
    /// not have (0-63 checked on macOS 27 by Hidden Bar, whose approach this
    /// follows).
    static let systemItemsToKeep = Array(0..<64)

    /// The menu bar re-architecture that carries MenuBarClientCore. Older
    /// systems have neither the framework nor the restriction, so the feature
    /// reports itself unsupported there instead of holding nothing.
    static let requiredMacOSMajorVersion = 27

    static func isSupportedOS(majorVersion: Int = ProcessInfo.processInfo.operatingSystemVersion.majorVersion) -> Bool {
        majorVersion >= requiredMacOSMajorVersion
    }

    /// What the service should hold right now.
    enum Activation: Equatable {
        /// Hold nothing: every icon stays visible.
        case inactive

        /// Hold an allow-list; every app it does not name is hidden.
        case activate(allowedBundleIdentifiers: [String])
    }

    /// The allow-list for the current state, or nothing to hold.
    ///
    /// An empty hidden selection never activates: the restriction is the whole
    /// assessment mode, whose side effects (clock clicks ignored, the
    /// microphone/camera capsule hidden) are not worth holding while it would
    /// hide nothing. A temporary reveal releases the list the same way, so
    /// "show everything" is always one toggle away.
    static func activation(hiddenApps: [String],
                           runningBundleIdentifiers: [String],
                           ownBundleIdentifier: String?,
                           featureEnabled: Bool,
                           temporarilyRevealed: Bool) -> Activation {
        let hidden = Set(hiddenApps)
        guard featureEnabled, !temporarilyRevealed, !hidden.isEmpty else {
            return .inactive
        }
        var allowed = Set(runningBundleIdentifiers).subtracting(hidden)
        if let ownBundleIdentifier {
            // This app's own icon is the feature's only menu bar surface; it
            // stays visible even if someone pastes its bundle id into the list.
            allowed.insert(ownBundleIdentifier)
        }
        return .activate(allowedBundleIdentifiers: allowed.sorted())
    }

    /// The stored hidden selection, cleaned up: no empty entries, no
    /// duplicates, no stable order an insertion order should leak, and never
    /// this app's own bundle id.
    static func sanitizedHiddenApps(_ raw: [String]?, ownBundleIdentifier: String?) -> [String] {
        var seen = Set<String>()
        var cleaned = [String]()
        for identifier in (raw ?? []) where !identifier.isEmpty {
            guard identifier != ownBundleIdentifier, seen.insert(identifier).inserted else {
                continue
            }
            cleaned.append(identifier)
        }
        return cleaned.sorted()
    }

    /// Whether a running app belongs on the settings page's pick list. Only
    /// third-party bundles are offered: the restriction hides apps by bundle
    /// id, while the system's own extras are covered by the numeric system
    /// item identifiers and cannot be hidden this way at all.
    static func isListableApp(bundleIdentifier: String?, ownBundleIdentifier: String?) -> Bool {
        guard let bundleIdentifier, !bundleIdentifier.isEmpty else {
            return false
        }
        return bundleIdentifier != ownBundleIdentifier && !bundleIdentifier.hasPrefix("com.apple.")
    }

    /// Whether the app this feature runs in sits in an Applications folder.
    ///
    /// macOS 27 matches the allow-list only to apps it knows by bundle id,
    /// which (measured by Hidden Bar on 27.2) it does for apps in an
    /// Applications folder but not for one run from a build folder or
    /// Downloads — such a build can end up with its own icon hidden and no
    /// surface left to reveal with. System locations are exempt: they are
    /// never "outside" for this purpose.
    static func runsFromApplicationsFolder(bundleURL: URL?,
                                           applicationFolders: [URL] = FileManager.default.urls(
                                               for: .applicationDirectory, in: .localDomainMask)) -> Bool {
        guard let bundleURL else { return false }
        let path = bundleURL.resolvingSymlinksInPath().standardizedFileURL.path
        if ["/System/", "/usr/", "/Library/Apple/"].contains(where: path.hasPrefix) {
            return true
        }
        return applicationFolders.contains { folder in
            let folderPath = folder.resolvingSymlinksInPath().standardizedFileURL.path
            return path == folderPath || path.hasPrefix(folderPath + "/")
        }
    }
}
