//
//  DockIconManager.swift
//  Nightscout Menu Bar
//
//  Created by Adam Dinneen on 6/8/2023.
//

import AppKit

class DockIconManager {
    static let shared = DockIconManager()
    private var alert: Bool = false
    private var dockTile: NSDockTile?
    var isAlertShowing = false

    private init() {
        dockTile = NSApp.dockTile
    }

    func showDock(alert: Bool) {
        NSApp.setActivationPolicy(.regular)
        self.alert = alert
        if (alert) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [] in
                NSApp.dockTile.badgeLabel = "!"
            }
        }
    }

    func hideDock() {
        self.alert = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [] in
            let hasActiveWindows = NSApp.windows.contains { $0.isMainWindow || $0.isKeyWindow }

            if hasActiveWindows {
                // There are active windows, do nothing
                print("Window is still open")
            } else {
                // Hide the dock since there are no active windows
                NSApp.dockTile.badgeLabel = nil
                NSApp.setActivationPolicy(.accessory)
            }
        }

    }
    
    func dockWasClicked() {
        if (self.alert && !isAlertShowing) {
            showTopNotchAlert()
        } else {
            nsmodel.statusItem.checkVisibility()
        }
        
    }
    
    private func showTopNotchAlert() {
        isAlertShowing = true
        
        let alert = NSAlert()
        alert.messageText = "Nightscout Menu Bar was hidden by the OS"
        alert.informativeText = "Try turning off features like the graph, icon etc in Preferences. \n\nYou can choose which items are hidden by the notch by holding ⌘ and dragging items into the notch."
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Open Preferences")
        let response = alert.runModal()
        isAlertShowing = false
        
        switch response {
        case .alertFirstButtonReturn:
            // OK button clicked
            break
        case .alertSecondButtonReturn:
            // Open Preferences button clicked
            NSApp.activate(ignoringOtherApps: true)
            if #available(macOS 13, *) {
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            } else {
                NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
            }
            break
        default:
            break
        }
    }
}
