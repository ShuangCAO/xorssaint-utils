// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import SwiftUI

/// Settings for the independent Clipy clipboard menu.
struct ClipySettings: View {
    @ObservedObject private var l10n = L10n.shared
    @AppStorage(DefaultsKey.clipyEnabled) private var enabled = true
    @AppStorage(DefaultsKey.clipyAutoPaste) private var autoPaste = true
    @AppStorage(DefaultsKey.clipyHistoryLimit) private var historyLimit = 100
    @AppStorage(DefaultsKey.clipySortByLastUsed) private var sortByLastUsed = false
    @AppStorage(DefaultsKey.clipyAllowDuplicates) private var allowDuplicates = false
    @AppStorage(DefaultsKey.clipyOverwriteDuplicates) private var overwriteDuplicates = true
    @AppStorage(DefaultsKey.clipyInlineLimit) private var inlineLimit = 10
    @AppStorage(DefaultsKey.clipyFolderLimit) private var folderLimit = 10
    @AppStorage(DefaultsKey.clipyTitleLength) private var titleLength = 60
    @AppStorage(DefaultsKey.clipyMarksNumbers) private var marksNumbers = true
    @AppStorage(DefaultsKey.clipyStartsAtZero) private var startsAtZero = false
    @AppStorage(DefaultsKey.clipyNumericShortcuts) private var numericShortcuts = true
    @AppStorage(DefaultsKey.clipyHighlightFirst) private var highlightFirst = true
    @AppStorage(DefaultsKey.clipyShowImages) private var showImages = true
    @AppStorage(DefaultsKey.clipyThumbnailWidth) private var thumbnailWidth = 40
    @AppStorage(DefaultsKey.clipyThumbnailHeight) private var thumbnailHeight = 30
    @AppStorage(DefaultsKey.clipyShowColorPreview) private var showColorPreview = true
    @AppStorage(DefaultsKey.clipyParseColorsWithoutHash) private var parseWithoutHash = true
    @AppStorage(DefaultsKey.clipyParseCSSNamedColors) private var parseCSS = true
    @AppStorage(DefaultsKey.clipyCapturePlainText) private var capturePlainText = true
    @AppStorage(DefaultsKey.clipyCaptureRTF) private var captureRTF = false
    @AppStorage(DefaultsKey.clipyCaptureRTFD) private var captureRTFD = false
    @AppStorage(DefaultsKey.clipyCapturePDF) private var capturePDF = false
    @AppStorage(DefaultsKey.clipyCaptureFiles) private var captureFiles = false
    @AppStorage(DefaultsKey.clipyCaptureURL) private var captureURL = false
    @AppStorage(DefaultsKey.clipyCaptureImages) private var captureImages = false
    @AppStorage(DefaultsKey.clipyCaptureHTML) private var captureHTML = false
    @ObservedObject private var service = ClipyService.shared
    @State private var editingSnippets = false
    @State private var folders: [String] = []
    @State private var folderShortcuts: [String: String] = [:]

    private var text: ClipyStrings { FeatureStrings.clipy(l10n.language) }

