// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import SwiftUI

/// Explains where macOS 27 keeps menu bar icon hiding and opens that pane.
/// The app no longer holds a private menu bar visibility assertion; the
/// system's own list is the only implementation.
struct MenuBarHidingSettings: View {
    @ObservedObject private var l10n = L10n.shared

    private var text: MenuBarHidingStrings { FeatureStrings.menuBarHiding(l10n.language) }
    private var isSupported: Bool { MenuBarHidingSupport.isSupportedOS() }

    var body: some View {
        Form {
            Section {
                Text(text.pageDescription)

                Button(FeatureStrings.hub(l10n.language).openSystemSettings) {
                    MenuBarHidingSupport.openSystemSettings()
                }
                .disabled(!isSupported)

                if !isSupported {
                    Text(text.unavailableOS)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section(text.limitationsTitle) {
                Text(text.limitationApps)
                Text(text.limitationSystem)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .formStyle(.grouped)
    }
}