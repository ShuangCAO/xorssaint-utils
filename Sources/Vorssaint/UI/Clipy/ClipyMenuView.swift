// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import AppKit
import SwiftUI

/// The Clipy menu: a root column of history and snippets, with a second
/// column for an overflow folder. It is a panel rather than an NSMenu so the
/// rows can use Vorssaint's materials, thumbnails and typography.
struct ClipyMenuView: View {
    @ObservedObject var service: ClipyService
    @ObservedObject var model: ClipyMenuModel
    @ObservedObject private var l10n = L10n.shared

    private var strings: ClipyStrings { FeatureStrings.clipy(l10n.language) }
    private var titleLength: Int {
        UserDefaults.standard.integer(forKey: DefaultsKey.clipyTitleLength)
    }

    private var thumbnailWidth: CGFloat {
        CGFloat(UserDefaults.standard.integer(forKey: DefaultsKey.clipyThumbnailWidth))
    }

    private var thumbnailHeight: CGFloat {
        CGFloat(UserDefaults.standard.integer(forKey: DefaultsKey.clipyThumbnailHeight))
    }

    private var showImages: Bool {
        UserDefaults.standard.bool(forKey: DefaultsKey.clipyShowImages)
    }

    var body: some View {
        HStack(spacing: 0) {
            rootColumn
                .frame(width: 280)
            if let folder = model.openFolder {
                Divider()
                folderColumn(folder)
                    .frame(width: 259)
            }
        }
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.14), lineWidth: 0.7)
        )
    }

    private var rootColumn: some View {
        VStack(spacing: 0) {
            if model.rootRows.isEmpty {
                Text(strings.empty)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(20)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 1) {
                        ForEach(model.rootRows) { row in
                            rowView(row)
                        }
                    }
                    .padding(4)
                }
            }
            Divider()
            HStack(spacing: 10) {
                Button(strings.clearHistory) {
                    service.confirmClearHistory()
                }
                .disabled(service.entries.isEmpty)
                Spacer()
                Button(strings.editSnippets) {
                    service.editSnippets()
                }
            }
            .buttonStyle(.plain)
            .font(.system(size: 10.5, weight: .medium))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 10)
            .frame(height: 32)
        }
    }

    private func folderColumn(_ folder: ClipyMenuFolder) -> some View {
        VStack(spacing: 0) {
            Text("\(folder.start)–\(folder.end)")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 10)
                .frame(height: 24)
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 1) {
                    ForEach(Array(folder.entries.enumerated()), id: \.element.id) { index, entry in
                        menuItem(number: model.numberLabel(for: folder.startNumber + index),
                                 title: ClipyTitle.shortened(entry.preview, limit: titleLength),
                                 icon: icon(for: entry),
                                 selected: model.folderSelection == index,
                                 help: entry.preview)
                        .onHover { inside in
                            if inside { model.folderSelection = index }
                        }
                        .onTapGesture { service.paste(entry) }
                    }
                }
                .padding(4)
            }
        }
    }

    @ViewBuilder
    private func rowView(_ row: ClipyMenuRow) -> some View {
        switch row {
        case .header(let title, _):
            Text(title.uppercased())
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.secondary)
                .tracking(0.4)
                .padding(.horizontal, 6)
                .padding(.top, 5)
                .padding(.bottom, 2)
        case .entry(let entry, let number):
            menuItem(number: model.numberLabel(for: number),
                     title: ClipyTitle.shortened(entry.preview, limit: titleLength),
                     icon: icon(for: entry),
                     selected: model.isSelected(row),
                     help: entry.preview)
            .onHover { inside in
                if inside { model.select(row) }
            }
            .onTapGesture { model.select(row); model.activate(row) }
        case .folder(let folder, let number):
            HStack(spacing: 7) {
                numberBadge(model.numberLabel(for: number))
                Image(systemName: "folder")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(width: 16)
                Text("\(folder.start)–\(folder.end)")
                    .font(.system(size: 12))
                    .lineLimit(1)
                Spacer(minLength: 6)
                Image(systemName: "chevron.right")
                    .font(.system(size: 8.5, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 6)
            .frame(height: 26)
            .background(selectionFill(model.isSelected(row)))
            .contentShape(Rectangle())
            .onHover { inside in
                if inside { model.select(row) }
            }
            .onTapGesture { model.select(row); model.activate(row) }
        case .snippet(let snippet, let number):
            menuItem(number: model.numberLabel(for: number),
                     title: ClipyTitle.shortened(snippet.name.isEmpty ? snippet.content : snippet.name,
                                                 limit: titleLength),
                     icon: .symbol("text.append"),
                     selected: model.isSelected(row),
                     help: snippet.content)
            .onHover { inside in
                if inside { model.select(row) }
            }
            .onTapGesture { model.select(row); model.activate(row) }
        }
    }

    private func menuItem(number: String?,
                          title: String,
                          icon: ClipyRowIcon,
                          selected: Bool,
                          help: String?) -> some View {
        HStack(spacing: 7) {
            numberBadge(number)
            iconView(icon)
            Text(title)
                .font(.system(size: 12))
                .lineLimit(1)
                .truncationMode(.tail)
            Spacer(minLength: 6)
        }
        .padding(.horizontal, 6)
        .frame(height: rowHeight(for: icon))
        .background(selectionFill(selected))
        .contentShape(Rectangle())
        .help(help ?? "")
    }

    private func rowHeight(for icon: ClipyRowIcon) -> CGFloat {
        guard showImages, case .image = icon else { return 26 }
        return min(max(26, thumbnailHeight + 4), 64)
    }

    @ViewBuilder
    private func numberBadge(_ number: String?) -> some View {
        Text(number ?? "")
            .font(.system(size: 9, weight: .semibold, design: .monospaced))
            .foregroundStyle(.tertiary)
            .frame(width: 13, alignment: .trailing)
    }

    @ViewBuilder
    private func iconView(_ icon: ClipyRowIcon) -> some View {
        switch icon {
        case .symbol(let name):
            Image(systemName: name)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 18, height: 16)
        case .image(let image):
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: min(thumbnailWidth, 100), height: min(thumbnailHeight, 56))
                .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
        case .color(let color):
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(Color(nsColor: color))
                .frame(width: 16, height: 16)
                .overlay(
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.18), lineWidth: 0.5)
                )
                .frame(width: 18, height: 16)
        }
    }

    private func icon(for entry: ClipyEntry) -> ClipyRowIcon {
        service.rowIcon(for: entry)
    }

    private func selectionFill(_ selected: Bool) -> Color {
        selected ? Color.accentColor.opacity(0.14) : Color.clear
    }
}