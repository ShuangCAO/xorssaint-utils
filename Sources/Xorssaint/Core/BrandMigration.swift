// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

/// Copies the old Vorssaint preferences and private files into the Xorssaint
/// bundle identity once. The old domain and directory are left in place so the
/// upstream app keeps working, and so a failed copy can be retried.
enum BrandMigration {
    private static let markerKey = "xorssaintMigratedFromVorssaint"
    private static let oldReleaseID = "com.vorssaint.utils"
    private static let oldDeveloperID = "com.vorssaint.utils.dev"

    static func runIfNeeded() {
        guard !CommandLine.arguments.contains("--uninstall") else { return }
        guard let newID = Bundle.main.bundleIdentifier,
              newID == "com.xorssaint.utils" || newID == "com.xorssaint.utils.dev" else { return }

        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: markerKey) else { return }

        let oldID = newID.hasSuffix(".dev") ? oldDeveloperID : oldReleaseID
        copyPreferences(from: oldID, to: newID, defaults: defaults)
        let copiedFiles = copySupportDirectory(from: oldID, to: newID)
        if copiedFiles {
            defaults.set(true, forKey: markerKey)
        }
    }

    private static func copyPreferences(from oldID: String,
                                        to newID: String,
                                        defaults: UserDefaults) {
        guard let old = defaults.persistentDomain(forName: oldID) else { return }
        let new = defaults.persistentDomain(forName: newID) ?? [:]
        for (key, value) in old where new[key] == nil {
            defaults.set(value, forKey: key)
        }
    }

    /// Returns false only when an old directory exists but could not be
    /// copied, so the next launch tries again.
    private static func copySupportDirectory(from oldID: String, to newID: String) -> Bool {
        guard let base = FileManager.default.urls(for: .applicationSupportDirectory,
                                                  in: .userDomainMask).first else { return true }
        let oldURL = base.appendingPathComponent(oldID, isDirectory: true)
        let newURL = base.appendingPathComponent(newID, isDirectory: true)
        let manager = FileManager.default

        guard manager.fileExists(atPath: oldURL.path) else { return true }
        if !manager.fileExists(atPath: newURL.path) {
            do {
                try manager.copyItem(at: oldURL, to: newURL)
                return true
            } catch {
                return false
            }
        }

        let copied = copyMissingItems(from: oldURL, to: newURL, manager: manager)
        try? manager.setAttributes([.posixPermissions: 0o700], ofItemAtPath: newURL.path)
        return copied
    }

    /// Copies only entries the new directory does not already have. Both trees
    /// can contain the same folder (Clipy, for example), so recurse instead of
    /// skipping a whole folder and losing its history.
    private static func copyMissingItems(from source: URL,
                                         to destination: URL,
                                         manager: FileManager) -> Bool {
        var copied = true
        let children = (try? manager.contentsOfDirectory(
            at: source, includingPropertiesForKeys: [.isDirectoryKey])) ?? []
        for child in children {
            let target = destination.appendingPathComponent(child.lastPathComponent)
            guard !manager.fileExists(atPath: target.path) else {
                let sourceIsDirectory = (try? child.resourceValues(forKeys: [.isDirectoryKey]))?
                    .isDirectory == true
                let targetIsDirectory = (try? target.resourceValues(forKeys: [.isDirectoryKey]))?
                    .isDirectory == true
                if sourceIsDirectory && targetIsDirectory {
                    if !copyMissingItems(from: child, to: target, manager: manager) {
                        copied = false
                    }
                }
                continue
            }
            do {
                try manager.copyItem(at: child, to: target)
            } catch {
                copied = false
            }
        }
        return copied
    }
}