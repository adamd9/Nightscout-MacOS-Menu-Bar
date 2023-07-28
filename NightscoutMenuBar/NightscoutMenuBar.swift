//
//  NightscoutMenuBar.swift
//  NightscoutMenuBar
//
//  Created by adam.d on 27/6/2022.
//

import SwiftUI
import Foundation
import Cocoa
import Combine
import Charts

private let store = EntriesStore()
private let nsmodel = NightscoutModel()
private let otherinfo = OtherInfoModel()

@main
struct NightscoutMenuBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var settings = SettingsModel()
    
    var body: some Scene {
        Settings {
            SettingsView()
                .onReceive(NotificationCenter.default.publisher(for: NSApplication.willResignActiveNotification)) { _ in
                    print("inactive")
                    settings.glUrlTemp = settings.glUrl
                    settings.glIsEdit = false
                    settings.glTokenTemp = settings.glToken
                    settings.glIsEditToken = false
                }
                .environmentObject(settings)
        }
    }
}

class NightscoutModel: ObservableObject {
    private let menu = MainMenu()
    var statusItem: StatusItemProtocol

    func updateDisplay(message: String ,extraMessage: String?) {
        @AppStorage("useLegacyStatusItem") var useLegacyStatusItem = false
        statusItem = StatusItemFactory.makeStatusItem(type: useLegacyStatusItem ? .legacy : .normal)
        nsmodel.statusItem.updateDisplay(message: message, store: store, extraMessage: extraMessage)
    }
    
    func emptyHistoryMenu() {
        store.entries.removeAll()
        nsmodel.statusItem.emptyHistoryMenu(entries: [String]())
    }
    
    init() {
        @AppStorage("useLegacyStatusItem") var useLegacyStatusItem = false
        statusItem = StatusItemFactory.makeStatusItem(type: useLegacyStatusItem ? .legacy : .normal)
    }
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
        //Round mmol to 1dp
        let bgMmol = helpers().convertbgMgToMmol(bgMg: bgMg)
        let direction = String(entryArr[3].replacingOccurrences(of: "\"", with: ""))
        
        let newEntry = Entry(time: time, bgMg: bgMg, bgMmol: bgMmol, direction: direction)
        store.entries.insert(newEntry, at: 0)
    }
}

func getEntries() {
    @AppStorage("nightscoutUrl") var nightscoutUrl = ""
    @AppStorage("accessToken") var accessToken = ""
    @AppStorage("showLoopData") var showLoopData = false
    
    nsmodel.updateDisplay(message: "...",extraMessage: "Getting initial entries...")
    if (nightscoutUrl == "") {
        handleNetworkFail(reason: "Add your Nightscout URL in Preferences")
        return
    }
    
    var fullNightscoutUrl = ""
    
    if (accessToken != "") {
        fullNightscoutUrl = nightscoutUrl + "/api/v1/entries?token=" + accessToken
    } else {
        fullNightscoutUrl = nightscoutUrl + "/api/v1/entries"
    }

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
                nsmodel.statusItem.populateHistoryMenu(store: store)
                if (showLoopData == true) {
                    getProperties()
                }
                
                if (isStaleEntry(entry: store.entries[0], staleThresholdMin: 15)) {
                    nsmodel.updateDisplay(message: "???",extraMessage: "No recent readings from CGM")
                } else {
                    
                    if (showLoopData == true && pumpDataIndicator() != "") {
                        nsmodel.updateDisplay(message: pumpDataIndicator() + " " + bgValueFormatted(entry: store.entries[0]), extraMessage: "No recent data from Pump")
                    } else {
                        nsmodel.updateDisplay(message: bgValueFormatted(entry: store.entries[0]), extraMessage: nil)
//                        nsmodel.updateDisplay(message: bgValueFormatted(entry: store.entries[0]), store: store, extraMessage: nil)
                    }
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
            nsmodel.updateDisplay(message: "[network]", extraMessage: reason)
        } else {
            nsmodel.statusItem.populateHistoryMenu(store: store)
            nsmodel.updateDisplay(message: bgValueFormatted(entry: store.entries[0]) + "!", extraMessage: "Temporary network failure")
        }
        
    }
    
    func isValidURL(url: String) -> Bool {
        let urlToVal: NSURL? = NSURL(string: url)

        if urlToVal != nil {
            return true
        }
        return false
    }
}


func pumpDataIndicator() -> String {
    let pumpAgo = otherinfo.pumpAgo
    let pumpAgoRange = NSRange(
        pumpAgo.startIndex..<pumpAgo.endIndex,
        in: pumpAgo
    )

    print(pumpAgo)
    // Create A NSRegularExpression
    let capturePattern =
        #"(?<val>\d+)"# +
        #"(?<unit>.)"# +
    #".+"#

    let pumpAgoRegex = try! NSRegularExpression(
        pattern: capturePattern,
        options: []
    )
    
    // Find the matching capture groups
    let matches = pumpAgoRegex.matches(
        in: pumpAgo,
        options: [],
        range: pumpAgoRange
    )

    guard let match = matches.first else {
        // Handle exception
        print("couldn't match regex for pumpAgo")
        return ""
    }
    
    var captures: [String: String] = [:]

    // For each matched range, extract the named capture group
    for name in ["val", "unit"] {
        let matchRange = match.range(withName: name)
        // Extract the substring matching the named capture group
        if let substringRange = Range(matchRange, in: pumpAgo) {
            let capture = String(pumpAgo[substringRange])
            captures[name] = capture
        }
    }

    let pumpAgoVal = Int(captures["val"] ?? "0") ?? 0
    if (captures["unit"] == "m" && pumpAgoVal > 0) {
        if (pumpAgoVal > 5) {
            return "⚠"
        }
        
        if (pumpAgoVal > 20) {
            return "☇"
        }
    }
    if (captures["unit"] == "h") {
        return "☇"
    }
    return ""
}

