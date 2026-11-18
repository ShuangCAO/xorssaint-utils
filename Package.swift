// swift-tools-version:5.9
// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import PackageDescription

let package = Package(
    name: "Xorssaint",
    platforms: [.macOS(.v14)],
    targets: [
        .systemLibrary(
            name: "CoreAudioTapCompat",
            path: "Sources/CoreAudioTapCompat"
        ),
        .systemLibrary(
            name: "HIDEventSystem",
            path: "Sources/HIDEventSystem"
        ),
        .systemLibrary(
            name: "VMStatisticsCompat",
            path: "Sources/VMStatisticsCompat"
        ),
        .target(
            name: "RecorderGIFCodec",
            path: "Sources/RecorderGIFCodec",
            sources: ["RecorderGIFCodec.c", "vendor/cgif/cgif_raw.c"]
        ),
        .target(
            name: "MenuBarVisibility",
            path: "Sources/MenuBarVisibility",
            sources: ["MenuBarVisibility.m"],
            publicHeadersPath: "include"
        ),
        .executableTarget(
            name: "Xorssaint",
            dependencies: ["VMStatisticsCompat", "HIDEventSystem", "CoreAudioTapCompat", "RecorderGIFCodec",
                           "MenuBarVisibility"],
            path: "Sources/Xorssaint"
        )
    ]
)
