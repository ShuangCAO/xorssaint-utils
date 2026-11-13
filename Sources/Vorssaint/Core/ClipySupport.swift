// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import AppKit
import CryptoKit
import Foundation

/// One pasteboard representation the independent Clipy feature can capture.
/// The cases map to the eight types the menu settings expose.
enum ClipyCaptureType: String, CaseIterable, Identifiable {
    case plainText
    case rtf
    case rtfd
    case pdf
    case files
    case url
    case image
    case html

    var id: String { rawValue }

    var pasteboardType: NSPasteboard.PasteboardType {
        switch self {
        case .plainText: return .string
        case .rtf: return .rtf
        case .rtfd: return .rtfd
        case .pdf: return .pdf
        case .files: return .fileURL
        case .url: return .URL
        case .image: return .tiff
        case .html: return .html
        }
    }

    /// The stored representation uses the pasteboard's own UTI so writing it
    /// back needs no translation table.
    var storageType: String { pasteboardType.rawValue }

    var defaultsKey: String {
        switch self {
        case .plainText: return DefaultsKey.clipyCapturePlainText
        case .rtf: return DefaultsKey.clipyCaptureRTF
        case .rtfd: return DefaultsKey.clipyCaptureRTFD
        case .pdf: return DefaultsKey.clipyCapturePDF
        case .files: return DefaultsKey.clipyCaptureFiles
        case .url: return DefaultsKey.clipyCaptureURL
        case .image: return DefaultsKey.clipyCaptureImages
        case .html: return DefaultsKey.clipyCaptureHTML
        }
    }

    /// Lower wins when a copy carries several types: text reads better than
    /// the HTML or RTF that came with it.
    var priority: Int {
        switch self {
        case .plainText: return 0
        case .url: return 1
        case .files: return 2
        case .image: return 3
        case .pdf: return 4
        case .html: return 5
        case .rtf: return 6
        case .rtfd: return 7
        }
    }

    static func enabled(in defaults: UserDefaults = .standard) -> Set<ClipyCaptureType> {
        Set(allCases.filter { defaults.bool(forKey: $0.defaultsKey) })
    }
}

/// One saved clipboard item. Content bytes live in a per-entry blob folder;
/// the index keeps only what the menu needs to draw a row.
struct ClipyEntry: Codable, Equatable, Identifiable {
    let id: UUID
    var createdAt: Date
    var lastUsedAt: Date
    var sourceBundleID: String?
    /// The representation used for the row's icon and preview.
    var primaryType: String
    var preview: String
    /// Every stored representation's UTI, including the primary one.
    var representationTypes: [String]
    var imageWidth: Int?
    var imageHeight: Int?
    /// Paths for a copied file set, kept out of the blob store because they
    /// belong to the Finder and may move.
    var filePaths: [String]?
    var contentHash: String

    init(id: UUID = UUID(),
         createdAt: Date = Date(),
         lastUsedAt: Date = Date(),
         sourceBundleID: String? = nil,
         primaryType: String,
         preview: String,
         representationTypes: [String],
         imageWidth: Int? = nil,
         imageHeight: Int? = nil,
         filePaths: [String]? = nil,
         contentHash: String) {
        self.id = id
        self.createdAt = createdAt
        self.lastUsedAt = lastUsedAt
        self.sourceBundleID = sourceBundleID
        self.primaryType = primaryType
        self.preview = preview
        self.representationTypes = representationTypes
        self.imageWidth = imageWidth
        self.imageHeight = imageHeight
        self.filePaths = filePaths
        self.contentHash = contentHash
    }

    var isFileEntry: Bool { filePaths?.isEmpty == false }
    var isImageEntry: Bool { primaryType == NSPasteboard.PasteboardType.tiff.rawValue
        || primaryType == NSPasteboard.PasteboardType.png.rawValue }
}

enum ClipySortOrder: String, CaseIterable {
    case created
    case lastUsed

    static func current(in defaults: UserDefaults = .standard) -> ClipySortOrder {
        defaults.bool(forKey: DefaultsKey.clipySortByLastUsed) ? .lastUsed : .created
    }
}

/// The user's snippets, grouped by a plain folder name. Folder names travel
/// inside each snippet, the same shape the rest of the app uses.
struct ClipySnippet: Codable, Equatable, Identifiable {
    var id = UUID()
    var name = ""
    var content = ""
    var folder = ""
    var enabled = true
}

/// Folder → shortcut storage for snippet folders. Kept beside the snippets so
/// the settings page and the service read the same map.
enum ClipySnippetFolderShortcuts {
    static func load(from defaults: UserDefaults = .standard) -> [String: String] {
        guard let data = defaults.data(forKey: DefaultsKey.clipySnippetFolderShortcuts),
              let map = try? JSONDecoder().decode([String: String].self, from: data) else {
            return [:]
        }
        return map.filter { !$0.key.isEmpty && !$0.value.isEmpty }
    }

    static func save(_ map: [String: String], to defaults: UserDefaults = .standard) {
        guard let data = try? JSONEncoder().encode(map) else { return }
        defaults.set(data, forKey: DefaultsKey.clipySnippetFolderShortcuts)
    }
}

enum ClipyTitle {
    /// A one-line menu title, collapsed to a single line and cut at the
    /// configured length.
    static func shortened(_ text: String, limit: Int) -> String {
        let collapsed = text
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\t", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard collapsed.count > limit else { return collapsed }
        return String(collapsed.prefix(limit)) + "…"
    }
}

