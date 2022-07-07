//
//  MainMenu.swift
//  NightscountOSXMenuApp
//
//  Created by adam.d on 27/6/2022.
//

//import Foundation
//import Cocoa
import SwiftUI

class MainMenu: NSObject {
    let menu = NSMenu()

    func build() -> NSMenu {
        menu.removeAllItems()

        let settingsMenuItem = NSMenuItem(
            title: "Preferences",
            action: #selector(settings),
            keyEquivalent: ","
        )
        settingsMenuItem.target = self
        menu.addItem(settingsMenuItem)
        menu.addItem(NSMenuItem.separator())
        
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
        
        // Adding a seperator
        menu.addItem(NSMenuItem.separator())
        
        // Adding a quit menu item
        let quitMenuItem = NSMenuItem(
            title: "Quit Nightscout Menu App",
            action: #selector(quit),
            keyEquivalent: "q"
        )
        quitMenuItem.target = self
        menu.addItem(quitMenuItem)
        
        return menu
    }
    
    func addHistory(entries: [String]) {
 
        let historySubMenu = NSMenu()
        
        entries.forEach({entry in
            let entryMenuItem = NSMenuItem(
            title: entry,
            action: nil,
            keyEquivalent: ""
        )
        historySubMenu.addItem(entryMenuItem)
        })
        let historyMenuItem = NSMenuItem()
        historyMenuItem.title = "History"
        historyMenuItem.tag = 11
        if (menu.item(withTag: 11) != nil) {
            menu.removeItem(at: menu.indexOfItem(withTag: 11))
        }
        menu.insertItem(historyMenuItem, at: 0)
        menu.setSubmenu(historySubMenu, for: historyMenuItem)
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
            
            // Adding a seperator
            menu.addItem(NSMenuItem.separator())
        }
    }
    
    // The selector that opens a standard about pane.
    // You can see we also customise what appears in our
    // about pane by creating a Credits.html file in the root
    // of the project
    @objc func about(sender: NSMenuItem) {
        NSApp.orderFrontStandardAboutPanel()
    }
    
    @objc func settings(sender: NSMenuItem) {
        NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
    }
    
    // The selector that quits the app
    @objc func quit(sender: NSMenuItem) {
        NSApp.terminate(self)
    }
}
