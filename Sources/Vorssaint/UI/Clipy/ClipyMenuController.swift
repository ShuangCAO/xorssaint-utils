// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import AppKit
import Carbon.HIToolbox
import Combine
import SwiftUI

/// Hosts the Clipy menu in a non-activating panel at the pointer and owns its
/// keyboard and outside-click handling.
final class ClipyMenuController {
    private let service: ClipyService
    private let model: ClipyMenuModel
    private var panel: ClipyMenuPanel?
    private var keyMonitor: Any?
    private var localClickMonitor: Any?
    private var globalClickMonitor: Any?
    private var cancellables = Set<AnyCancellable>()
    private var topLeft = NSPoint.zero
    private var visibleFrame = NSRect.zero

    init(service: ClipyService, mode: ClipyMenuMode) {
        self.service = service
        model = ClipyMenuModel(service: service, mode: mode)
    }

    func show() {
        let panel = ClipyMenuPanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false)
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        let host = NSHostingController(rootView: ClipyMenuView(service: service, model: model))
        host.sizingOptions = []
        panel.contentViewController = host
        self.panel = panel

        installMonitors(for: panel)
        position(panel)
        panel.orderFrontRegardless()
        panel.makeKey()

        model.$openFolder
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.resize() }
            .store(in: &cancellables)
        service.$entries
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.resize() }
            .store(in: &cancellables)
    }

    func dismiss() {
        removeMonitors()
        cancellables.removeAll()
        panel?.orderOut(nil)
        panel = nil
    }

    private func position(_ panel: NSPanel) {
        let mouse = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { $0.frame.contains(mouse) }
            ?? NSScreen.main
            ?? NSScreen.screens[0]
        visibleFrame = screen.visibleFrame
        let size = currentSize()
        let x = min(max(mouse.x, visibleFrame.minX + 8),
                    visibleFrame.maxX - size.width - 8)
        let top = min(max(mouse.y, visibleFrame.minY + size.height + 8),
                      visibleFrame.maxY - 8)
        topLeft = NSPoint(x: x, y: top)
        panel.setFrame(NSRect(x: x, y: top - size.height,
                              width: size.width, height: size.height),
                       display: true)
    }

    private func resize() {
        guard let panel else { return }
        let size = currentSize()
        let x = min(max(topLeft.x, visibleFrame.minX + 8),
                    visibleFrame.maxX - size.width - 8)
        topLeft.x = x
        let y = max(visibleFrame.minY + 8, topLeft.y - size.height)
        panel.setFrame(NSRect(x: x, y: y, width: size.width, height: size.height),
                       display: true)
    }

    private func currentSize() -> NSSize {
        NSSize(width: model.panelWidth, height: model.estimatedHeight)
    }

    private func installMonitors(for panel: NSPanel) {
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, event.window === self.panel else { return event }
            return self.handle(event)
        }
        let mouseEvents: NSEvent.EventTypeMask = [.leftMouseDown, .rightMouseDown, .otherMouseDown]
        localClickMonitor = NSEvent.addLocalMonitorForEvents(matching: mouseEvents) { [weak self] event in
            guard let self, let panel = self.panel, panel.isVisible else { return event }
            if event.window !== panel, !panel.frame.insetBy(dx: -2, dy: -2)
                .contains(NSEvent.mouseLocation) {
                self.dismiss()
            }
            return event
        }
        globalClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: mouseEvents) { [weak self] _ in
            self?.dismiss()
        }
    }

    private func removeMonitors() {
        if let keyMonitor { NSEvent.removeMonitor(keyMonitor) }
        if let localClickMonitor { NSEvent.removeMonitor(localClickMonitor) }
        if let globalClickMonitor { NSEvent.removeMonitor(globalClickMonitor) }
        keyMonitor = nil
        localClickMonitor = nil
        globalClickMonitor = nil
    }

    private func handle(_ event: NSEvent) -> NSEvent? {
        let modifiers = event.modifierFlags.intersection([.command, .option, .shift, .control])
        switch event.keyCode {
        case UInt16(kVK_Escape):
            if model.openFolder != nil {
                model.closeFolder()
            } else {
                dismiss()
            }
            return nil
        case UInt16(kVK_UpArrow):
            if model.openFolder != nil {
                model.moveFolderSelection(by: -1)
            } else {
                model.moveSelection(by: -1)
            }
            return nil
        case UInt16(kVK_DownArrow):
            if model.openFolder != nil {
                model.moveFolderSelection(by: 1)
            } else {
                model.moveSelection(by: 1)
            }
            return nil
        case UInt16(kVK_Return), UInt16(kVK_ANSI_KeypadEnter):
            if model.openFolder != nil {
                model.activateFolderSelection()
            } else {
                model.activateSelection()
            }
            return nil
        case UInt16(kVK_RightArrow):
            model.openSelectedFolder()
            return nil
        case UInt16(kVK_LeftArrow):
            if model.openFolder != nil {
                model.closeFolder()
                return nil
            }
            return event
        default:
            break
        }
        if modifiers == [.command],
           UserDefaults.standard.bool(forKey: DefaultsKey.clipyNumericShortcuts),
           let index = ClipyMenuBuilder.digitIndex(for: Int64(event.keyCode)) {
            if let folder = model.openFolder {
                if folder.entries.indices.contains(index) {
                    service.paste(folder.entries[index])
                }
            } else {
                model.activateNumber(index)
            }
            return nil
        }
        return event
    }
}

private final class ClipyMenuPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}