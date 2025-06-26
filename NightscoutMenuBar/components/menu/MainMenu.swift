//
//  MainMenu.swift
//  NightscountMenuBar
//
//  Created by adam.d on 27/6/2022.
//

//import Foundation
//import Cocoa
import SwiftUI

class MainMenu: NSObject, NSMenuDelegate {
    private let menu = NSMenu()
    @State private var chartMenuItem: NSMenuItem  = NSMenuItem()
    @State private var otherInfoBoardMenuItem: NSMenuItem = NSMenuItem()
    @State private var historySubMenu: NSMenu?
    var dockIconManager = DockIconManager.shared

    func build() -> NSMenu {

        // Set MainMenu as the delegate of menu
        menu.delegate = self

        @AppStorage("useLegacyStatusItem") var useLegacyStatusItem = false
        @AppStorage("showLoopData") var showLoopData = false
        @AppStorage("nightscoutUrl") var nightscoutUrl = ""
        menu.removeAllItems()
        chartMenuItem.title = "[Chart] has no data..."
        
        menu.addItem(buildSettingsMenuItem())

        if (showLoopData) {
            otherInfoBoardMenuItem.title = "[InfoBoard] has no data..."
            menu.addItem(otherInfoBoardMenuItem)
        }
        menu.addItem(chartMenuItem)
        menu.addItem(buildHistoryMenuItem())
        menu.addItem(NSMenuItem.separator())
        menu.addItem(buildAboutMenuItem())
         // Always display the "Open Nightscout Site" option; availability checked in selector
         menu.addItem(buildOpenSiteMenuItem())
        menu.addItem(buildReportIssueMenuItem())
        menu.addItem(buildQuitMenuItem())

        return menu
    }
    
    // NSMenuDelegate method
     func menuWillOpen(_ menu: NSMenu) {
         // This code will be triggered when the menu is opened
         print("Menu will open")
         dockIconManager.showDock(alert: false)
     }
    
    // NSMenuDelegate method
    func menuDidClose(_ menu: NSMenu) {
        // This code will be triggered when the menu is closed
        print("Menu did close")
        dockIconManager.hideDock()
    }

    func buildPlaceholderItem() -> NSMenuItem {
        let placeholderMenuItem = NSMenuItem()
        placeholderMenuItem.title = "Loading..."
        return placeholderMenuItem
    }
    
    func buildHistoryMenuItem() -> NSMenuItem {
        let historyMenuItem = NSMenuItem()
        historyMenuItem.title = "History"
        historyMenuItem.tag = 11
        historyMenuItem.submenu = buildHistorySubMenu()
        return historyMenuItem
        
        func buildHistorySubMenu() -> NSMenu {
            let historySubMenu = NSMenu()
            historySubMenu.addItem(withTitle: "No entries", action: nil, keyEquivalent: "")
            return historySubMenu
        }
    }

    private func buildSettingsMenuItem() -> NSMenuItem {
        let settingsButtonView = SettingsLinkView().padding(4)
        
        let content1View = NSHostingController(rootView: settingsButtonView)
        content1View.view.frame.size = CGSize(width: 220, height: 44)
        
        let settingsMenuItem = NSMenuItem()
        settingsMenuItem.view = content1View.view
        
        return settingsMenuItem

    }

    private func buildAboutMenuItem() -> NSMenuItem {
        let aboutMenuItem = NSMenuItem(
            title: "About Nightscout Menu Bar",
            action: #selector(about),
            keyEquivalent: ""
        )
        aboutMenuItem.target = self
        return aboutMenuItem
    }

    private func buildOpenSiteMenuItem() -> NSMenuItem {
        let openMenuItem = NSMenuItem(
            title: "Open Nightscout Site",
            action: #selector(openSite),
            keyEquivalent: ""
        )
        openMenuItem.target = self
        return openMenuItem
    }

    private func buildReportIssueMenuItem() -> NSMenuItem {
        let reportIssueMenuItem = NSMenuItem(
            title: "Report an Issue",
            action: #selector(reportIssue),
            keyEquivalent: ""
        )
        reportIssueMenuItem.target = self
        return reportIssueMenuItem
    }

    private func buildQuitMenuItem() -> NSMenuItem {
        let quitMenuItem = NSMenuItem(
            title: "Quit",
            action: #selector(quit),
            keyEquivalent: "q"
        )
        quitMenuItem.target = self
        return quitMenuItem
    }
    
    func updateHistory(entries: [String]) {
        let newHistorySubMenu = NSMenu()

        entries.forEach { entry in
            let entryMenuItem = NSMenuItem(
                title: entry,
                action: nil,
                keyEquivalent: ""
            )
            newHistorySubMenu.addItem(entryMenuItem)
        }

        if let existingHistoryMenuItem = menu.item(withTitle: "History") {
            // Update existing History menu item
            if historySubMenu != nil {
                existingHistoryMenuItem.submenu = newHistorySubMenu
            } else {
                existingHistoryMenuItem.submenu = newHistorySubMenu
                historySubMenu = newHistorySubMenu // Save the reference
            }
        } else {
            // Create a new History menu item
            let newHistoryMenuItem = NSMenuItem(title: "History", action: nil, keyEquivalent: "")
            newHistoryMenuItem.submenu = newHistorySubMenu
            menu.addItem(newHistoryMenuItem)
            menu.addItem(NSMenuItem.separator())
            historySubMenu = newHistorySubMenu // Save the reference
        }
    }
    
