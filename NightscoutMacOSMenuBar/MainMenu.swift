//
//  MainMenu.swift
//  NightscountOSXMenuApp
//
//  Created by adam.d on 27/6/2022.
//

//import Foundation
//import Cocoa
import SwiftUI

// This is our custom menu that will appear when users
// click on the menu bar icon
class MainMenu: NSObject {
    // A new menu instance ready to add items to
    let menu = NSMenu()
    // These are the available links shown in the menu
    // These are fetched from the Info.plist file
    //  let menuItems = Bundle.main.object(forInfoDictionaryKey: "KyanLinks") as! [String: String]
    
    // function called by KyanBarApp to create the menu
    func build() -> NSMenu {
        menu.removeAllItems()
        //    func build() -> NSMenu {
        // Initialse the custom now playing view
        //    let nowPlayingView = NowPlayingView()
        // We need this to allow use to stick a SwiftUI view into a
        // a location an NSView would normally be placed
        //    let contentView = NSHostingController(rootView: nowPlayingView)
        // Setting a size for our now playing view
        //    contentView.view.frame.size = CGSize(width: 200, height: 80)
        
        // This is where we actually add our now playing view to the menu
        //    let customMenuItem = NSMenuItem()
        //    customMenuItem.view = contentView.view
        //    menu.addItem(customMenuItem)
        
        // Adding a seperator
        //    menu.addItem(NSMenuItem.separator())
//
//        let historySubMenu = NSMenu()
//
//        entries.sorted(by: { $0.time > $1.time }).forEach({entry in
//            let entryMenuItem = NSMenuItem(
//                title: bgHistoryValueFormatted(entry: entry),
//                action: nil,
//                keyEquivalent: ""
//            )
//            historySubMenu.addItem(entryMenuItem)
//        })
//        let historyMenuItem = NSMenuItem()
//        historyMenuItem.title = "History"
//        menu.addItem(historyMenuItem)
//        menu.setSubmenu(historySubMenu, for: historyMenuItem)
//        menu.addItem(NSMenuItem.separator())
//
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
            title: "About Nightscout Menu App",
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
        
        // Loop though our sorted link list and create a new menu item for
        // each, and then add it to the menu
        //    for (title, link) in menuItems.sorted( by: { $0.0 < $1.0 }) {
        //      let menuItem = NSMenuItem(
        //        title: title,
        //        action: #selector(linkSelector),
        //        keyEquivalent: ""
        //      )
        //      menuItem.target = self
        //      menuItem.representedObject = link
        //
        //      menu.addItem(menuItem)
        //    }
        
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
    
    func addHistory(entries: [Entry]) {
 
        let historySubMenu = NSMenu()
        
        entries.sorted(by: { $0.time > $1.time }).forEach({entry in
            let entryMenuItem = NSMenuItem(
                title: bgHistoryValueFormatted(entry: entry),
                action: nil,
                keyEquivalent: ""
            )
            historySubMenu.addItem(entryMenuItem)
        })
        let historyMenuItem = NSMenuItem()
        historyMenuItem.title = "History"
        if (menu.item(at: 0)?.title == "History") {
            menu.removeItem(at: 0)
        }
        menu.insertItem(historyMenuItem, at: 0)
        menu.setSubmenu(historySubMenu, for: historyMenuItem)
        menu.addItem(NSMenuItem.separator())
        
//        return menu
    }
    
    // The selector that takes a link and opens it
    // in your default browser
    @objc func linkSelector(sender: NSMenuItem) {
        let link = sender.representedObject as! String
        guard let url = URL(string: link) else { return }
        NSWorkspace.shared.open(url)
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
    private func bgHistoryValueFormatted(entry: Entry? = nil) -> String {
        
        if (entry == nil) {
            return "Loading.."
        }
        @AppStorage("bgUnits") var userPrefBg = "mgdl"
        var bgVal = ""
        if (userPrefBg == "mmol") {
            bgVal = String(entry!.bgMmol)
        } else {
            bgVal = String(entry!.bgMg)
        }
        switch entry!.direction {
        case "Flat":
            bgVal += " ➔"
        case "FortyFiveDown":
            bgVal += " ➘"
        case "FortyFiveUp":
            bgVal += " ➚"
        default:
            bgVal += " *"
        }
        
        let fromNow = String(Int(minutesBetweenDates(entry!.time, Date())))
        bgVal += " " + fromNow + " m"
        return bgVal
    }
}
