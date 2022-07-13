//
//  NightscoutMacOSMenuBar.swift
//  NightscoutMacOSMenuBar
//
//  Created by adam.d on 27/6/2022.
//

import SwiftUI
import Foundation
import Cocoa
private let store = EntriesStore()
private let nsmodel = NightscoutModel()
private let otherinfo = OtherInfoModel()

@main
struct NightscountOSXMenuAppApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var settings = SettingsModel()

    var body: some Scene {
        Settings {
            SettingsView()
                .onReceive(NotificationCenter.default.publisher(for: NSApplication.willResignActiveNotification)) { _ in
                    print("inactive")
                    settings.glUrlTemp = settings.glUrl
                    settings.glIsEdit = false
                }
                .environmentObject(settings)
        }
    }
}

class NightscoutModel: ObservableObject {
    private let menu = MainMenu()
    private var statusBarItem: NSStatusItem
    
    func updateDisplay(message: String, otherinfo: OtherInfoModel? ,extraMessage: String?) {
        let myAttribute = [ NSAttributedString.Key.foregroundColor: NSColor.controlAccentColor ]
        let myAttrString = NSAttributedString(string: message, attributes: myAttribute)
        self.statusBarItem.button?.attributedTitle = myAttrString
        
        if (otherinfo != nil && otherinfo?.isOtherInfoEnabled == true) {
            self.menu.updateOtherInfo(otherinfo: otherinfo)
        } else {
            self.menu.updateOtherInfo(otherinfo: nil)
        }
        if (extraMessage != nil) {
            self.menu.updateExtraMessage(extraMessage: extraMessage)
        } else {
            self.menu.updateExtraMessage(extraMessage: nil)
        }
    }
    
    func populateHistoryMenu() {
        store.orderByTime()
        var historyStringArr = [String]()
        store.entries.forEach({entry in
            historyStringArr.append(bgValueFormatted(entry: entry) + " " + bgMinsAgo(entry: entry) + " m")
        })
        self.menu.updateHistory(entries: historyStringArr)
    }
    
    func emptyHistoryMenu() {
        store.entries.removeAll()
        self.menu.updateHistory(entries: [String]())
    }
    
    init() {
        self.statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        self.statusBarItem.button?.image = NSImage(named: NSImage.Name("sys-icon"))
        self.statusBarItem.button?.image?.size = NSSize(width: 18.0, height: 18.0)
        self.statusBarItem.button?.imagePosition = .imageLeading
        self.statusBarItem.menu = self.menu.build()
    }
}

class SettingsModel: ObservableObject {
    @Published var glIsEdit = false
    @Published var glUrl = ""
    @Published var glUrlTemp = ""
}

class OtherInfoModel: ObservableObject {
    @Published var isOtherInfoEnabled = false
    @Published var loopIob = ""
    @Published var loopCob = ""
    @Published var pumpReservoir = ""
    @Published var pumpBatt = ""
    @Published var pumpAgo = ""
    @Published var cgmSensorAge = ""
    @Published var cgmTransmitterAge = ""
    @Published var loopPredictions = NSArray()
    
}

class AppDelegate: NSObject, NSApplicationDelegate {
    static private(set) var instance: AppDelegate!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        AppDelegate.instance = self
        
        getEntries()
        setupRefreshTimer()
    }
    
    private func setupRefreshTimer() {
        let refreshInterval: TimeInterval = 60
        Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { _ in getEntries() }
    }
    
}

func addRawEntry(rawEntry: String) {
    let entryArr = rawEntry.components(separatedBy: "\t") as [String]
    if (entryArr.count > 2) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        let time = dateFormatter.date(from: entryArr[0].replacingOccurrences(of: "\"", with: ""))!
        let bgMg = Int(entryArr[2])!
        //round to 2dp
        let bgMmol = (Double(bgMg)/18*10).rounded()/10
        let direction = String(entryArr[3].replacingOccurrences(of: "\"", with: ""))
        
        let newEntry = Entry(time: time, bgMg: bgMg, bgMmol: bgMmol, direction: direction)
        store.entries.insert(newEntry, at: 0)
    }
}