    func updateExtraMessage(extraMessage: String?) {
        if let existingExtraMessageMenuItem = menu.item(withTag: 99) {
            // Remove the existing extraMessageMenuItem if it exists
            menu.removeItem(existingExtraMessageMenuItem)
        }

        if let extraMessage = extraMessage {
            let extraMessageMenuItem = NSMenuItem(
                title: extraMessage,
                action: nil,
                keyEquivalent: ""
            )
            extraMessageMenuItem.tag = 99

            // Calculate the index where the new extraMessageMenuItem should be inserted
            let insertIndex = min(0, menu.items.count)
            menu.insertItem(extraMessageMenuItem, at: insertIndex)
        }
    }

    func updateOtherInfo(otherinfo: OtherInfoModel?) {
        let existingMenuItem = otherInfoBoardMenuItem
        if let otherinfo = otherinfo {
            let otherInfoBoardView = OtherInfoBoardView()
                .environmentObject(otherinfo)

            let content1View = NSHostingController(rootView: otherInfoBoardView)
            content1View.view.frame.size = CGSize(width: 200, height: 40)

            existingMenuItem.view = content1View.view
        }
       }
    
    func updateMenuChart(chartData: ChartData?, maxVal: Double, minVal: Double) {
        if (chartData != nil) {
            let existingMenuItem = chartMenuItem
            let chartView = MenuChartView(maxVal: maxVal, minVal: minVal)
                .environmentObject(chartData!)

            let content1View = NSHostingController(rootView: chartView)
            content1View.view.frame.size = CGSize(width: 200, height: 120)

            existingMenuItem.view = content1View.view
        }
 
    }
    
    // The selector that opens a standard about pane.
    // You can see we also customise what appears in our
    // about pane by creating a Credits.html file in the root
    // of the project
    @objc func about(sender: NSMenuItem) {
        
        NSApp.orderFrontStandardAboutPanel(
            options: [
                NSApplication.AboutPanelOptionKey.credits: NSMutableAttributedString(
                    string: "Github Project",
                    attributes:[
                        NSAttributedString.Key.link: URL(string: "https://github.com/adamd9/NightscoutOSXMenuApp")!,
                        NSAttributedString.Key.font: NSFont.boldSystemFont(ofSize: NSFont.smallSystemFontSize)
                    ]
                ),
                NSApplication.AboutPanelOptionKey(
                    rawValue: "Copyright"
                ): "2022 Adam Dinneen"
            ]
        )
    }
    
    @objc func settings(sender: NSMenuItem) {
        NSApp.activate(ignoringOtherApps: true)
        if #available(macOS 13, *) {
          NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        } else {
          NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
        }
        
    }
    
    // The selector that reports an issue
    @objc func reportIssue(sender: NSMenuItem) {
        @AppStorage("nightscoutUrl") var nightscoutUrl = ""
        let service = NSSharingService(named: NSSharingService.Name.composeEmail)
        
        service?.recipients = ["adam@greatmachineinthesky.com"]
        service?.subject = "Nightscout Menu Bar - Report an Issue"
        service?.perform(withItems: [
            "Nightscout URL: " + nightscoutUrl,
            "Please provide a description of the issue. Leaving your Nightscout URL included means that the developer can replicate the issue and fix it.",
            "",
            "Description of issue: "
        ])
    }
    
    // The selector that opens the current nightscout site
    @objc func openSite(sender: NSMenuItem) {
        @AppStorage("nightscoutUrl") var nightscoutUrl = ""
        @AppStorage("accessToken") var accessToken = ""
        
        // Trim whitespace/newlines to reliably detect empty configuration
        let trimmedUrl = nightscoutUrl.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedUrl.isEmpty else {
            // Nightscout URL not configured – inform the user and optionally open Settings
            let alert = NSAlert()
            alert.alertStyle = .warning
            alert.messageText = "Nightscout URL not configured"
            alert.informativeText = "Please configure your Nightscout URL in Settings before opening the Nightscout site."
            alert.addButton(withTitle: "OK")
            alert.runModal()
            return
        }
        
        // Nightscout URL configured – open the site. Append token only if supplied
        var urlString = trimmedUrl
        if !accessToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            // Ensure we append the token correctly (avoid double query symbol)
            if urlString.contains("?") {
                urlString += "&token=" + accessToken
            } else {
                urlString += "?token=" + accessToken
            }
        }
        
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }
    
    // The selector that quits the app
    @objc func quit(sender: NSMenuItem) {
        NSApp.terminate(self)
    }
    
    
    struct SettingsLinkView: View {
        @State private var isHovering = false
        
        var body: some View {
            HStack {
                Spacer()
                Text("Nightscout Menu Bar")
                    .font(.headline)
                Spacer()
                if #available(macOS 14.0, *) {
                    SettingsLink {
                        Image(systemName: "gear")
                            .resizable()
                            .frame(width: 15, height: 15)
                            .padding(4)
                            .foregroundColor(isHovering ? .secondary : .primary)
                            .background(isHovering ? .tertiary : .quinary)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .background(.quinary)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .onHover(perform: { hovering in
                        isHovering =  hovering
                    })
                } else {
                    Button("Settings") {
                        NSApp.activate(ignoringOtherApps: true)
                        if #available(macOS 13, *) {
                          NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                        } else {
                          NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
                        }
                    }
                    .font(.caption)
                }
            }
        }
    }
}
