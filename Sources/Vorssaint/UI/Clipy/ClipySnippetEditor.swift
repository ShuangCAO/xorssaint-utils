// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import SwiftUI

/// Edits snippet folders first, then the snippets inside the selected folder.
/// The root level has folders only; a snippet always belongs to one.
struct ClipySnippetEditor: View {
    @ObservedObject private var l10n = L10n.shared
    @Environment(\.dismiss) private var dismiss
    @State private var folders: [String]
    @State private var snippets: [ClipySnippet]
    @State private var selectedFolder: String?
    @State private var selectedSnippet: UUID?
    @State private var folderNameDraft = ""

    init() {
        let store = ClipySnippetStore.load()
        _folders = State(initialValue: store.folders)
        _snippets = State(initialValue: store.snippets)
        let first = store.folders.first
        _selectedFolder = State(initialValue: first)
        _selectedSnippet = State(initialValue: store.snippets.first { $0.folder == first }?.id)
    }

    private var text: ClipyStrings { FeatureStrings.clipy(l10n.language) }

    private var selectedSnippetIndex: Int? {
        guard let selectedSnippet else { return nil }
        return snippets.firstIndex { $0.id == selectedSnippet }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                folderList
                    .frame(width: 220)
                Divider()
                detail
            }
            Divider()
            HStack(spacing: 10) {
                Spacer()
                Button(text.cancel) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button(text.save) { save() }
                    .keyboardShortcut(.defaultAction)
            }
            .padding(12)
        }
        .frame(width: 720, height: 480)
        .onAppear { folderNameDraft = selectedFolder ?? "" }
        .onChange(of: selectedFolder) { _, folder in
            folderNameDraft = folder ?? ""
            selectedSnippet = snippets.first { $0.folder == folder }?.id
        }
    }

    private var folderList: some View {
        VStack(spacing: 0) {
            List(selection: $selectedFolder) {
                ForEach(folders, id: \.self) { folder in
                    HStack {
                        Text(folder)
                            .lineLimit(1)
                        Spacer()
                        Text("\(snippetCount(in: folder))")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                    .tag(folder)
                }
            }
            .listStyle(.inset)
            Divider()
            HStack(spacing: 6) {
                Button {
                    addFolder()
                } label: {
                    Image(systemName: "plus")
                }
                .help(text.addFolder)
                .accessibilityLabel(text.addFolder)
                Button {
                    deleteFolder()
                } label: {
                    Image(systemName: "minus")
                }
                .help(text.delete)
                .accessibilityLabel(text.delete)
                .disabled(selectedFolder == nil)
                Spacer()
            }
            .buttonStyle(.borderless)
            .padding(6)
        }
    }

    @ViewBuilder
    private var detail: some View {
        if let folder = selectedFolder {
            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    TextField(text.snippetFolder, text: $folderNameDraft)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit { renameSelectedFolder() }
                    Button(text.renameFolder) { renameSelectedFolder() }
                        .help(text.renameFolder)
                }
                .padding(12)
                Divider()
                HStack(spacing: 0) {
                    snippetList(folder: folder)
                        .frame(width: 210)
                    Divider()
                    snippetForm(folder: folder)
                }
            }
        } else {
            Text(text.selectFolder)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func snippetList(folder: String) -> some View {
        VStack(spacing: 0) {
            List(selection: $selectedSnippet) {
                ForEach(snippets.filter { $0.folder == folder }) { snippet in
                    Text(snippet.name.isEmpty ? text.snippetName : snippet.name)
                        .lineLimit(1)
                        .tag(snippet.id)
                }
            }
            .listStyle(.inset)
            Divider()
            HStack(spacing: 6) {
                Button {
                    addSnippet(to: folder)
                } label: {
                    Image(systemName: "plus")
                }
                .help(text.addSnippet)
                .accessibilityLabel(text.addSnippet)
                Button {
                    deleteSelectedSnippet()
                } label: {
                    Image(systemName: "minus")
                }
                .help(text.delete)
                .accessibilityLabel(text.delete)
                .disabled(selectedSnippet == nil)
                Spacer()
            }
            .buttonStyle(.borderless)
            .padding(6)
        }
    }

    @ViewBuilder
    private func snippetForm(folder: String) -> some View {
        if let index = selectedSnippetIndex {
            Form {
                TextField(text.snippetName, text: $snippets[index].name)
                Toggle(text.snippetEnabled, isOn: $snippets[index].enabled)
                Section(text.snippetContent) {
                    TextEditor(text: $snippets[index].content)
                        .font(.system(size: 12, design: .monospaced))
                        .frame(minHeight: 220)
                }
            }
            .formStyle(.grouped)
        } else {
            Text(text.noSnippets)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func snippetCount(in folder: String) -> Int {
        snippets.filter { $0.folder == folder }.count
    }

    private func addFolder() {
        var name = text.snippetFolder
        var suffix = 2
        while folders.contains(name) {
            name = "\(text.snippetFolder) \(suffix)"
            suffix += 1
        }
        folders.append(name)
        folders.sort { $0.localizedStandardCompare($1) == .orderedAscending }
        selectedFolder = name
        selectedSnippet = nil
        folderNameDraft = name
    }

    private func deleteFolder() {
        guard let folder = selectedFolder else { return }
        folders.removeAll { $0 == folder }
        snippets.removeAll { $0.folder == folder }
        var shortcuts = ClipySnippetFolderShortcuts.load()
        if shortcuts.removeValue(forKey: folder) != nil {
            ClipySnippetFolderShortcuts.save(shortcuts)
        }
        selectedFolder = folders.first
        selectedSnippet = nil
    }

    private func renameSelectedFolder() {
        guard let old = selectedFolder else { return }
        let name = folderNameDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, name != old, !folders.contains(name) else {
            folderNameDraft = old
            return
        }
        folders = folders.map { $0 == old ? name : $0 }
            .sorted { $0.localizedStandardCompare($1) == .orderedAscending }
        for index in snippets.indices where snippets[index].folder == old {
            snippets[index].folder = name
        }
        var shortcuts = ClipySnippetFolderShortcuts.load()
        if let value = shortcuts.removeValue(forKey: old) {
            shortcuts[name] = value
            ClipySnippetFolderShortcuts.save(shortcuts)
        }
        selectedFolder = name
        folderNameDraft = name
    }

    private func addSnippet(to folder: String) {
        let snippet = ClipySnippet(name: "", content: "", folder: folder)
        snippets.append(snippet)
        selectedSnippet = snippet.id
    }

    private func deleteSelectedSnippet() {
        guard let index = selectedSnippetIndex else { return }
        snippets.remove(at: index)
        selectedSnippet = nil
    }

    private func save() {
        ClipySnippetStore.save(folders: folders, snippets: snippets)
        ClipyService.shared.syncWithPreferences()
        dismiss()
    }
}