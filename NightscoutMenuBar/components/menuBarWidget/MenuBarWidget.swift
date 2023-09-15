//
//  MenuBarWidget.swift
//  Nightscout Menu Bar
//
//  Created by Adam Dinneen on 26/7/2023.
//

import SwiftUI
import Foundation
import Cocoa
import Combine
import Charts

protocol MenuBarWidgetProtocol {
    func updateDisplay(message: String, store: EntriesStore, extraMessage: String?)
    func populateHistoryMenu(store: EntriesStore)
    func updateOtherInfo(otherinfo: OtherInfoModel?)
    func emptyHistoryMenu(entries: [String])
    func updateExtraMessage(extraMessage: String?)
    func destroyStatusItem()
    func checkVisibility()
}

class MenuBarWidgetFactory {
    enum ItemType {
        case legacy
    }
    
    static func makeStatusItem(type: ItemType) -> MenuBarWidgetProtocol {
        return MenuBarWidgetLegacy()
    }
}

