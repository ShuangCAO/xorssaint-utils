// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import AppKit
import SwiftUI

enum ClipyMenuRow: Identifiable {
    case header(String, Int)
    case entry(ClipyEntry, Int)
    case folder(ClipyMenuFolder, Int)
    case snippetFolder(String, [ClipySnippet], Int)
    case snippet(ClipySnippet, Int)

    var id: String {
        switch self {
        case .header(_, let index): return "h-\(index)"
        case .entry(let entry, _): return "e-\(entry.id)"
        case .folder(let folder, _): return "f-\(folder.startNumber)"
        case .snippetFolder(let name, _, _): return "sf-\(name)"
        case .snippet(let snippet, _): return "s-\(snippet.id)"
        }
    }

    var isActionable: Bool {
        if case .header = self { return false }
        return true
    }
}

enum ClipyOpenFolder: Equatable {
    case history(ClipyMenuFolder)
    case snippets(String, [ClipySnippet])

    var title: String {
        switch self {
        case .history(let folder): return "\(folder.start)–\(folder.end)"
        case .snippets(let name, _): return name
        }
    }

    var count: Int {
        switch self {
        case .history(let folder): return folder.entries.count
        case .snippets(_, let snippets): return snippets.count
        }
    }
}

final class ClipyMenuModel: ObservableObject {
    let service: ClipyService
    let mode: ClipyMenuMode

    @Published var selection: Int?
    @Published var openFolder: ClipyOpenFolder?
    @Published var folderSelection: Int?

    init(service: ClipyService, mode: ClipyMenuMode) {
        self.service = service
        self.mode = mode
        if UserDefaults.standard.bool(forKey: DefaultsKey.clipyHighlightFirst) {
            selection = actionableRows.isEmpty ? nil : 0
        }
    }

    private var defaults: UserDefaults { .standard }
    private var strings: ClipyStrings { FeatureStrings.clipy(L10n.shared.language) }

    var rootRows: [ClipyMenuRow] {
        var rows: [ClipyMenuRow] = []
        var number = 1
        let store = ClipySnippetStore.load()

        if mode == .main {
            let entries = sortedEntries
            let split = ClipyMenuBuilder.folders(
                entries: entries,
                inlineLimit: defaults.integer(forKey: DefaultsKey.clipyInlineLimit),
                folderLimit: defaults.integer(forKey: DefaultsKey.clipyFolderLimit))
            if !entries.isEmpty {
                rows.append(.header(strings.historySection, rows.count))
                for entry in split.inline {
                    rows.append(.entry(entry, number))
                    number += 1
                }
                for folder in split.folders {
                    rows.append(.folder(folder, number))
                    number += 1
                }
            }
        }

        if mode == .snippets, let filter = service.snippetFolderFilter {
            let snippets = store.snippets.filter { $0.enabled && $0.folder == filter }
            if !filter.isEmpty {
                rows.append(.header(filter, rows.count))
            }
            for snippet in snippets {
                rows.append(.snippet(snippet, number))
                number += 1
            }
        } else if mode == .main || mode == .snippets {
            if !store.folders.isEmpty {
                rows.append(.header(strings.snippetsSection, rows.count))
                for folder in store.folders {
                    let snippets = store.snippets.filter { $0.enabled && $0.folder == folder }
                    rows.append(.snippetFolder(folder, snippets, number))
                    number += 1
                }
            }
        }
        return rows
    }

    var actionableRows: [ClipyMenuRow] {
        rootRows.filter(\.isActionable)
    }

    var panelWidth: CGFloat {
        openFolder == nil ? 280 : 540
    }

    var estimatedHeight: CGFloat {
        let rootHeight = CGFloat(rootRows.count) * 26 + 42
        return min(560, max(140, rootHeight))
    }

    func numberLabel(for number: Int) -> String? {
        guard defaults.bool(forKey: DefaultsKey.clipyMarksNumbers),
              number >= 1, number <= 10 else { return nil }
        if defaults.bool(forKey: DefaultsKey.clipyStartsAtZero) {
            return "\(number - 1)"
        }
        return number == 10 ? "0" : "\(number)"
    }

    func isSelected(_ row: ClipyMenuRow) -> Bool {
        guard let selection, actionableRows.indices.contains(selection) else { return false }
        return actionableRows[selection].id == row.id
    }

    func select(_ row: ClipyMenuRow) {
        guard let index = actionableRows.firstIndex(where: { $0.id == row.id }) else { return }
        selection = index
    }

    func moveSelection(by delta: Int) {
        let rows = actionableRows
        guard !rows.isEmpty else { selection = nil; return }
        let current = selection ?? 0
        selection = min(max(current + delta, 0), rows.count - 1)
    }

    func moveFolderSelection(by delta: Int) {
        let count = openFolder?.count ?? 0
        guard count > 0 else { folderSelection = nil; return }
        let current = folderSelection ?? 0
        folderSelection = min(max(current + delta, 0), count - 1)
    }

    func activateSelection() {
        guard let selection, actionableRows.indices.contains(selection) else { return }
        activate(actionableRows[selection])
    }

    func activate(_ row: ClipyMenuRow) {
        switch row {
        case .header:
            break
        case .entry(let entry, _):
            service.paste(entry)
        case .folder(let folder, _):
            openFolder = .history(folder)
            folderSelection = folder.entries.isEmpty ? nil : 0
        case .snippetFolder(let name, let snippets, _):
            openFolder = .snippets(name, snippets)
            folderSelection = snippets.isEmpty ? nil : 0
        case .snippet(let snippet, _):
            service.pasteText(snippet.content)
        }
    }

    /// Hovering a folder row opens its column like a click, without firing
    /// any other action the row could carry. Both folder kinds expand so the
    /// menu reads as one consistent submenu behavior.
    func hoverExpand(_ row: ClipyMenuRow) {
        switch row {
        case .folder, .snippetFolder:
            activate(row)
        default:
            break
        }
    }

    func activateFolderSelection() {
        guard let folderSelection, let openFolder,
              openFolder.count > folderSelection else { return }
        switch openFolder {
        case .history(let folder):
            service.paste(folder.entries[folderSelection])
        case .snippets(_, let snippets):
            service.pasteText(snippets[folderSelection].content)
        }
    }

    func openSelectedFolder() {
        guard let selection, actionableRows.indices.contains(selection) else { return }
        switch actionableRows[selection] {
        case .folder(let folder, _):
            openFolder = .history(folder)
            folderSelection = folder.entries.isEmpty ? nil : 0
        case .snippetFolder(let name, let snippets, _):
            openFolder = .snippets(name, snippets)
            folderSelection = snippets.isEmpty ? nil : 0
        default:
            break
        }
    }

    func closeFolder() {
        openFolder = nil
        folderSelection = nil
    }

    func activateNumber(_ index: Int) {
        let rows = actionableRows
        guard rows.indices.contains(index) else { return }
        activate(rows[index])
    }

    private var sortedEntries: [ClipyEntry] {
        let order = ClipySortOrder.current(in: defaults)
        return service.entries.sorted {
            order == .created ? $0.createdAt > $1.createdAt : $0.lastUsedAt > $1.lastUsedAt
        }
    }
}