/// Color-code preview for copied values. Hex forms and the common CSS names
/// are enough to draw the swatch the menu shows.
enum ClipyColor {
    static func color(from raw: String,
                      allowsWithoutHash: Bool,
                      allowsNamed: Bool) -> NSColor? {
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, text.count <= 32 else { return nil }
        if allowsNamed, let named = namedColors[text.lowercased()] {
            return named
        }
        var hex = text
        if hex.hasPrefix("#") {
            hex.removeFirst()
        } else if !allowsWithoutHash {
            return nil
        }
        guard [3, 4, 6, 8].contains(hex.count),
              hex.allSatisfy(\.isHexDigit) else { return nil }
        switch hex.count {
        case 3, 4:
            let expanded = hex.map { "\($0)\($0)" }.joined()
            return color(fromHex: expanded)
        default:
            return color(fromHex: hex)
        }
    }

    private static func color(fromHex hex: String) -> NSColor? {
        var value: UInt64 = 0
        guard Scanner(string: hex).scanHexInt64(&value) else { return nil }
        let red: UInt64
        let green: UInt64
        let blue: UInt64
        let alpha: UInt64
        switch hex.count {
        case 6:
            red = (value >> 16) & 0xFF
            green = (value >> 8) & 0xFF
            blue = value & 0xFF
            alpha = 0xFF
        case 8:
            red = (value >> 24) & 0xFF
            green = (value >> 16) & 0xFF
            blue = (value >> 8) & 0xFF
            alpha = value & 0xFF
        default:
            return nil
        }
        return NSColor(srgbRed: CGFloat(red) / 255,
                       green: CGFloat(green) / 255,
                       blue: CGFloat(blue) / 255,
                       alpha: CGFloat(alpha) / 255)
    }

    private static let namedColors: [String: NSColor] = [
        "black": .black, "white": .white, "red": .systemRed, "green": .systemGreen,
        "blue": .systemBlue, "yellow": .systemYellow, "orange": .systemOrange,
        "purple": .systemPurple, "pink": .systemPink, "gray": .systemGray,
        "grey": .systemGray, "brown": .brown, "cyan": .systemCyan,
        "magenta": .systemPink, "silver": NSColor(srgbRed: 0.75, green: 0.75, blue: 0.75, alpha: 1),
        "maroon": NSColor(srgbRed: 0.5, green: 0, blue: 0, alpha: 1),
        "olive": NSColor(srgbRed: 0.5, green: 0.5, blue: 0, alpha: 1),
        "lime": NSColor(srgbRed: 0, green: 1, blue: 0, alpha: 1),
        "teal": NSColor(srgbRed: 0, green: 0.5, blue: 0.5, alpha: 1),
        "navy": NSColor(srgbRed: 0, green: 0, blue: 0.5, alpha: 1),
        "gold": NSColor(srgbRed: 1, green: 0.84, blue: 0, alpha: 1),
        "coral": NSColor(srgbRed: 1, green: 0.5, blue: 0.31, alpha: 1),
        "salmon": NSColor(srgbRed: 0.98, green: 0.5, blue: 0.45, alpha: 1),
        "indigo": NSColor(srgbRed: 0.29, green: 0, blue: 0.51, alpha: 1),
        "violet": NSColor(srgbRed: 0.93, green: 0.51, blue: 0.93, alpha: 1),
        "beige": NSColor(srgbRed: 0.96, green: 0.96, blue: 0.86, alpha: 1),
    ]
}

/// One overflow folder in the menu: entries after the inline limit, split
/// into fixed-size ranges like Clipy's "11–20" submenus.
struct ClipyMenuFolder: Identifiable, Equatable {
    let startNumber: Int
    let entries: [ClipyEntry]

    var id: String { "\(startNumber)-\(startNumber + entries.count - 1)" }
    var start: Int { startNumber }
    var end: Int { startNumber + entries.count - 1 }
}

enum ClipyMenuBuilder {
    /// Splits the sorted history into the inline tail and overflow folders.
    /// A zero inline limit puts everything into folders.
    static func folders(entries: [ClipyEntry],
                        inlineLimit: Int,
                        folderLimit: Int) -> (inline: [ClipyEntry], folders: [ClipyMenuFolder]) {
        let limit = max(0, inlineLimit)
        let perFolder = max(1, folderLimit)
        let inline = Array(entries.prefix(limit))
        let overflow = entries.dropFirst(limit)
        guard !overflow.isEmpty else { return (inline, []) }
        var folders: [ClipyMenuFolder] = []
        var start = limit + 1
        var index = overflow.startIndex
        while index < overflow.endIndex {
            let end = min(index + perFolder, overflow.endIndex)
            let chunk = Array(overflow[index..<end])
            folders.append(ClipyMenuFolder(startNumber: start, entries: chunk))
            start += chunk.count
            index = end
        }
        return (inline, folders)
    }

    /// The index a ⌘-number picks: 1–9 map to the first nine rows, 0 to the
    /// tenth, matching the numbers shown beside them.
    static func digitIndex(for keyCode: Int64) -> Int? {
        switch keyCode {
        case 18: return 0 // 1
        case 19: return 1 // 2
        case 20: return 2 // 3
        case 21: return 3 // 4
        case 23: return 4 // 5
        case 22: return 5 // 6
        case 26: return 6 // 7
        case 28: return 7 // 8
        case 25: return 8 // 9
        case 29: return 9 // 0
        default: return nil
        }
    }
}