    var body: some View {
        Form {
            Section {
                Toggle(text.enabled, isOn: $enabled)
                Toggle(text.autoPaste, isOn: $autoPaste)
                ClipyNumberRow(title: text.historyLimit,
                               value: $historyLimit,
                               range: 1...1000)
                Picker(text.sort, selection: $sortByLastUsed) {
                    Text(text.sortCreated).tag(false)
                    Text(text.sortLastUsed).tag(true)
                }
                Toggle(text.allowDuplicates, isOn: $allowDuplicates)
                Toggle(text.overwriteDuplicates, isOn: $overwriteDuplicates)
                    .disabled(!allowDuplicates)
            } header: {
                Text(text.general)
            }

            Section {
                typeToggle(text.typePlainText, $capturePlainText)
                typeToggle(text.typeRTF, $captureRTF)
                typeToggle(text.typeRTFD, $captureRTFD)
                typeToggle(text.typePDF, $capturePDF)
                typeToggle(text.typeFiles, $captureFiles)
                typeToggle(text.typeURL, $captureURL)
                typeToggle(text.typeImages, $captureImages)
                typeToggle(text.typeHTML, $captureHTML)
            } header: {
                Text(text.types)
            }

            Section {
                ClipyNumberRow(title: text.inlineLimit, value: $inlineLimit, range: 0...100)
                ClipyNumberRow(title: text.folderLimit, value: $folderLimit, range: 1...100)
                ClipyNumberRow(title: text.titleLength, value: $titleLength, range: 1...1000)
                Toggle(text.showNumbers, isOn: $marksNumbers)
                Toggle(text.startAtZero, isOn: $startsAtZero)
                    .disabled(!marksNumbers)
                Toggle(text.numericShortcuts, isOn: $numericShortcuts)
                Toggle(text.highlightFirst, isOn: $highlightFirst)
                Toggle(text.showImages, isOn: $showImages)
                ClipyNumberRow(title: text.thumbnailWidth, value: $thumbnailWidth, range: 1...512)
                    .disabled(!showImages)
                ClipyNumberRow(title: text.thumbnailHeight, value: $thumbnailHeight, range: 1...512)
                    .disabled(!showImages)
                Toggle(text.colorPreview, isOn: $showColorPreview)
                Toggle(text.parseWithoutHash, isOn: $parseWithoutHash)
                    .disabled(!showColorPreview)
                Toggle(text.parseCSS, isOn: $parseCSS)
                    .disabled(!showColorPreview)
            } header: {
                Text(text.menu)
            }

            Section {
                shortcutRow(text.shortcutMain, key: DefaultsKey.clipyMainShortcut)
                if service.shortcutRegistrationFailed {
                    Text(l10n.s.shortcutUnavailable)
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            } header: {
                Text(text.shortcuts)
            }

            Section {
                Button(text.editSnippets) { editingSnippets = true }
                if folders.isEmpty {
                    Text(text.noSnippets)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text(text.snippets)
            }

            if !folders.isEmpty {
                Section {
                    ForEach(folders, id: \.self) { folder in
                        HStack {
                            Text(folder)
                            Spacer()
                            ShortcutRecorderButton(
                                shortcut: GlobalShortcut(
                                    storageValue: folderShortcuts[folder] ?? "") ?? .clipyFallback,
                                isEnabled: true,
                                waitingTitle: l10n.s.shortcutPressKeys,
                                emptyTitle: (folderShortcuts[folder] ?? "").isEmpty ? "—" : nil,
                                invalidAction: {},
                                captureAction: { shortcut in
                                    folderShortcuts[folder] = shortcut.storageValue
                                    ClipySnippetFolderShortcuts.save(folderShortcuts)
                                    service.syncWithPreferences()
                                }
                            )
                            .frame(width: 150, height: 24)
                        }
                    }
                } header: {
                    Text(text.folderShortcuts)
                }
            }

            Section {
                Button(text.clearHistory, role: .destructive) {
                    service.confirmClearHistory()
                }
                .disabled(service.entries.isEmpty)
            }
        }
        .formStyle(.grouped)
        .onAppear(perform: reloadFolders)
        .sheet(isPresented: $editingSnippets, onDismiss: reloadFolders) {
            ClipySnippetEditor()
        }
    }

    private func typeToggle(_ title: String, _ binding: Binding<Bool>) -> some View {
        Toggle(title, isOn: binding)
    }

    private func shortcutRow(_ title: String, key: String) -> some View {
        let raw = UserDefaults.standard.string(forKey: key) ?? ""
        return HStack {
            Text(title)
            Spacer()
            ShortcutRecorderButton(
                shortcut: GlobalShortcut(storageValue: raw) ?? .clipyFallback,
                isEnabled: true,
                waitingTitle: l10n.s.shortcutPressKeys,
                emptyTitle: raw.isEmpty ? "—" : nil,
                invalidAction: {},
                captureAction: { shortcut in
                    UserDefaults.standard.set(shortcut.storageValue, forKey: key)
                    service.syncWithPreferences()
                }
            )
            .frame(width: 150, height: 24)
        }
    }

    private func reloadFolders() {
        let store = ClipySnippetStore.load()
        folders = store.folders
        folderShortcuts = ClipySnippetFolderShortcuts.load()
        let active = Set(folders)
        let cleaned = folderShortcuts.filter { active.contains($0.key) }
        if cleaned != folderShortcuts {
            folderShortcuts = cleaned
            ClipySnippetFolderShortcuts.save(cleaned)
            service.syncWithPreferences()
        }
    }
}

private struct ClipyNumberRow: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>

    var body: some View {
        HStack(spacing: 8) {
            Text(title)
            Spacer()
            TextField("", value: $value, format: .number.grouping(.never))
                .textFieldStyle(.roundedBorder)
                .multilineTextAlignment(.trailing)
                .frame(width: 76)
                .accessibilityLabel(Text(title))
                .onChange(of: value) { _, newValue in
                    let clamped = min(max(newValue, range.lowerBound), range.upperBound)
                    if clamped != newValue { value = clamped }
                }
            Stepper("", value: $value, in: range)
                .labelsHidden()
        }
    }
}
