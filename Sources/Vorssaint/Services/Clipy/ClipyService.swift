// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import AppKit
import Carbon.HIToolbox
import Combine
import SwiftUI

enum ClipyMenuMode {
    case main
    case history
    case snippets
}

enum ClipyShortcutRole: CaseIterable {
    case main
    case history
    case snippets
    case editSnippets
    case clearHistory

    var defaultsKey: String {
        switch self {
        case .main: return DefaultsKey.clipyMainShortcut
        case .history: return DefaultsKey.clipyHistoryShortcut
        case .snippets: return DefaultsKey.clipySnippetsShortcut
        case .editSnippets: return DefaultsKey.clipyEditSnippetsShortcut
        case .clearHistory: return DefaultsKey.clipyClearHistoryShortcut
        }
    }

    var hotKeyID: UInt32 {
        switch self {
        case .main: return 400
        case .history: return 401
        case .snippets: return 402
        case .editSnippets: return 403
        case .clearHistory: return 404
        }
    }
}

enum ClipyRowIcon {
    case symbol(String)
    case image(NSImage)
    case color(NSColor)
}

/// The independent Clipy feature: its own pasteboard monitor, history store
/// and menu. Nothing here reads or writes Vorssaint's clipboard history.
final class ClipyService: ObservableObject {
    static let shared = ClipyService()

    @Published private(set) var entries: [ClipyEntry] = []
    @Published private(set) var shortcutRegistrationFailed = false

    private let store = ClipyStore()
    private var timer: Timer?
    private var lastChangeCount = NSPasteboard.general.changeCount
    private var ignoreChangeCount: Int?
    private var hotkeys: [ClipyShortcutRole: QuickToolHotkey] = [:]
    private var folderHotkeys: [String: QuickToolHotkey] = [:]
    private(set) var snippetFolderFilter: String?
    private var menuController: ClipyMenuController?
    private var defaultsObserver: NSObjectProtocol?
    private var syncScheduled = false
    private var isStarted = false
    private var pasteTarget: NSRunningApplication?
    private var promptedForAccessibility = false

