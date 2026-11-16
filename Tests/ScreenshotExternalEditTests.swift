// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

/// "Edit with Xorssaint" in Finder's Services menu opens any image file in
/// the screenshot editor. Saving lands beside the original and never
/// replaces it. These checks pin the save-target math and the wiring between
/// the declared service and its handler.
enum ScreenshotExternalEditTests {
    static func run(_ suite: TestSuite) {
        saveDestination(suite)
        serviceContract(suite)
    }

    private static func saveDestination(_ suite: TestSuite) {
        let source = URL(fileURLWithPath: "/tmp/Pictures/photo.jpg")

        // No conflict: the export keeps the original's folder and base name,
        // in the export format.
        let plain = ScreenshotSupport.saveDestination(forSourceURL: source,
                                                      fileExtension: "jpg") { _ in false }
        suite.expect(plain.path == "/tmp/Pictures/photo.jpg",
                     "a free name saves beside the original: \(plain.path)")

        // The original always exists, so the first save never overwrites it.
        let first = ScreenshotSupport.saveDestination(forSourceURL: source,
                                                      fileExtension: "jpg") {
            $0 == "/tmp/Pictures/photo.jpg"
        }
        suite.expect(first.path == "/tmp/Pictures/photo 2.jpg",
                     "an existing original forces a numbered name: \(first.path)")

        // Earlier exports occupy their numbers; the next free one is used.
        let third = ScreenshotSupport.saveDestination(forSourceURL: source,
                                                      fileExtension: "jpg") {
            ["/tmp/Pictures/photo.jpg", "/tmp/Pictures/photo 2.jpg"].contains($0)
        }
        suite.expect(third.path == "/tmp/Pictures/photo 3.jpg",
                     "numbering skips names already on disk: \(third.path)")

        // A JPEG with annotations exports as PNG; that name is independent of
        // the JPEG original, but still must not replace an existing PNG.
        let png = ScreenshotSupport.saveDestination(forSourceURL: source,
                                                    fileExtension: "png") {
            $0 == "/tmp/Pictures/photo.png"
        }
        suite.expect(png.path == "/tmp/Pictures/photo 2.png",
                     "a format change picks a free name of the new type: \(png.path)")

        let dotted = ScreenshotSupport.saveDestination(
            forSourceURL: URL(fileURLWithPath: "/tmp/a.b/shot.final.heic"),
            fileExtension: "png") { _ in false }
        suite.expect(dotted.path == "/tmp/a.b/shot.final.png",
                     "only the last extension is replaced: \(dotted.path)")
    }

    private static func serviceContract(_ suite: TestSuite) {
        let plist = (try? String(contentsOfFile: "Resources/Info.plist", encoding: .utf8)) ?? ""
        suite.expect(plist.contains("<key>NSServices</key>")
                     && plist.contains("<string>editImageWithXorssaint</string>"),
                     "the service declares the editImageWithXorssaint message")
        suite.expect(plist.contains("<string>public.image</string>"),
                     "the service is offered for image files")
        suite.expect(plist.contains("<key>NSSendFileTypes</key>"),
                     "the service receives file URLs, not image data")

        let delegate = (try? String(contentsOfFile: "Sources/Xorssaint/App/AppDelegate.swift",
                                    encoding: .utf8)) ?? ""
        suite.expect(delegate.contains("NSApp.servicesProvider = self"),
                     "the app delegate registers itself as the services provider")
        // NSMessage appends :userData:error: to the declared name; a mismatch
        // here makes the menu item do nothing.
        suite.expect(delegate.contains("func editImageWithXorssaint(_ pboard: NSPasteboard,")
                     && delegate.contains("userData: String,")
                     && delegate.contains("error: AutoreleasingUnsafeMutablePointer<NSString?>)"),
                     "the handler's selector matches the declared message")
        suite.expect(delegate.contains("ScreenshotService.shared.editImage(at: url)"),
                     "the handler routes the file into the existing editor channel")

        // Only the first selected file is edited, and the import channel is
        // what carries the origin through to the editor's save target.
        let service = (try? String(contentsOfFile:
                "Sources/Xorssaint/Services/QuickTools/ScreenshotService.swift",
                                   encoding: .utf8)) ?? ""
        suite.expect(service.contains("capture.sourceURL = url"),
                     "a file import remembers where the image came from")
    }
}
