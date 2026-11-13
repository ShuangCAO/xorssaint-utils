// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import AppKit
import CryptoKit
import Foundation

/// One copy read from the pasteboard, already reduced to the types the user
/// enabled. `representations` keeps each type's bytes; file paths are kept
/// separately because the Finder owns those files.
struct ClipyCaptured {
    let representations: [String: Data]
    let primaryType: String
    let preview: String
    let imageWidth: Int?
    let imageHeight: Int?
    let filePaths: [String]?
    let contentHash: String
}

enum ClipyCapture {
    static func read(from pasteboard: NSPasteboard,
                     enabled: Set<ClipyCaptureType>,
                     sourceBundleID: String?) -> ClipyCaptured? {
        guard !enabled.isEmpty else { return nil }
        var representations: [String: Data] = [:]
        var capturedTypes: [ClipyCaptureType] = []

        for type in enabled.sorted(by: { $0.priority < $1.priority }) {
            if let data = data(for: type, from: pasteboard) {
                representations[type.storageType] = data
                capturedTypes.append(type)
            }
        }

        var filePaths: [String]?
        if enabled.contains(.files) {
            let urls = (pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [NSURL])?
                .compactMap { $0 as URL }
            if let urls, !urls.isEmpty {
                filePaths = urls.map(\.path)
                capturedTypes.append(.files)
            }
        }

        guard !representations.isEmpty || filePaths?.isEmpty == false else { return nil }
        let primary = capturedTypes.min { $0.priority < $1.priority } ?? .plainText
        let imageData = representations[NSPasteboard.PasteboardType.png.rawValue]
            ?? representations[NSPasteboard.PasteboardType.tiff.rawValue]
        let size = imageData.flatMap(ClipyImage.dimensions)
        let preview = preview(for: primary,
                              pasteboard: pasteboard,
                              filePaths: filePaths,
                              imageSize: size)
        let hash = contentHash(representations: representations, filePaths: filePaths)
        return ClipyCaptured(representations: representations,
                             primaryType: primary.storageType,
                             preview: preview,
                             imageWidth: size?.width,
                             imageHeight: size?.height,
                             filePaths: filePaths,
                             contentHash: hash)
    }

    static func write(_ entry: ClipyEntry,
                      representations: [String: Data],
                      to pasteboard: NSPasteboard) -> Bool {
        pasteboard.clearContents()
        if let paths = entry.filePaths, !paths.isEmpty {
            pasteboard.writeObjects(paths.map { NSURL(fileURLWithPath: $0) })
        }
        for (type, data) in representations {
            pasteboard.setData(data, forType: NSPasteboard.PasteboardType(type))
        }
        return true
    }

    private static func data(for type: ClipyCaptureType,
                             from pasteboard: NSPasteboard) -> Data? {
        switch type {
        case .plainText, .rtf, .rtfd, .pdf, .html:
            return pasteboard.data(forType: type.pasteboardType)
        case .url:
            return pasteboard.string(forType: .URL)?.data(using: .utf8)
        case .image:
            return pasteboard.data(forType: .png) ?? pasteboard.data(forType: .tiff)
        case .files:
            return nil
        }
    }

    private static func preview(for type: ClipyCaptureType,
                                pasteboard: NSPasteboard,
                                filePaths: [String]?,
                                imageSize: (width: Int, height: Int)?) -> String {
        let fallback = pasteboard.string(forType: .string) ?? ""
        switch type {
        case .files:
            let names = (filePaths ?? []).map { ($0 as NSString).lastPathComponent }
            return names.joined(separator: ", ")
        case .image:
            if let imageSize {
                return "Image \(imageSize.width)×\(imageSize.height)"
            }
            return "Image"
        case .url:
            return pasteboard.string(forType: .URL) ?? fallback
        case .pdf:
            return fallback.isEmpty ? "PDF" : String(fallback.prefix(200))
        case .html:
            return fallback.isEmpty ? "HTML" : String(fallback.prefix(200))
        case .rtf, .rtfd:
            return fallback.isEmpty ? "Rich text" : String(fallback.prefix(200))
        case .plainText:
            return fallback
        }
    }

    private static func contentHash(representations: [String: Data],
                                    filePaths: [String]?) -> String {
        var hasher = SHA256()
        for key in representations.keys.sorted() {
            hasher.update(data: Data(key.utf8))
            if let data = representations[key] {
                hasher.update(data: data)
            }
        }
        if let filePaths {
            for path in filePaths {
                hasher.update(data: Data(path.utf8))
            }
        }
        return hasher.finalize().map { String(format: "%02x", $0) }.joined()
    }
}

enum ClipyImage {
    static func dimensions(_ data: Data) -> (width: Int, height: Int)? {
        guard let rep = NSBitmapImageRep(data: data), rep.pixelsWide > 0, rep.pixelsHigh > 0 else {
            return nil
        }
        return (rep.pixelsWide, rep.pixelsHigh)
    }
}