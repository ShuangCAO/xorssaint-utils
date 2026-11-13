// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import AppKit
import SwiftUI

/// The compact clipboard panel: clipboard history and snippets share one
/// list, with the scope control narrowing it to either half. It replaces the
/// old resizable window and its separate preview sidebar.
struct ClipboardCompactPanelView: View {
    static let preferredSize = ClipboardHistoryWindowSizing.compactPanelSize
    private static let historyLimitInAllScope = 8

    @ObservedObject private var l10n = L10n.shared
    @ObservedObject private var history = ClipboardHistoryService.shared
    @ObservedObject private var snippets = SnippetLibraryService.shared
    @ObservedObject private var features = FeatureRuntime.shared
    @AppStorage(DefaultsKey.clipboardHistoryShowSourceAppIcons) private var showSourceAppIcons = false
    @FocusState private var searchFocused: Bool
    @State private var scope: ClipboardCompactScope = .all
    @State private var query = ""
    @State private var collapsedFolders: Set<String> = []
    @State private var hoveredRow: String?
    @State private var clearingIDs: [UUID: Date]?

    private var text: ClipboardFeatureStrings {
        FeatureStrings.clipboard(l10n.language)
    }

    private var snippetsAvailable: Bool {
        features.isAvailable(.textSnippets)
    }

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 1) {
                        historyContent
                        if snippetsAvailable, scope != .history {
                            snippetsContent
                        }
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                }
                .onChange(of: history.quickSelectionID) { _, id in
                    guard let id else { return }
                    withAnimation(.easeOut(duration: 0.12)) {
                        proxy.scrollTo(id, anchor: .center)
                    }
                }
                .onChange(of: snippets.selectedID) { _, id in
                    guard let id else { return }
                    withAnimation(.easeOut(duration: 0.12)) {
                        proxy.scrollTo(id, anchor: .center)
                    }
                }
            }
            Divider()
            footer
        }
        .frame(width: Self.preferredSize.width, height: Self.preferredSize.height)
        .background(.regularMaterial)
        .onAppear(perform: prepare)
        .onChange(of: history.quickWindowPresentationID) { _, _ in prepare() }
        .onChange(of: query) { _, value in
            history.quickQuery = value
            snippets.query = value
        }
        .onChange(of: scope) { _, value in
            history.hubScope = value
            if value == .snippets {
                snippets.prepareForHub()
                snippets.query = query
            }
        }
        .onChange(of: snippetsAvailable) { _, available in
            if !available, scope == .snippets { scope = .all }
        }
    }

    // MARK: - Header

    private var toolbar: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                TextField(text.search, text: $query)
                    .textFieldStyle(.roundedBorder)
                    .focused($searchFocused)
                Button {
                    history.hideHistoryWindow()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10.5, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 22, height: 22)
                }
                .buttonStyle(.plain)
                .help(l10n.s.menuClose)
                .accessibilityLabel(l10n.s.menuClose)
            }
            Picker("", selection: $scope) {
                Text(text.scopeAll).tag(ClipboardCompactScope.all)
                Text(text.historyTab).tag(ClipboardCompactScope.history)
                if snippetsAvailable {
                    Text(text.snippetsTab).tag(ClipboardCompactScope.snippets)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
        }
        .padding(.horizontal, 12)
        .padding(.top, 9)
        .padding(.bottom, 7)
    }

    // MARK: - History

    @ViewBuilder
    private var historyContent: some View {
        let filtered = history.filteredQuickEntries
        let pinned = filtered.filter(\.isPinned)
        let recent = filtered.filter { !$0.isPinned }
        let limit = scope == .all ? Self.historyLimitInAllScope : Int.max
        let shownPinned = Array(pinned.prefix(limit))
        let shownRecent = Array(recent.prefix(max(0, limit - shownPinned.count)))
        let hidden = filtered.count - shownPinned.count - shownRecent.count

        if !shownPinned.isEmpty {
            sectionHeader(text.pinned)
            ForEach(Array(shownPinned.enumerated()), id: \.element.id) { index, entry in
                historyRow(entry, number: index + 1)
                    .id(entry.id)
            }
        }
        if !shownRecent.isEmpty {
            if !shownPinned.isEmpty { sectionHeader(text.recent) }
            ForEach(Array(shownRecent.enumerated()), id: \.element.id) { index, entry in
                historyRow(entry, number: shownPinned.count + index + 1)
                    .id(entry.id)
            }
        }
        if hidden > 0 {
            Button {
                scope = .history
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "chevron.down")
                    Text("\(text.viewAllHistory) (\(hidden))")
                }
                .font(.system(size: 10.5, weight: .medium))
                .foregroundStyle(Color.accentColor)
                .padding(.horizontal, 8)
                .frame(height: 26)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        if filtered.isEmpty, scope != .snippets,
           scope == .history || snippets.sections.isEmpty {
            emptyRow(text.empty, symbol: "doc.on.clipboard")
        }
    }

    private func historyRow(_ entry: ClipboardHistoryEntry, number: Int) -> some View {
        let rowID = "h-\(entry.id.uuidString)"
        let isSelected = history.quickSelectionIsVisible
            && history.selectedQuickEntryID == entry.id
        let isBatch = history.isQuickBatchSelected(entry)
        return HStack(spacing: 7) {
            numberBadge(number)
            Image(systemName: kindSymbol(entry.kind))
                .font(.system(size: 10.5, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 15)
            if showSourceAppIcons, let app = sourceApp(for: entry) {
                Image(nsImage: app.icon)
                    .resizable()
                    .frame(width: 14, height: 14)
                    .help(app.name)
            }
            Text(entry.preview)
                .font(.system(size: 11.5))
                .lineLimit(1)
                .truncationMode(.tail)
            Spacer(minLength: 6)
            if entry.isPinned {
                Image(systemName: "pin.fill")
                    .font(.system(size: 8.5))
                    .foregroundStyle(.tertiary)
            }
            Text(entry.copiedAt, style: .time)
                .font(.system(size: 9.5, design: .monospaced))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 7)
        .frame(height: 30)
        .background(rowFill(isSelected: isSelected, isBatch: isBatch,
                            hovered: hoveredRow == rowID))
        .contentShape(Rectangle())
        .onHover { hoveredRow = $0 ? rowID : (hoveredRow == rowID ? nil : hoveredRow) }
        .onTapGesture {
            if NSEvent.modifierFlags.contains(.command) {
                history.toggleQuickBatchSelection(entry)
            } else {
                history.copyQuickEntry(entry)
            }
        }
        .contextMenu {
            Button(entry.isPinned ? text.unpin : text.pin) { history.togglePin(entry) }
            Button(text.copy) { history.copy(entry) { _ in } }
            Divider()
            Button(text.delete, role: .destructive) { history.remove(entry) }
        }
    }

    // MARK: - Snippets

    @ViewBuilder
    private var snippetsContent: some View {
        let sections = snippets.sections
        if sections.isEmpty {
            if scope == .snippets {
                emptyRow(text.noResults, symbol: "text.append")
            }
        } else {
            if scope == .all { sectionHeader(text.snippetsTab) }
            ForEach(sections, id: \.folder) { section in
                if !section.folder.isEmpty {
                    folderHeader(section)
                }
                if section.folder.isEmpty || !collapsedFolders.contains(section.folder) {
                    ForEach(section.snippets) { snippet in
                        snippetRow(snippet, number: snippetNumber(snippet))
                            .id(snippet.id)
                    }
                }
            }
        }
    }

    private func snippetRow(_ snippet: TextSnippet, number: Int?) -> some View {
        let rowID = "s-\(snippet.id.uuidString)"
        let isSelected = snippets.selectedID == snippet.id
        return HStack(spacing: 7) {
            if let number {
                numberBadge(number)
            } else {
                Spacer().frame(width: 13)
            }
            Image(systemName: "text.append")
                .font(.system(size: 10.5, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 15)
            VStack(alignment: .leading, spacing: 0) {
                Text(displayName(snippet))
                    .font(.system(size: 11.5))
                    .lineLimit(1)
                Text(previewText(snippet))
                    .font(.system(size: 9.5))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 6)
            if !snippet.trigger.isEmpty {
                Text(snippet.trigger)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 7)
        .frame(height: 32)
        .background(rowFill(isSelected: isSelected, isBatch: false,
                            hovered: hoveredRow == rowID))
        .contentShape(Rectangle())
        .onHover { hoveredRow = $0 ? rowID : (hoveredRow == rowID ? nil : hoveredRow) }
        .onTapGesture { insert(snippet) }
        .contextMenu {
            Button(text.edit) { openSettings(.textSnippets) }
        }
    }

    private func folderHeader(_ section: TextSnippetSupport.LibrarySection) -> some View {
        let collapsed = collapsedFolders.contains(section.folder)
        return Button {
            if collapsed {
                collapsedFolders.remove(section.folder)
            } else {
                collapsedFolders.insert(section.folder)
            }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: collapsed ? "chevron.right" : "chevron.down")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(.tertiary)
                Text(section.folder)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Spacer()
                Text("\(section.snippets.count)")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 8)
            .frame(height: 22)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func snippetNumber(_ snippet: TextSnippet) -> Int? {
        guard scope == .snippets, collapsedFolders.isEmpty,
              let index = snippets.rows.firstIndex(of: snippet) else { return nil }
        return index + 1
    }

    private func displayName(_ snippet: TextSnippet) -> String {
        if !snippet.name.isEmpty { return snippet.name }
        if !snippet.trigger.isEmpty { return snippet.trigger }
        return previewText(snippet)
    }

    private func previewText(_ snippet: TextSnippet) -> String {
        let collapsed = snippet.replacement
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\t", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return String(collapsed.prefix(120))
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: 8) {
            if history.quickBatchCount > 0 {
                Button(String(format: text.pasteSelectedFormat, history.quickBatchCount)) {
                    history.copySelectedQuickEntry()
                }
                Button(String(format: text.deleteSelectedFormat, history.quickBatchCount),
                       role: .destructive) {
                    history.removeSelectedQuickEntries()
                }
                Button(text.clearSelection) {
                    history.clearQuickBatchSelection()
                }
                Spacer(minLength: 4)
            } else {
                Button {
                    openSettings(scope == .snippets ? .textSnippets : .clipboard)
                } label: {
                    Image(systemName: "gearshape")
                }
                .help(l10n.s.panelSettings)
                .accessibilityLabel(l10n.s.panelSettings)

                Button {
                    clearingIDs = history.recentEntriesSnapshot
                } label: {
                    Label(text.clearRecent, systemImage: "trash")
                }
                .disabled(history.recentEntries.isEmpty)
                .modifier(ClipboardClearRecentConfirmation(entryIDs: $clearingIDs))

                Spacer(minLength: 4)
                Text("\(history.entries.count)")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(.tertiary)
            }
        }
        .controlSize(.small)
        .lineLimit(1)
        .minimumScaleFactor(0.78)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: - Rows

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 9, weight: .semibold))
            .foregroundStyle(.secondary)
            .tracking(0.5)
            .padding(.horizontal, 8)
            .padding(.top, 6)
            .padding(.bottom, 2)
    }

    private func emptyRow(_ message: String, symbol: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: symbol)
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
            Text(message)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 10)
    }

    private func numberBadge(_ number: Int) -> some View {
        Text(number <= 9 ? "\(number)" : "")
            .font(.system(size: 9, weight: .semibold, design: .monospaced))
            .foregroundStyle(.tertiary)
            .frame(width: 13, alignment: .trailing)
    }

    private func rowFill(isSelected: Bool, isBatch: Bool, hovered: Bool) -> some View {
        RoundedRectangle(cornerRadius: 6, style: .continuous)
            .fill(isBatch ? Color.accentColor.opacity(0.16)
                  : isSelected ? Color.accentColor.opacity(0.12)
                  : hovered ? Color.primary.opacity(0.05) : Color.clear)
    }

    private func kindSymbol(_ kind: ClipboardHistoryEntryKind) -> String {
        switch kind {
        case .text: return "text.alignleft"
        case .image: return "photo"
        case .files: return "doc"
        }
    }

    private func sourceApp(for entry: ClipboardHistoryEntry) -> (name: String, icon: NSImage)? {
        guard let bundleID = entry.sourceBundleID,
              let url = InstalledApps.url(for: bundleID) else { return nil }
        return (InstalledApps.name(for: bundleID),
                NSWorkspace.shared.icon(forFile: url.path))
    }

    // MARK: - Actions

    private func prepare() {
        history.hubScope = .all
        scope = .all
        query = ""
        history.quickQuery = ""
        snippets.prepareForHub()
        snippets.query = ""
        DispatchQueue.main.async { searchFocused = true }
    }

    private func insert(_ snippet: TextSnippet) {
        history.hideHistoryWindow()
        snippets.insert(snippet)
    }

    private func openSettings(_ page: SettingsPage) {
        SettingsRouter.shared.page = page
        appDelegate()?.openSettingsWindow()
    }
}