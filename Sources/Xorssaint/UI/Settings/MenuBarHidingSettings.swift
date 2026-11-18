// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import AppKit
import Combine
import SwiftUI

/// Picks which apps' menu bar icons stay hidden. The list shows running apps
/// (no permission needed to know they run); entries picked earlier that are
/// not running right now stay listed below, so a selection can always be
/// taken back. The actual hiding lives in `MenuBarHidingService`, which
/// reacts to every write this page makes.
struct MenuBarHidingSettings: View {
    @ObservedObject private var l10n = L10n.shared
    @ObservedObject private var service = MenuBarHidingService.shared
    @AppStorage(DefaultsKey.menuBarHidingEnabled) private var enabled = false

    @State private var runningApps: [RunningApp] = []

    struct RunningApp: Identifiable, Equatable {
        let bundleIdentifier: String
        let name: String

        var id: String { bundleIdentifier }
    }

    private var text: MenuBarHidingStrings { FeatureStrings.menuBarHiding(l10n.language) }

    /// The cleaned-up selection, kept in one place so toggling a row and the
    /// "not running" rows below read and write the same list.
    private var selection: Set<String> {
        Set(service.hiddenSelection())
    }

    private var selectedNotRunning: [String] {
        selection.filter { bundle in !runningApps.contains(where: { $0.bundleIdentifier == bundle }) }
            .sorted()
    }

    var body: some View {
        Form {
            Section {
                Toggle(text.masterToggle, isOn: $enabled)
                Text(text.masterCaption)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let reason = unavailableReasonText {
                    Label(reason, systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }

            Section(text.listTitle) {
                Text(text.listCaption)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if runningApps.isEmpty {
                    Text(text.emptyList)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                ForEach(runningApps) { app in
                    Toggle(app.name, isOn: toggleBinding(for: app.bundleIdentifier))
                }
                if !selectedNotRunning.isEmpty {
                    Text(text.hiddenNotRunning)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .padding(.top, 4)
                    ForEach(selectedNotRunning, id: \.self) { bundle in
                        Toggle(displayName(for: bundle), isOn: toggleBinding(for: bundle))
                    }
                }
                Button(text.refresh) { refreshApps() }
                    .font(.caption)
            }

            Section(text.limitationsTitle) {
                Text(text.limitationApps)
                Text(text.limitationSystem)
                Text(text.limitationSideEffects)
                Text(text.limitationQuit)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .formStyle(.grouped)
        .onAppear { refreshApps() }
        // Menu bar apps are mostly agents, which post no workspace launch
        // notifications, so the running list itself is watched while the page
        // is on screen; a page that went away stops watching.
        .onReceive(runningAppsPublisher) { _ in refreshApps() }
    }

    private var runningAppsPublisher: AnyPublisher<[NSRunningApplication], Never> {
        NSWorkspace.shared.publisher(for: \.runningApplications)
            .receive(on: DispatchQueue.main)
            .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    /// Rows write the shared selection directly: one toggle must never wait
    /// for a second surface to notice.
    private func toggleBinding(for bundleIdentifier: String) -> Binding<Bool> {
        Binding(
            get: { selection.contains(bundleIdentifier) },
            set: { isHidden in
                var current = selection
                if isHidden {
                    current.insert(bundleIdentifier)
                } else {
                    current.remove(bundleIdentifier)
                }
                UserDefaults.standard.set(current.sorted(),
                                          forKey: DefaultsKey.menuBarHiddenApps)
            }
        )
    }

    private var unavailableReasonText: String? {
        switch service.unavailableReason {
        case .unsupportedOS: return text.unavailableOS
        case .frameworkMissing: return text.unavailableFramework
        case .outsideApplicationsFolder: return text.unavailableLocation
        case nil: return nil
        }
    }

    private func refreshApps() {
        let ownBundleIdentifier = Bundle.main.bundleIdentifier
        runningApps = NSWorkspace.shared.runningApplications
            .filter {
                MenuBarHidingSupport.isListableApp(bundleIdentifier: $0.bundleIdentifier,
                                                   ownBundleIdentifier: ownBundleIdentifier)
            }
            .map { app in
                RunningApp(
                    bundleIdentifier: app.bundleIdentifier ?? "",
                    name: app.localizedName
                        ?? app.bundleURL?.deletingPathExtension().lastPathComponent
                        ?? app.bundleIdentifier ?? ""
                )
            }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    /// A bundle id nobody turned into a name still has to read as a row.
    private func displayName(for bundleIdentifier: String) -> String {
        runningApps.first(where: { $0.bundleIdentifier == bundleIdentifier })?.name ?? bundleIdentifier
    }
}