func getEntries() {
    @AppStorage("nightscoutUrl") var nightscoutUrl = ""
    let fullNightscoutUrl = nightscoutUrl + "/api/v1/entries"

    if (isValidURL(url: fullNightscoutUrl) == false) {
        handleNetworkFail(reason: "isValidUrl failed")
        return
    }
    guard let url = URL(string: fullNightscoutUrl) else {
        handleNetworkFail(reason: "create URL failed")
        return
        
    }
    
    let urlRequest = URLRequest(url: url)
    
    let dataTask = URLSession(configuration: .ephemeral).dataTask(with: urlRequest) { (data, response, error) in
        if let error = error {
            print("Request error: ", error)
            return
        }
        guard let response = response as? HTTPURLResponse else {
            handleNetworkFail(reason: "not a valid HTTP response")
            return
            
        }
        
        if response.statusCode == 200 {
            guard let data = data else {
                handleNetworkFail(reason: "no data in response")
                return
            }
            DispatchQueue.main.async {
                let responseData = String(data: data, encoding: String.Encoding.utf8)
                store.entries.removeAll()
                let entries = responseData!.components(separatedBy: .newlines)
                entries.forEach({entry in addRawEntry(rawEntry: entry) })
                if (store.entries.isEmpty) {
                    handleNetworkFail(reason: "no valid data")
                    return
                }
                nsmodel.populateHistoryMenu()
                getProperties()
                
                if (isStaleEntry(entry: store.entries[0], staleThresholdMin: 15)) {
                    nsmodel.updateDisplay(message: "[stale]", otherinfo: otherinfo,extraMessage: "No recent readings from CGM")
                } else {
                    nsmodel.updateDisplay(message: bgValueFormatted(entry: store.entries[0]), otherinfo: otherinfo, extraMessage: nil)
                }
            }
        } else {
            DispatchQueue.main.async {
                handleNetworkFail(reason: "response code was " + String(response.statusCode))
            }
        }
    }
    dataTask.resume()
    
    func handleNetworkFail(reason: String) {
        print("Network error source: " + reason)
        if (store.entries.isEmpty || isStaleEntry(entry: store.entries[0], staleThresholdMin: 15)) {
            nsmodel.emptyHistoryMenu()
            nsmodel.updateDisplay(message: "[network]", otherinfo: otherinfo, extraMessage: reason)
        } else {
            nsmodel.populateHistoryMenu()
            nsmodel.updateDisplay(message: bgValueFormatted(entry: store.entries[0]) + "!", otherinfo: otherinfo, extraMessage: "Temporary network failure")
        }
        
    }
    
    func isValidURL(url: String) -> Bool {
        let regEx = "((https|http)://)((\\w|-)+)(([.]|[/])((\\w|-)+))+"
        let predicate = NSPredicate(format: "SELF MATCHES %@", argumentArray: [regEx])
        return predicate.evaluate(with: url)
    }
}

func getProperties() {
    @AppStorage("nightscoutUrl") var nightscoutUrl = ""
    let fullNightscoutUrl = nightscoutUrl + "/api/v2/properties"

    if (isValidURL(url: fullNightscoutUrl) == false) {
        handleNetworkFail(reason: "isValidUrl failed")
        return
    }
    guard let url = URL(string: fullNightscoutUrl) else {
        handleNetworkFail(reason: "create URL failed")
        return
        
    }
    
    let urlRequest = URLRequest(url: url)
    
    let dataTask = URLSession(configuration: .ephemeral).dataTask(with: urlRequest) { (data, response, error) in
        if let error = error {
            print("Request error: ", error)
            return
        }
        guard let response = response as? HTTPURLResponse else {
            handleNetworkFail(reason: "not a valid HTTP response")
            return
            
        }
        
        if response.statusCode == 200 {
            guard let data = data else {
                handleNetworkFail(reason: "no data in response")
                return
            }
            DispatchQueue.main.async {
                if let json = try! JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] {
                    parseExtraInfo(properties: json)
                }
            }
        } else {
            DispatchQueue.main.async {
                handleNetworkFail(reason: "response code was " + String(response.statusCode))
            }
        }
    }
    dataTask.resume()
    
    func handleNetworkFail(reason: String) {
        print("Network error source: " + reason)
        if (store.entries.isEmpty || isStaleEntry(entry: store.entries[0], staleThresholdMin: 15)) {
            nsmodel.emptyHistoryMenu()
            nsmodel.updateDisplay(message: "[network]", otherinfo: otherinfo, extraMessage: reason)
        } else {
            nsmodel.populateHistoryMenu()
            nsmodel.updateDisplay(message: bgValueFormatted(entry: store.entries[0]) + "!", otherinfo: otherinfo, extraMessage: "Temporary network failure")
        }
        
    }
    
    func isValidURL(url: String) -> Bool {
        let regEx = "((https|http)://)((\\w|-)+)(([.]|[/])((\\w|-)+))+"
        let predicate = NSPredicate(format: "SELF MATCHES %@", argumentArray: [regEx])
        return predicate.evaluate(with: url)
    }
}

