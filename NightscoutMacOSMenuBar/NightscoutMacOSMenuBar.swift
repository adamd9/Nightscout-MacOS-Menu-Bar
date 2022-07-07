//
//  NightscoutMacOSMenuBar.swift
//  NightscoutMacOSMenuBar
//
//  Created by adam.d on 27/6/2022.
//

import SwiftUI
import Foundation
import Cocoa
import LaunchAtLogin
private let store = EntriesStore()
private let nsmodel = NightscoutModel()

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
    
    func updateDisplay(message: String, extraMessage: String?) {
        let myAttribute = [ NSAttributedString.Key.foregroundColor: NSColor.controlAccentColor ]
        let myAttrString = NSAttributedString(string: message, attributes: myAttribute)
        self.statusBarItem.button?.attributedTitle = myAttrString
        
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
        self.menu.addHistory(entries: historyStringArr)
    }
    
    func emptyHistoryMenu() {
        store.entries.removeAll()
        self.menu.addHistory(entries: [String]())
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

struct SettingsView: View {
    @AppStorage("nightscoutUrl") private var nightscoutUrl = ""
    @AppStorage("bgUnits") private var bgUnits = "mgdl"
    @State private var isUrlEditMode = false
    @State private var urlTemp = ""
    @EnvironmentObject private var settings: SettingsModel
    
    var body: some View {
        Form {
            HStack {
                TextField("Nightscout URL",
                          text: $settings.glUrlTemp,
                          onEditingChanged: { (isBegin) in
                    if isBegin {
                        settings.glUrl = nightscoutUrl
                        settings.glUrlTemp = settings.glUrl
                        print("Begins editing")
                    } else {
                        print("Finishes editing")
                    }
                },
                          onCommit: {
                    settings.glIsEdit = false
                    if settings.glUrlTemp.last == "/" {
                        settings.glUrlTemp = String(settings.glUrlTemp.dropLast())
                    }
                    nightscoutUrl = settings.glUrlTemp
                    settings.glUrl =  settings.glUrlTemp
                    getEntries()
                    print("commit")
                }
                )
                .disabled(settings.glIsEdit ? false : true)
                .onAppear {
                    settings.glUrl = nightscoutUrl
                    settings.glUrlTemp = settings.glUrl
                }
                
                if (settings.glIsEdit) {
                    Button("Cancel", action: {
                        settings.glUrl = nightscoutUrl
                        settings.glUrlTemp = nightscoutUrl
                        settings.glIsEdit = false
                    })
                    Button("Save", action: {
                        settings.glIsEdit = false
                    })
                } else {
                    Button("Edit", action: {
                        settings.glIsEdit = true
                    })
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            Picker("BG Reading Units:", selection: $bgUnits) {
                Text("mg/dL").tag("mgdl")
                Text("mmol/L").tag("mmol")
            }
            .onChange(of: bgUnits, perform: { _ in
                getEntries()
            })
            .pickerStyle(.inline)
            LaunchAtLogin.Toggle()
            HStack {
                Button("Cut", action: {
                    let pasteBoard = NSPasteboard.general
                    pasteBoard.clearContents()
                    pasteBoard.setString(settings.glUrlTemp, forType: .string)
                    settings.glUrlTemp = ""
                }).keyboardShortcut("x")
                
                Button("Copy", action: {
                    let pasteBoard = NSPasteboard.general
                    pasteBoard.clearContents()
                    pasteBoard.setString(settings.glUrlTemp, forType: .string)
                }).keyboardShortcut("c")
                Button("Paste", action: {
                    if let read = NSPasteboard.general.string(forType: .string) {
                        settings.glUrlTemp = read  // <-- here
                    }
                }).keyboardShortcut("v")
            }.opacity(0)
        }
        .padding(60)
        .frame(width: 600, height: 200)
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
                
                if (isStaleEntry(entry: store.entries[0], staleThresholdMin: 15)) {
                    nsmodel.updateDisplay(message: "[stale]", extraMessage: "No recent readings from CGM")
                } else {
                    nsmodel.updateDisplay(message: bgValueFormatted(entry: store.entries[0]), extraMessage: nil)
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
            nsmodel.populateHistoryMenu()
            nsmodel.updateDisplay(message: bgValueFormatted(entry: store.entries[0]) + "!", extraMessage: "Temporary network failure")
        }
        
    }
    
    func isValidURL(url: String) -> Bool {
        let regEx = "((https|http)://)((\\w|-)+)(([.]|[/])((\\w|-)+))+"
        let predicate = NSPredicate(format: "SELF MATCHES %@", argumentArray: [regEx])
        return predicate.evaluate(with: url)
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
