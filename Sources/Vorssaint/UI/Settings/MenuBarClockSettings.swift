// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import SwiftUI

/// The menu bar clock: a date/time readout in the idle slot where the app's
/// glyph used to sit. A signal still brings the icon back, so the symbol
/// picker below keeps its meaning for those moments.
struct MenuBarClockSettings: View {
    @ObservedObject private var l10n = L10n.shared
    @AppStorage(DefaultsKey.menuBarClockEnabled) private var enabled = true
    @AppStorage(DefaultsKey.menuBarClockFormat) private var format = MenuBarClockSupport.defaultFormat

    private var text: GeneralSettingsStrings { FeatureStrings.generalSettings(l10n.language) }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SettingsRow(symbol: "clock", title: text.clockTitle, caption: text.clockCaption) {
                Toggle(text.clockTitle, isOn: $enabled)
                    .labelsHidden()
            }
            if enabled {
                SettingsRow(symbol: nil, title: text.clockFormatTitle,
                            caption: text.clockFormatCaption) {
                    HStack(spacing: 8) {
                        TextField(MenuBarClockSupport.defaultFormat, text: $format)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 230)
                        Button(text.clockFormatReset) {
                            format = MenuBarClockSupport.defaultFormat
                        }
                        .disabled(MenuBarClockSupport.sanitizedFormat(format)
                                  == MenuBarClockSupport.defaultFormat)
                    }
                }
                preview
            }
        }
    }

    private var preview: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            HStack(spacing: 8) {
                Text(text.clockPreviewLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(MenuBarClockSupport.text(for: context.date, format: format))
                    .font(.system(size: 11.6, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.black.opacity(0.82),
                                in: RoundedRectangle(cornerRadius: 5, style: .continuous))
                Spacer(minLength: 0)
            }
        }
        .padding(.leading, settingsRowTextInset)
    }
}

/// The idle menu bar content as Settings previews draw it: the clock while
/// the option is on, the app glyph when it is off.
struct MenuBarIdlePreview: View {
    @AppStorage(DefaultsKey.menuBarClockEnabled) private var enabled = true
    @AppStorage(DefaultsKey.menuBarClockFormat) private var format = MenuBarClockSupport.defaultFormat

    var body: some View {
        Group {
            if enabled {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    Text(MenuBarClockSupport.text(for: context.date, format: format))
                        .font(.system(size: 10.5, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            } else {
                MenuBarGlyph()
                    .frame(width: 20, height: 15)
            }
        }
    }
}