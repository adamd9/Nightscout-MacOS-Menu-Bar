//
//  MainMenu.swift
//  NightscountMenuBar
//
//  Created by adam.d on 27/6/2022.
//

//import Foundation
//import Cocoa
import SwiftUI

class MainMenu: NSObject {
    let menu = NSMenu()
    
    func build() -> NSMenu {
        
        let historyMenuItem = NSMenuItem()
        historyMenuItem.title = "History"
        historyMenuItem.tag = 11
        menu.addItem(historyMenuItem)
        let historySubMenu = NSMenu()
        historySubMenu.addItem(withTitle: "No entries", action: nil, keyEquivalent: "")
        menu.setSubmenu(historySubMenu, for: historyMenuItem)
        
        let settingsMenuItem = NSMenuItem(
            title: "Preferences",
            action: #selector(settings),
            keyEquivalent: ","
        )
        settingsMenuItem.target = self
        menu.addItem(settingsMenuItem)
        menu.addItem(NSMenuItem.separator())
     
        // We add an Open site option.
        let openMenuItem = NSMenuItem(
            title: "Open Nightscout Site",
            action: #selector(openSite),
            keyEquivalent: ""
        )
        // This is important so that our #selector
        // targets the `about` func in this file
        openMenuItem.target = self
        
        // This is where we actually add our about item to the menu
        menu.addItem(openMenuItem)
        
        // We add an About pane.
        let aboutMenuItem = NSMenuItem(
            title: "About Nightscout Menu Bar",
            action: #selector(about),
            keyEquivalent: ""
        )
        // This is important so that our #selector
        // targets the `about` func in this file
        aboutMenuItem.target = self
        
        // This is where we actually add our about item to the menu
        menu.addItem(aboutMenuItem)
        
        // We add an issue reporting menu option.
        let reportIssueMenuItem = NSMenuItem(
            title: "Report an Issue",
            action: #selector(reportIssue),
            keyEquivalent: ""
        )
        reportIssueMenuItem.target = self
        
        // This is where we actually add our about item to the menu
        menu.addItem(reportIssueMenuItem)
        
        // Adding a quit menu item
        let quitMenuItem = NSMenuItem(
            title: "Quit",
            action: #selector(quit),
            keyEquivalent: "q"
        )
        quitMenuItem.target = self
        menu.addItem(quitMenuItem)
        
        return menu
    }
    
    func updateHistory(entries: [String]) {
        
        let historySubMenu = NSMenu()
        
        entries.forEach({entry in
            let entryMenuItem = NSMenuItem(
                title: entry,
                action: nil,
                keyEquivalent: ""
            )
            historySubMenu.addItem(entryMenuItem)
        })
        let historyMenuItem = menu.item(withTitle: "History")
        menu.setSubmenu(historySubMenu, for: historyMenuItem!)
    }
    
    func updateExtraMessage(extraMessage: String?) {
        if (menu.item(withTag: 99) != nil) {
            menu.removeItem(at: menu.indexOfItem(withTag: 99))
        }
        if (extraMessage != nil) {
            let extraMessageMenuItem = NSMenuItem(
                title: extraMessage!,
                action: nil,
                keyEquivalent: ""
            )
            extraMessageMenuItem.tag = 99
            menu.insertItem(extraMessageMenuItem, at: 0)
        }
    }
    
    func updateOtherInfo(otherinfo: OtherInfoModel?) {
        if (menu.item(withTag: 22) != nil) {
            menu.removeItem(at: menu.indexOfItem(withTag: 22))
        }
        if (otherinfo != nil) {
            let otherInfoBoardView = OtherInfoBoardView()
                .environmentObject(otherinfo!)
            
            // We need this to allow use to stick a SwiftUI view into a
            // a location an NSView would normally be placed
            let content1View = NSHostingController(rootView: otherInfoBoardView)
            // Setting a size for our now playing view
            content1View.view.frame.size = CGSize(width: 200, height: 40)
            
            let otherInfoBoardMenuItem = NSMenuItem()
            otherInfoBoardMenuItem.view = content1View.view
            
            otherInfoBoardMenuItem.tag = 22
            menu.insertItem(otherInfoBoardMenuItem, at: 0)
            menu.addItem(NSMenuItem.separator())
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
                    string: "Github Project`",
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
        NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
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
        
        if let url = URL(string: nightscoutUrl) {
            NSWorkspace.shared.open(url)
        }    }
    
    // The selector that quits the app
    @objc func quit(sender: NSMenuItem) {
        NSApp.terminate(self)
    }
}
