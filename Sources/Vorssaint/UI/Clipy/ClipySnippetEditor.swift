// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import SwiftUI

/// Edits the snippets the Clipy menu shows below history. Folders are plain
/// names carried by each snippet, the same shape the menu groups by.
struct ClipySnippetEditor: View {
    @ObservedObject private var l10n = L10n.shared
    @Environment(\.dismiss) private var dismiss
    @State private var snippets: [ClipySnippet]
    @State private var selection: UUID?

    init() {
        _snippets = State(initialValue: ClipyMenuModel.loadSnippets())
        _selection = State(initialValue: ClipyMenuModel.loadSnippets().first?.id)
    }

    private var text: ClipyStrings { FeatureStrings.clipy(l10n.language) }

    private var selectedIndex: Int? {
        guard let selection else { return nil }
        return snippets.firstIndex { $0.id == selection }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                snippetList
                    .frame(width: 220)
                Divider()
                editor
            }
            Divider()
            HStack(spacing: 10) {
                Button {
                    addSnippet()
                } label: {
                    Label(text.addSnippet, systemImage: "plus")
                }
                Button {
                    removeSelection()
                } label: {
                    Label(text.delete, systemImage: "minus")
                }
                .disabled(selection == nil)
                Spacer()
                Button(text.cancel) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button(text.save) { save() }
                    .keyboardShortcut(.defaultAction)
            }
            .padding(12)
        }
        .frame(width: 680, height: 440)
        .onAppear {
            if selection == nil { selection = snippets.first?.id }
        }
    }

    private var snippetList: some View {
        VStack(spacing: 0) {
            List(selection: $selection) {
                ForEach(snippets) { snippet in
                    VStack(alignment: .leading, spacing: 1) {
                        Text(snippet.name.isEmpty ? text.snippetName : snippet.name)
                            .lineLimit(1)
                        if !snippet.folder.isEmpty {
                            Text(snippet.folder)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .tag(snippet.id)
                }
            }
            .listStyle(.inset)
        }
    }

    @ViewBuilder
    private var editor: some View {
        if let index = selectedIndex {
            Form {
                TextField(text.snippetName, text: $snippets[index].name)
                TextField(text.snippetFolder, text: $snippets[index].folder)
                Toggle(text.snippetEnabled, isOn: $snippets[index].enabled)
                Section(text.snippetContent) {
                    TextEditor(text: $snippets[index].content)
                        .font(.system(size: 12, design: .monospaced))
                        .frame(minHeight: 200)
                }
            }
            .formStyle(.grouped)
        } else {
            Text(text.noSnippets)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func addSnippet() {
        let snippet = ClipySnippet(name: "", content: "")
        snippets.append(snippet)
        selection = snippet.id
    }

    private func removeSelection() {
        guard let index = selectedIndex else { return }
        let removed = snippets.remove(at: index)
        if selection == removed.id {
            selection = snippets.first?.id
        }
    }

    private func save() {
        let data = try? JSONEncoder().encode(snippets)
        UserDefaults.standard.set(data, forKey: DefaultsKey.clipySnippets)
        ClipyService.shared.syncWithPreferences()
        dismiss()
    }
}