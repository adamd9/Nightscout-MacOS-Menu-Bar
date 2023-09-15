//
//  MenuBarWidgetLegacy.swift
//  Nightscout Menu Bar
//
//  Created by Adam Dinneen on 26/7/2023.
//

import SwiftUI
import Foundation
import Cocoa

class MenuBarWidgetLegacy: ObservableObject, MenuBarWidgetProtocol {
    
    private var statusItem: NSStatusItem
    private let menu = MainMenu()
    
    func updateDisplay(message: String, store: EntriesStore, extraMessage: String?) {
        @AppStorage("bgUnits") var userPrefBg = "mgdl"
        @AppStorage("displayNSIcon") var displayNSIcon = true

        if (!store.entries.isEmpty) {
            
            let myAttribute = [ NSAttributedString.Key.foregroundColor: NSColor.textColor ]
            let myAttrString = NSAttributedString(string: message, attributes: myAttribute)
            self.statusItem.button?.attributedTitle = myAttrString
            if (displayNSIcon) {
                self.statusItem.button?.image = NSImage(named: NSImage.Name("sys-icon"))
                self.statusItem.button?.image?.size = NSSize(width: 18.0, height: 18.0)
                self.statusItem.button?.imagePosition = .imageLeading
            } else {
                self.statusItem.button?.image = nil
            }
            populateHistoryMenu(store: store)
        }
        
    }
    
    func checkVisibility() {
        
    }
    
    func populateHistoryMenu(store: EntriesStore) {
        if (!store.entries.isEmpty) {
            store.orderByTime()
            var historyStringArr = [String]()
            store.entries.forEach({entry in
                historyStringArr.append(bgValueFormattedHistory(entry: entry) + " " + bgMinsAgo(entry: entry) + " m")
            })
            self.menu.updateHistory(entries: historyStringArr)
        }
    }
    
    func updateExtraMessage(extraMessage: String?) {
        if (extraMessage != nil) {
            self.menu.updateExtraMessage(extraMessage: extraMessage)
        } else {
            self.menu.updateExtraMessage(extraMessage: nil)
        }
    }
    
    func updateOtherInfo(otherinfo: OtherInfoModel?) {
        if (otherinfo != nil) {
            self.menu.updateOtherInfo(otherinfo: otherinfo)
        } else {
            self.menu.updateOtherInfo(otherinfo: nil)
        }
    }
    
    func emptyHistoryMenu(entries: [String]) {
        self.menu.updateHistory(entries: entries)
    }
    
    init() {
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        self.statusItem.menu = self.menu.build()
        
        func destroyStatusItem() {
            // Remove the status item from the status bar
            NSStatusBar.system.removeStatusItem(self.statusItem)
            // Optionally, also remove the observer if it's no longer needed
            //        NotificationCenter.default.removeObserver(self, name: NSWindow.didChangeOcclusionStateNotification, object: self.statusItem.button?.window)
        }
    }
    func destroyStatusItem() {
    
    }
}
