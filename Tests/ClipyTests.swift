// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import AppKit
import Foundation

/// The independent Clipy feature's pure contracts: menu grouping, numbering,
/// color parsing and its own history store.
enum ClipyTests {
    static func run(_ suite: TestSuite) {
        let entries = (1...25).map { number in
            ClipyEntry(primaryType: NSPasteboard.PasteboardType.string.rawValue,
                       preview: "\(number)",
                       representationTypes: [],
                       contentHash: "\(number)")
        }

        let split = ClipyMenuBuilder.folders(entries: entries,
                                             inlineLimit: 10,
                                             folderLimit: 5)
        suite.expect(split.inline.count == 10
                     && split.folders.map(\.start) == [11, 16, 21]
                     && split.folders.map(\.end) == [15, 20, 25],
                     "history splits into the inline tail and fixed-size overflow folders")

        let allFolders = ClipyMenuBuilder.folders(entries: entries,
                                                  inlineLimit: 0,
                                                  folderLimit: 10)
        suite.expect(allFolders.inline.isEmpty
                     && allFolders.folders.map(\.start) == [1, 11, 21],
                     "a zero inline limit puts every item into folders")

        suite.expect(ClipyTitle.shortened("a\nb\tc", limit: 3) == "a b…",
                     "menu titles collapse line breaks and cut at the limit")
        suite.expect(ClipyTitle.shortened("short", limit: 20) == "short",
                     "a short title is left alone")

        suite.expect(ClipyMenuBuilder.digitIndex(for: 18) == 0
                     && ClipyMenuBuilder.digitIndex(for: 29) == 9
                     && ClipyMenuBuilder.digitIndex(for: 0) == nil,
                     "the number row maps 1–9 and 0 to the first ten items")

        let red = ClipyColor.color(from: "#FF0000", allowsWithoutHash: false, allowsNamed: false)
        let redComponents = red?.usingColorSpace(.sRGB)
        suite.expect(redComponents?.redComponent ?? 0 > 0.99
                     && redComponents?.greenComponent ?? 1 < 0.01
                     && redComponents?.blueComponent ?? 1 < 0.01,
                     "a hex color becomes a red swatch")
        suite.expect(ClipyColor.color(from: "FF0000", allowsWithoutHash: false, allowsNamed: false) == nil
                     && ClipyColor.color(from: "FF0000", allowsWithoutHash: true, allowsNamed: false) != nil,
                     "a bare hex color is accepted only when that option is on")
        suite.expect(ClipyColor.color(from: "rebeccapurple", allowsWithoutHash: true, allowsNamed: false) == nil
                     && ClipyColor.color(from: "red", allowsWithoutHash: true, allowsNamed: true) != nil,
                     "named colors are accepted only when CSS names are on")

        suite.expect(ClipyCaptureType.allCases.count == 8
                     && Set(ClipyCaptureType.allCases.map(\.defaultsKey)).count == 8,
                     "the eight capture types keep distinct preference keys")

        let pasteboard = NSPasteboard.withUniqueName()
        pasteboard.clearContents()
        pasteboard.setString("hello", forType: .string)
        let captured = ClipyCapture.read(from: pasteboard,
                                         enabled: [.plainText],
                                         sourceBundleID: "com.example.test")
        suite.expect(captured?.preview == "hello"
                     && captured?.primaryType == NSPasteboard.PasteboardType.string.rawValue
                     && captured?.representations[NSPasteboard.PasteboardType.string.rawValue]
                        == Data("hello".utf8),
                     "plain-text capture keeps the text and its preview")

        let writeEntry = ClipyEntry(primaryType: NSPasteboard.PasteboardType.string.rawValue,
                                    preview: "hello",
                                    representationTypes: [NSPasteboard.PasteboardType.string.rawValue],
                                    contentHash: "hash")
        suite.expect(ClipyCapture.write(
            writeEntry,
            representations: [NSPasteboard.PasteboardType.string.rawValue: Data("hello".utf8)],
            to: pasteboard)
                     && pasteboard.string(forType: .string) == "hello",
                     "writing a Clipy entry restores the plain text on the pasteboard")

        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("clipy-tests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = ClipyStore(rootURL: root)
        let type = NSPasteboard.PasteboardType.string.rawValue
        let entry = ClipyEntry(primaryType: type,
                               preview: "hello",
                               representationTypes: [type],
                               contentHash: "hash")
        let data = Data("hello".utf8)
        suite.expect(store.write(entry, representations: [type: data]),
                     "the store accepts a plain-text representation")
        store.save([entry])
        let loaded = store.load()
        suite.expect(loaded.count == 1
                     && loaded.first?.id == entry.id
                     && loaded.first?.preview == "hello",
                     "the history index round-trips")
        suite.expect(store.data(for: entry, type: type) == data,
                     "the blob round-trips byte for byte")
        store.delete(entry)
        suite.expect(store.load().isEmpty,
                     "deleting an entry removes its index row and blobs")
    }
}