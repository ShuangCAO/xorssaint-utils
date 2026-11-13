// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import AppKit
import SwiftUI

enum ClipyMenuRow: Identifiable {
    case header(String)
    case entry(ClipyEntry, Int)
    case folder(ClipyMenuFolder, Int)
    case snippet(ClipySnippet, Int)

    var id: String {
        switch self {
        case .header(let title): return "h-\(title)"
        case .entry(let entry, _): return "e-\(entry.id)"
        case .folder(let folder, _): return "f-\(folder.startNumber)"
        case .snippet(let snippet, _): return "s-\(snippet.id)"
        }
    }

    var isActionable: Bool {
        if case .header = self { return false }
        return true
    }
}

final class ClipyMenuModel: ObservableObject {
    let service: ClipyService
    let mode: ClipyMenuMode

    @Published var selection: Int?
    @Published var openFolder: ClipyMenuFolder?
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
        if mode != .snippets {
            let entries = sortedEntries
            let split = ClipyMenuBuilder.folders(
                entries: entries,
                inlineLimit: defaults.integer(forKey: DefaultsKey.clipyInlineLimit),
                folderLimit: defaults.integer(forKey: DefaultsKey.clipyFolderLimit))
            if !entries.isEmpty {
                rows.append(.header(strings.historySection))
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
        if mode != .history {
            let allSnippets = Self.loadSnippets()
            let snippets = service.snippetFolderFilter.map { folder in
                allSnippets.filter { $0.folder == folder }
            } ?? allSnippets
            if !snippets.isEmpty {
                rows.append(.header(strings.snippetsSection))
                for folder in Self.snippetFolders(snippets) {
                    if !folder.name.isEmpty {
                        rows.append(.header(folder.name))
                    }
                    for snippet in folder.snippets {
                        rows.append(.snippet(snippet, number))
                        number += 1
                    }
                }
            }
        }
        return rows
    }

    var actionableRows: [ClipyMenuRow] {
        rootRows.filter(\.isActionable)
    }

    var folderRows: [ClipyEntry] {
        openFolder?.entries ?? []
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
        let rows = folderRows
        guard !rows.isEmpty else { folderSelection = nil; return }
        let current = folderSelection ?? 0
        folderSelection = min(max(current + delta, 0), rows.count - 1)
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
            openFolder = folder
            folderSelection = folder.entries.isEmpty ? nil : 0
        case .snippet(let snippet, _):
            service.pasteText(snippet.content)
        }
    }

    func activateFolderSelection() {
        guard let folderSelection, folderRows.indices.contains(folderSelection) else { return }
        service.paste(folderRows[folderSelection])
    }

    func openSelectedFolder() {
        guard let selection, actionableRows.indices.contains(selection) else { return }
        if case .folder(let folder, _) = actionableRows[selection] {
            openFolder = folder
            folderSelection = folder.entries.isEmpty ? nil : 0
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

    private struct SnippetFolder {
        let name: String
        let snippets: [ClipySnippet]
    }

    private static func snippetFolders(_ snippets: [ClipySnippet]) -> [SnippetFolder] {
        let visible = snippets.filter(\.enabled)
        var groups: [String: [ClipySnippet]] = [:]
        for snippet in visible {
            groups[snippet.folder, default: []].append(snippet)
        }
        var folders = groups.filter { !$0.key.isEmpty }
            .sorted { $0.key.localizedStandardCompare($1.key) == .orderedAscending }
            .map { SnippetFolder(name: $0.key, snippets: $0.value) }
        if let loose = groups[""], !loose.isEmpty {
            folders.append(SnippetFolder(name: "", snippets: loose))
        }
        return folders
    }

    static func loadSnippets() -> [ClipySnippet] {
        guard let data = UserDefaults.standard.data(forKey: DefaultsKey.clipySnippets) else {
            return []
        }
        return (try? JSONDecoder().decode([ClipySnippet].self, from: data)) ?? []
    }
}