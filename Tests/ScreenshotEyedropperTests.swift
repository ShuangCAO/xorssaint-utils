// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

/// The eyedropper reads the colour under the pointer out of the capture and
/// puts it on the pasteboard. It is a tool that draws nothing, so it must not
/// disturb the marks, and it must not take a shortcut key away from a tool
/// that already had one.
enum ScreenshotEyedropperTests {
    static func run(_ suite: TestSuite) {
        order(suite)
        wiring(suite)
    }

    private static func order(_ suite: TestSuite) {
        suite.expect(ScreenshotSupport.Tool.editorTools.contains(.eyedropper),
                     "the eyedropper sits in the editor's rail")
        suite.expect(!ScreenshotSupport.Tool.editorTools.contains(.image),
                     "the image tool stays out of the rail")

        // The order a build before the eyedropper stored. A later build that
        // put the new tool anywhere but the end would hand a different tool
        // to the number keys.
        let stored = "select,arrow,pixelate,crop,text,sticker,rect,highlight,"
            + "freehand,line,ellipse,counter,redact,spotlight,expandCanvas"
        let order = ScreenshotSupport.Tool.ordered(from: stored)
        suite.expect(order.last == .eyedropper,
                     "a tool added later is appended, so the rail keeps its order")
        suite.expect(order.dropLast().map(\.rawValue).joined(separator: ",") == stored,
                     "the tools an earlier build handed out keep their places")

        for number in 1...ScreenshotSupport.Tool.shortcutLimit {
            let before = ScreenshotSupport.Tool.ordered(from: stored)[number - 1]
            let after = ScreenshotSupport.Tool.shortcutTool(number: number,
                                                           orderRaw: stored,
                                                           enabled: true)
            suite.expect(after == before,
                         "the number \(number) key still reaches the same tool")
        }

        // The eyedropper only reads, so a new editor opens ready to draw.
        suite.expect(ScreenshotSupport.Tool.startingTool(remembered: "eyedropper") == .arrow,
                     "the eyedropper is not the tool a new editor opens with")
        suite.expect(!ScreenshotSupport.Tool.eyedropper.dragsRect,
                     "the eyedropper drags no shape")
    }

    private static func wiring(_ suite: TestSuite) {
        let view = (try? String(contentsOfFile:
                "Sources/Xorssaint/UI/Screenshot/ScreenshotEditorView.swift",
                                   encoding: .utf8)) ?? ""
        suite.expect(view.contains("case .eyedropper: return \"eyedropper\""),
                     "the tool has its own symbol")
        suite.expect(view.contains("strings.toolEyedropper"),
                     "the tool has a name of its own")
        suite.expect(view.contains("model.updateEyedropper(at: point)"),
                     "the pointer's colour follows the pointer")
        suite.expect(view.contains("ColorSamplerService.shared.formattedValue"),
                     "the readout shows the value the pasteboard would receive")

        let editor = (try? String(contentsOfFile:
                "Sources/Xorssaint/Services/QuickTools/ScreenshotEditorController.swift",
                                   encoding: .utf8)) ?? ""
        suite.expect(editor.contains("func updateEyedropper(at point: CGPoint)"),
                     "the model tracks the pointer while the tool is active")
        suite.expect(editor.contains("QuickToolsSupport.sampledColor(in: image, x: x, y: y)"),
                     "the colour comes from the capture itself")
        suite.expect(editor.contains("ColorSamplerService.shared.copy(color)"),
                     "a picked colour goes to the pasteboard")
        suite.expect(editor.contains("tool = toolBeforeEyedropper"),
                     "the rail returns to the tool that was in use")

        let strings = (try? String(contentsOfFile:
                "Sources/Xorssaint/Core/ScreenshotStrings.swift", encoding: .utf8)) ?? ""
        suite.expect(strings.components(separatedBy: "toolEyedropper: \"").count - 1 == 15,
                     "every language names the eyedropper")
    }
}
