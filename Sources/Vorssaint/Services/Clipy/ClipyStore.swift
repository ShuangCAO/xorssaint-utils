// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import AppKit
import Foundation

/// The independent Clipy history store. It lives beside the app's other
/// private files, but nothing here is shared with Vorssaint's clipboard.
final class ClipyStore {
    private let fileManager = FileManager.default
    private let rootURL: URL?
    private let indexURL: URL?
    private let blobsURL: URL?

    init(rootURL: URL? = ClipyStore.defaultRootURL) {
        self.rootURL = rootURL
        indexURL = rootURL?.appendingPathComponent("index.json", isDirectory: false)
        blobsURL = rootURL?.appendingPathComponent("blobs", isDirectory: true)
        if let rootURL {
            PrivateFileStore.createDirectory(at: rootURL)
            if let blobsURL { PrivateFileStore.createDirectory(at: blobsURL) }
        }
    }

    static var defaultRootURL: URL? {
        PrivateFileStore.containerURL?.appendingPathComponent("Clipy", isDirectory: true)
    }

    func load() -> [ClipyEntry] {
        guard let indexURL, let data = try? Data(contentsOf: indexURL) else { return [] }
        guard let entries = try? JSONDecoder().decode([ClipyEntry].self, from: data) else { return [] }
        return entries.filter { entry in
            if let folder = folderURL(for: entry.id),
               fileManager.fileExists(atPath: folder.path) {
                return true
            }
            return entry.filePaths?.isEmpty == false
        }
    }

    func save(_ entries: [ClipyEntry]) {
        guard let indexURL, let data = try? JSONEncoder().encode(entries) else { return }
        PrivateFileStore.write(data, to: indexURL)
    }

    /// Writes one entry's representation blobs and returns whether the entry
    /// has anything the menu could paste.
    @discardableResult
    func write(_ entry: ClipyEntry, representations: [String: Data]) -> Bool {
        guard entry.filePaths?.isEmpty == false || !representations.isEmpty else { return false }
        guard let folder = folderURL(for: entry.id, create: true) else { return false }
        for (type, data) in representations {
            let url = folder.appendingPathComponent(Self.fileName(for: type), isDirectory: false)
            PrivateFileStore.write(data, to: url)
        }
        return true
    }

    func data(for entry: ClipyEntry, type: String) -> Data? {
        guard let folder = folderURL(for: entry.id) else { return nil }
        return try? Data(contentsOf: folder.appendingPathComponent(Self.fileName(for: type),
                                                                   isDirectory: false))
    }

    func delete(_ entry: ClipyEntry) {
        if let folder = folderURL(for: entry.id) {
            try? fileManager.removeItem(at: folder)
        }
    }

    func clear() {
        guard let blobsURL else { return }
        try? fileManager.removeItem(at: blobsURL)
        PrivateFileStore.createDirectory(at: blobsURL)
        save([])
    }

    /// Keeps the newest `limit` entries by the chosen order and removes the
    /// blobs of the rest.
    func pruned(_ entries: [ClipyEntry], limit: Int, sort: ClipySortOrder) -> [ClipyEntry] {
        guard entries.count > max(0, limit) else { return entries }
        let ordered = entries.sorted {
            sort == .created ? $0.createdAt > $1.createdAt : $0.lastUsedAt > $1.lastUsedAt
        }
        let kept = Array(ordered.prefix(max(0, limit)))
        let keptIDs = Set(kept.map(\.id))
        for entry in entries where !keptIDs.contains(entry.id) {
            delete(entry)
        }
        return kept
    }

    private func folderURL(for id: UUID, create: Bool = false) -> URL? {
        guard let blobsURL else { return nil }
        let url = blobsURL.appendingPathComponent(id.uuidString, isDirectory: true)
        if create {
            PrivateFileStore.createDirectory(at: url)
        }
        return url
    }

    private static func fileName(for type: String) -> String {
        let safe = type.map { character -> Character in
            character.isLetter || character.isNumber ? character : "_"
        }
        return String(safe) + ".bin"
    }
}