    private init() {
        entries = store.load()
        defaultsObserver = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            self?.scheduleSync()
        }
        syncWithPreferences()
    }

    func syncWithPreferences() {
        guard AppFeature.clipy.isAvailable else {
            stop()
            return
        }
        let defaults = UserDefaults.standard
        let enabled = defaults.bool(forKey: DefaultsKey.clipyEnabled)
        if enabled {
            if !isStarted {
                lastChangeCount = NSPasteboard.general.changeCount
                isStarted = true
            }
            startTimer()
        } else {
            timer?.invalidate()
            timer = nil
            isStarted = false
        }
        // Turning capture off stops the monitor, not the menu: saved history
        // and snippets stay reachable through their shortcuts.
        syncHotkeys()
        syncFolderHotkeys()
    }

    func clearHistory() {
        store.clear()
        entries = []
    }

    func confirmClearHistory() {
        let text = FeatureStrings.clipboard(L10n.shared.language)
        let alert = NSAlert()
        alert.messageText = FeatureStrings.clipy(L10n.shared.language).clearHistory
        alert.addButton(withTitle: text.delete)
        alert.addButton(withTitle: text.cancel)
        NSApp.activate(ignoringOtherApps: true)
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        clearHistory()
    }

    func delete(_ entry: ClipyEntry) {
        store.delete(entry)
        entries.removeAll { $0.id == entry.id }
        store.save(entries)
    }

    func paste(_ entry: ClipyEntry) {
        guard let target = pasteTarget ?? NSWorkspace.shared.frontmostApplication else {
            return
        }
        let representations = entry.representationTypes.reduce(into: [String: Data]()) { result, type in
            if let data = store.data(for: entry, type: type) {
                result[type] = data
            }
        }
        guard !representations.isEmpty || entry.isFileEntry else { return }
        let pasteboard = NSPasteboard.general
        _ = ClipyCapture.write(entry, representations: representations, to: pasteboard)
        ignoreChangeCount = pasteboard.changeCount
        lastChangeCount = pasteboard.changeCount
        if let index = entries.firstIndex(where: { $0.id == entry.id }) {
            entries[index].lastUsedAt = Date()
            store.save(entries)
        }
        dismissMenu()
        guard UserDefaults.standard.bool(forKey: DefaultsKey.clipyAutoPaste) else { return }
        performAutoPaste(to: target)
        pasteTarget = nil
    }

    func pasteText(_ text: String) {
        let target = pasteTarget ?? NSWorkspace.shared.frontmostApplication
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        ignoreChangeCount = pasteboard.changeCount
        lastChangeCount = pasteboard.changeCount
        dismissMenu()
        guard UserDefaults.standard.bool(forKey: DefaultsKey.clipyAutoPaste) else { return }
        performAutoPaste(to: target)
    }

    private func performAutoPaste(to target: NSRunningApplication?) {
        guard let target else { return }
        target.activate(options: [])
        guard AXIsProcessTrusted() else {
            if promptedForAccessibility {
                NSSound.beep()
            } else {
                promptedForAccessibility = true
                Permissions.shared.requestAccessibility()
            }
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            Self.postPasteShortcut()
        }
    }

    func rowIcon(for entry: ClipyEntry) -> ClipyRowIcon {
        let defaults = UserDefaults.standard
        if defaults.bool(forKey: DefaultsKey.clipyShowColorPreview),
           let color = ClipyColor.color(
               from: entry.preview,
               allowsWithoutHash: defaults.bool(forKey: DefaultsKey.clipyParseColorsWithoutHash),
               allowsNamed: defaults.bool(forKey: DefaultsKey.clipyParseCSSNamedColors)) {
            return .color(color)
        }
        if entry.isImageEntry,
           defaults.bool(forKey: DefaultsKey.clipyShowImages),
           let data = store.data(for: entry, type: entry.primaryType),
           let image = NSImage(data: data) {
            return .image(image)
        }
        if let path = entry.filePaths?.first {
            return .image(NSWorkspace.shared.icon(forFile: path))
        }
        return .symbol(Self.symbol(for: entry.primaryType))
    }

    private static func symbol(for type: String) -> String {
        switch type {
        case NSPasteboard.PasteboardType.string.rawValue: return "text.alignleft"
        case NSPasteboard.PasteboardType.rtf.rawValue,
             NSPasteboard.PasteboardType.rtfd.rawValue: return "textformat"
        case NSPasteboard.PasteboardType.pdf.rawValue: return "doc.richtext"
        case NSPasteboard.PasteboardType.fileURL.rawValue: return "doc"
        case NSPasteboard.PasteboardType.URL.rawValue: return "link"
        case NSPasteboard.PasteboardType.tiff.rawValue,
             NSPasteboard.PasteboardType.png.rawValue: return "photo"
        case NSPasteboard.PasteboardType.html.rawValue:
            return "chevron.left.forwardslash.chevron.right"
        default: return "doc.on.clipboard"
        }
    }

    func showMenu(_ mode: ClipyMenuMode, snippetFolder: String? = nil) {
        guard AppFeature.clipy.isAvailable else { return }
        if menuController != nil { dismissMenu() }
        snippetFolderFilter = snippetFolder
        if let app = NSWorkspace.shared.frontmostApplication,
           app.bundleIdentifier != Bundle.main.bundleIdentifier {
            pasteTarget = app
        } else {
            pasteTarget = nil
        }
        let controller = ClipyMenuController(service: self, mode: mode)
        menuController = controller
        controller.show()
    }

    func dismissMenu() {
        menuController?.dismiss()
        menuController = nil
        pasteTarget = nil
        snippetFolderFilter = nil
    }

    func editSnippets() {
        dismissMenu()
        SettingsRouter.shared.page = .clipy
        appDelegate()?.openSettingsWindow()
    }

    // MARK: - Capture

    private func startTimer() {
        guard timer == nil else { return }
        let timer = Timer(timeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.captureIfChanged() }
        }
        timer.tolerance = 0.15
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    private func stop() {
        timer?.invalidate()
        timer = nil
        unregisterHotkeys()
        unregisterFolderHotkeys()
        dismissMenu()
        isStarted = false
    }

    private func captureIfChanged() {
        guard AppFeature.clipy.isAvailable,
              UserDefaults.standard.bool(forKey: DefaultsKey.clipyEnabled) else { return }
        let pasteboard = NSPasteboard.general
        let changeCount = pasteboard.changeCount
        guard changeCount != lastChangeCount else { return }
        lastChangeCount = changeCount
        if changeCount == ignoreChangeCount {
            ignoreChangeCount = nil
            return
        }
        let enabled = ClipyCaptureType.enabled()
        guard !enabled.isEmpty,
              let captured = ClipyCapture.read(from: pasteboard,
                                               enabled: enabled,
                                               sourceBundleID: NSWorkspace.shared.frontmostApplication?
                                                .bundleIdentifier)
        else { return }
        let defaults = UserDefaults.standard
        let allowDuplicates = defaults.bool(forKey: DefaultsKey.clipyAllowDuplicates)
        let overwrite = defaults.bool(forKey: DefaultsKey.clipyOverwriteDuplicates)
        if !allowDuplicates,
           let existing = entries.first(where: { $0.contentHash == captured.contentHash }) {
            guard overwrite else { return }
            var updated = existing
            updated.createdAt = Date()
            updated.lastUsedAt = Date()
            updated.preview = captured.preview
            updated.primaryType = captured.primaryType
            updated.representationTypes = captured.representations.keys.sorted()
            updated.imageWidth = captured.imageWidth
            updated.imageHeight = captured.imageHeight
            updated.filePaths = captured.filePaths
            updated.sourceBundleID = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
            _ = store.write(updated, representations: captured.representations)
            entries.removeAll { $0.id == existing.id }
            entries.insert(updated, at: 0)
            store.save(entries)
            return
        }
        let entry = ClipyEntry(primaryType: captured.primaryType,
                               preview: captured.preview,
                               representationTypes: captured.representations.keys.sorted(),
                               imageWidth: captured.imageWidth,
                               imageHeight: captured.imageHeight,
                               filePaths: captured.filePaths,
                               contentHash: captured.contentHash)
        guard store.write(entry, representations: captured.representations) else { return }
        entries.insert(entry, at: 0)
        entries = store.pruned(entries,
                               limit: defaults.integer(forKey: DefaultsKey.clipyHistoryLimit),
                               sort: ClipySortOrder.current())
        store.save(entries)
    }

    // MARK: - Shortcuts

    private func syncHotkeys() {
        var failed = false
        for role in ClipyShortcutRole.allCases {
            let raw = UserDefaults.standard.string(forKey: role.defaultsKey) ?? ""
            guard let shortcut = GlobalShortcut(storageValue: raw) else {
                hotkeys[role]?.sync(enabled: false,
                                    shortcut: GlobalShortcut.clipyFallback,
                                    storageKey: role.defaultsKey)
                continue
            }
            let hotkey = hotkeys[role] ?? QuickToolHotkey(id: role.hotKeyID)
            hotkey.onPress = { [weak self] in
                Task { @MainActor in
                    switch role {
                    case .main: self?.showMenu(.main)
                    case .history: self?.showMenu(.history)
                    case .snippets: self?.showMenu(.snippets)
                    case .editSnippets: self?.editSnippets()
                    case .clearHistory: self?.clearHistory()
                    }
                }
            }
            hotkeys[role] = hotkey
            if !hotkey.sync(enabled: true, shortcut: shortcut, storageKey: role.defaultsKey) {
                failed = true
            }
        }
        shortcutRegistrationFailed = failed
    }

    private func unregisterHotkeys() {
        for hotkey in hotkeys.values {
            hotkey.sync(enabled: false,
                        shortcut: GlobalShortcut.clipyFallback,
                        storageKey: "")
        }
        hotkeys.removeAll()
        shortcutRegistrationFailed = false
    }

    private func syncFolderHotkeys() {
        let snippets = (try? JSONDecoder().decode(
            [ClipySnippet].self,
            from: UserDefaults.standard.data(forKey: DefaultsKey.clipySnippets) ?? Data())) ?? []
        let activeFolders = Set(snippets.map(\.folder).filter { !$0.isEmpty })
        let shortcuts = ClipySnippetFolderShortcuts.load()
            .filter { activeFolders.contains($0.key) }

        for (folder, hotkey) in folderHotkeys where shortcuts[folder] == nil {
            hotkey.sync(enabled: false,
                        shortcut: GlobalShortcut.clipyFallback,
                        storageKey: "")
            folderHotkeys.removeValue(forKey: folder)
        }

        var failed = false
        for (index, folder) in shortcuts.keys.sorted().enumerated() {
            guard let shortcut = GlobalShortcut(storageValue: shortcuts[folder] ?? "") else { continue }
            let hotkey = folderHotkeys[folder] ?? QuickToolHotkey(id: 410 + UInt32(index))
            hotkey.onPress = { [weak self] in
                self?.showMenu(.snippets, snippetFolder: folder)
            }
            folderHotkeys[folder] = hotkey
            if !hotkey.sync(enabled: true, shortcut: shortcut,
                            storageKey: DefaultsKey.clipySnippetFolderShortcuts + "." + folder) {
                failed = true
            }
        }
        if failed { shortcutRegistrationFailed = true }
    }

    private func unregisterFolderHotkeys() {
        for hotkey in folderHotkeys.values {
            hotkey.sync(enabled: false,
                        shortcut: GlobalShortcut.clipyFallback,
                        storageKey: "")
        }
        folderHotkeys.removeAll()
    }

    private func scheduleSync() {
        guard !syncScheduled else { return }
        syncScheduled = true
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.syncScheduled = false
            self.syncWithPreferences()
        }
    }

    // MARK: - Paste

    private static func postPasteShortcut() {
        guard let source = CGEventSource(stateID: .hidSystemState),
              let keyDown = CGEvent(keyboardEventSource: source,
                                    virtualKey: CGKeyCode(kVK_ANSI_V),
                                    keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source,
                                  virtualKey: CGKeyCode(kVK_ANSI_V),
                                  keyDown: false)
        else { return }
        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
    }
}

extension GlobalShortcut {
    /// A non-nil placeholder for rows that have no shortcut yet. It is never
    /// registered when the storage value is empty.
    static let clipyFallback = GlobalShortcut(keyCode: 9, modifiers: [.shift, .command])
}