func parseExtraInfo(properties: [String: Any]) {
    //get IOB
    if let iob = properties["iob"] as? [String: Any] {
        if let iobDisplay = iob["display"] as? String {
            otherinfo.loopIob = String(iobDisplay)
        }
    }
    
    //get COB
    if let cob = properties["cob"] as? [String: Any] {
        if let cobDisplay = cob["display"] as? Int {
            otherinfo.loopCob = String(cobDisplay)
        }
    }

    //get Pump Info
    if let pump = properties["pump"] as? [String: Any] {
        
        //get device stats
        if let pumpData = pump["data"] as? [String: Any] {
            //clock
            if let pumpDataClock = pumpData["clock"] as? [String: Any] {
                if let pumpDataClockDisplay = pumpDataClock["display"] as? String {
                    otherinfo.pumpAgo = pumpDataClockDisplay
                }
            }
            //battery
            if let pumpDataBattery = pumpData["battery"] as? [String: Any] {
                if let pumpDataBatteryDisplay = pumpDataBattery["display"] as? String {
                    otherinfo.pumpBatt = pumpDataBatteryDisplay
                }
            }
            //reservoir
            if let pumpDataReservoir = pumpData["reservoir"] as? [String: Any] {
                if let pumpDataReservoirDisplay = pumpDataReservoir["display"] as? String {
                    otherinfo.pumpReservoir = pumpDataReservoirDisplay
                }
            }
        }
        
        //get loop stats
        if let pumpLoop = pump["loop"] as? [String: Any] {
            if let pumpLoopPredicted = pumpLoop["predicted"] as? [String: Any] {
                if let pumpLoopPredictedValues = pumpLoopPredicted["values"] as? NSArray {
                    otherinfo.loopPredictions = pumpLoopPredictedValues
                }
            }
        }
    }
    if (otherinfo.loopIob.isEmpty && otherinfo.loopCob.isEmpty && otherinfo.pumpAgo.isEmpty && otherinfo.pumpBatt.isEmpty && otherinfo.pumpReservoir.isEmpty) {
        otherinfo.isOtherInfoEnabled = false
    } else {
        otherinfo.isOtherInfoEnabled = true
    }
}

func bgValueFormatted(entry: Entry? = nil) -> String {
    @AppStorage("bgUnits") var userPrefBg = "mgdl"
    var bgVal = ""
    if (userPrefBg == "mmol") {
        bgVal = String(entry!.bgMmol)
    } else {
        bgVal = String(entry!.bgMg)
    }
    switch entry!.direction {
    case "":
        bgVal += ""
    case "Flat":
        bgVal += " →"
    case "FortyFiveDown":
        bgVal += " ➘"
    case "FortyFiveUp":
        bgVal += " ➚"
    case "SingleUp":
        bgVal += " ➚"
    case "DoubleUp":
        bgVal += " ↑↑"
    case "SingleDown":
        bgVal += " ↓"
    case "DoubleDown":
        bgVal += " ↓↓"
    default:
        bgVal += " *"
        print("Unknown direction: " + entry!.direction)
    }
    return bgVal
}

func bgMinsAgo(entry: Entry? = nil) -> String {
    if (entry == nil) {
        return ""
    }
    
    let fromNow = String(Int(minutesBetweenDates(entry!.time, Date())))
    return fromNow
}

func isStaleEntry(entry: Entry, staleThresholdMin: Int) -> Bool {
    let fromNow = String(Int(minutesBetweenDates(entry.time, Date())))
    if (Int(fromNow)! > staleThresholdMin) {
        return true
    } else {
        return false
    }
}

func minutesBetweenDates(_ oldDate: Date, _ newDate: Date) -> CGFloat {
    
    //get both times sinces refrenced date and divide by 60 to get minutes
    let newDateMinutes = newDate.timeIntervalSinceReferenceDate/60
    let oldDateMinutes = oldDate.timeIntervalSinceReferenceDate/60
    
    //then return the difference
    return CGFloat(newDateMinutes - oldDateMinutes)
}