func getProperties() {
    @AppStorage("nightscoutUrl") var nightscoutUrl = ""
    @AppStorage("accessToken") var accessToken = ""
    
    var fullNightscoutUrl = ""
    
    if (accessToken != "") {
        fullNightscoutUrl = nightscoutUrl + "/api/v2/properties?token=" + accessToken
    } else {
        fullNightscoutUrl = nightscoutUrl + "/api/v2/properties"
    }
    
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
        print("Network error getting other info: " + reason)
        
    }
    
    func isValidURL(url: String) -> Bool {
        let urlToVal: NSURL? = NSURL(string: url)

        if urlToVal != nil {
            return true
        }
        return false
    }
}

func parseExtraInfo(properties: [String: Any]) {
    //get IOB
    if let iob = properties["iob"] as? [String: Any] {
        if let iobDisplay = iob["display"] as? Int {
            otherinfo.loopIob = String(iobDisplay)
        } else if let iobDisplay = iob["display"] as? Double {
            otherinfo.loopIob = String(iobDisplay)
        } else if let iobDisplay = iob["display"] as? String {
            otherinfo.loopIob = iobDisplay
        } else {
            print("iob not found")
        }
    } else {
        print("iob not found")
    }
    
    //get COB
    if let cob = properties["cob"] as? [String: Any] {
        if let cobDisplay = cob["display"] as? Int {
            otherinfo.loopCob = String(cobDisplay)
        } else if let cobDisplay = cob["display"] as? Double {
            otherinfo.loopCob = String(cobDisplay)
        } else if let cobDisplay = cob["display"] as? String {
            otherinfo.loopCob = cobDisplay
        } else {
            print("cob not found")
        }
    } else {
        print("cob not found")
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
                else {
                    print("pump clock not found")
                }
            }                 else {
                print("pump clock not found")
            }
            //battery
            if let pumpDataBattery = pumpData["battery"] as? [String: Any] {
                if let pumpDataBatteryDisplay = pumpDataBattery["display"] as? String {
                    otherinfo.pumpBatt = pumpDataBatteryDisplay
                } else {
                    print("pump batt not found")
                }
            } else {
                print("pump batt not found")
            }
            //reservoir
            if let pumpDataReservoir = pumpData["reservoir"] as? [String: Any] {
                if let pumpDataReservoirDisplay = pumpDataReservoir["display"] as? String {
                    otherinfo.pumpReservoir = pumpDataReservoirDisplay
                } else {
                    print("pump res not found")
                }
            } else {
                print("pump res not found")
            }
        } else {
            print("pump details not found")
        }
        
        //get loop stats
//        if let pumpLoop = pump["loop"] as? [String: Any] {
//            if let pumpLoopPredicted = pumpLoop["predicted"] as? [String: Any] {
//                if let pumpLoopPredictedValues = pumpLoopPredicted["values"] as? NSArray {
//                    otherinfo.loopPredictions = pumpLoopPredictedValues
//                }
//            }
//        }
    } else {
        print("pump not found")
    }
    if (otherinfo.loopIob.isEmpty || otherinfo.loopCob.isEmpty || otherinfo.pumpAgo.isEmpty || otherinfo.pumpBatt.isEmpty || otherinfo.pumpReservoir.isEmpty) {
        print("Unable to get all loop properties")
    }
    nsmodel.statusItem.updateOtherInfo(otherinfo: otherinfo)
}

func bgValueFormatted(entry: Entry? = nil) -> String {
    @AppStorage("bgUnits") var userPrefBg = "mgdl"
    @AppStorage("showLoopData") var showLoopData = false
    @AppStorage("displayShowUpdateTime") var displayShowUpdateTime = false
    @AppStorage("displayShowBGDifference") var displayShowBGDifference = false
    
    var bgVal = ""
    
    if (userPrefBg == "mmol") {
        bgVal += String(entry!.bgMmol)
    } else {
        bgVal += String(entry!.bgMg)
    }
    switch entry!.direction {
    case "":
        bgVal += ""
    case "NONE":
        bgVal += " →"
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
    
    if (displayShowBGDifference == true) {
        
        if (userPrefBg == "mmol") {
            let n = Double(store.entries[0].bgMmol - store.entries[1].bgMmol);
            //Round mmol to 1dp
            bgVal += " " + String(format: "%.1f", n)
        } else {
            bgVal += " " + String(store.entries[0].bgMg - store.entries[1].bgMg)
        }
    }
    
    if (displayShowUpdateTime == true) {
        bgVal += " " + bgMinsAgo(entry: store.entries[0]) + " m"
    }
    return bgVal
}

func bgValueFormattedHistory(entry: Entry? = nil) -> String {
    @AppStorage("bgUnits") var userPrefBg = "mgdl"
    @AppStorage("showLoopData") var showLoopData = false
    
    var bgVal = ""
    
    if (userPrefBg == "mmol") {
        bgVal += String(entry!.bgMmol)
    } else {
        bgVal += String(entry!.bgMg)
    }
    switch entry!.direction {
    case "":
        bgVal += ""
    case "NONE":
        bgVal += " →"
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
