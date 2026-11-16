// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

/// Command-Q must not quit the app by accident. Both Quit items stay in their
/// menus, so clicking them still quits, but no shortcut fires the action.
enum AppMenuSupportContract {
    static func run(_ suite: TestSuite) {
        let source = (try? String(contentsOfFile: "Sources/Xorssaint/App/AppDelegate.swift",
                                  encoding: .utf8)) ?? ""
        // Comments explain the choice and would otherwise match the scan.
        let code = source.components(separatedBy: "\n")
            .map { line in line.range(of: "//").map { String(line[..<$0.lowerBound]) } ?? line }
            .joined(separator: "\n")
        suite.expect(!code.isEmpty, "the app delegate is readable from the repo root")
        suite.expect(!code.contains("keyEquivalent: \"q\""),
                     "no menu item binds Command-Q")
        suite.expect(code.contains("action: #selector(quitApp), keyEquivalent: \"\")"),
                     "the status item menu keeps a Quit item that quits when clicked")
        suite.expect(code.contains("action: #selector(NSApplication.terminate(_:)), keyEquivalent: \"\")"),
                     "the application menu keeps a Quit item that quits when clicked")
    }
}
