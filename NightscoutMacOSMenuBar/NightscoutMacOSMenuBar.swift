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
let store = EntriesStore()
var statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
let menu = MainMenu()

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
//                        settings.glUrl = nightscoutUrl
//                        settings.glUrlTemp = nightscoutUrl
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
        
        // Here we are using a custom icon found in Assets.xcassets
        statusBarItem.button?.image = NSImage(named: NSImage.Name("sys-icon"))
        statusBarItem.button?.image?.size = NSSize(width: 18.0, height: 18.0)
        
        statusBarItem.button?.imagePosition = .imageLeading
        statusBarItem.menu = menu.build()
        getEntries()
        setupRefreshTimer()
    }
    
    private func setupRefreshTimer() {
        let refreshInterval: TimeInterval = 60
        Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { _ in getEntries() }
    }
    
}

func addEntry(rawEntry: String) {
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

func bgValueFormatted(entry: Entry? = nil) -> NSAttributedString {
    var myAttrString: NSAttributedString
    if (entry == nil) {
        let myAttribute = [ NSAttributedString.Key.foregroundColor: NSColor.red ]
        myAttrString = NSAttributedString(string: "Loading...", attributes: myAttribute)
        return myAttrString
    } else {
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
        var myAttribute = [ NSAttributedString.Key.foregroundColor: NSColor.controlAccentColor ]
        if (isStaleEntry(entry: entry!)) {
            bgVal = "[stale]"
            myAttribute = [ NSAttributedString.Key.foregroundColor: NSColor.red ]
        }
        myAttrString = NSAttributedString(string: bgVal, attributes: myAttribute)
    }
    
    return myAttrString
}

func isStaleEntry(entry: Entry) -> Bool {
    let fromNow = String(Int(minutesBetweenDates(entry.time, Date())))
    if (Int(fromNow)! > 15) {
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

func getEntries() {
    @AppStorage("nightscoutUrl") var nightscoutUrl = ""
    //        guard let url = URL(string: "https://adamd9nightscout.herokuapp.com/api/v1/entries") else { fatalError("Missing URL") }
    guard let url = URL(string: nightscoutUrl + "/api/v1/entries") else { return }
    
    let urlRequest = URLRequest(url: url)
    
    let dataTask = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
        if let error = error {
            print("Request error: ", error)
            return
        }
        guard let response = response as? HTTPURLResponse else {
            store.entries.removeAll()
            menu.addHistory(entries: store.entries)
            let bgVal = "[not connected]"
            let myAttribute = [ NSAttributedString.Key.foregroundColor: NSColor.red ]
            let myAttrString = NSAttributedString(string: bgVal, attributes: myAttribute)
            statusBarItem.button?.attributedTitle = myAttrString
            return
            
        }
        
        if response.statusCode == 200 {
            guard let data = data else {
                store.entries.removeAll()
                menu.addHistory(entries: store.entries)
                let bgVal = "[not connected]"
                let myAttribute = [ NSAttributedString.Key.foregroundColor: NSColor.red ]
                let myAttrString = NSAttributedString(string: bgVal, attributes: myAttribute)
                statusBarItem.button?.attributedTitle = myAttrString
                return
            }
            DispatchQueue.main.async {
                let responseData = String(data: data, encoding: String.Encoding.utf8)
                store.entries.removeAll()
                let entries = responseData!.components(separatedBy: .newlines)
                entries.forEach({entry in
                    addEntry(rawEntry: entry)
                })
                menu.addHistory(entries: store.entries)
                statusBarItem.button?.attributedTitle = bgValueFormatted(entry: store.entries.last)
            }
        } else {
            store.entries.removeAll()
            menu.addHistory(entries: store.entries)
            let bgVal = "[not connected]"
            let myAttribute = [ NSAttributedString.Key.foregroundColor: NSColor.red ]
            let myAttrString = NSAttributedString(string: bgVal, attributes: myAttribute)
            statusBarItem.button?.attributedTitle = myAttrString
        }
    }
    
    dataTask.resume()
}
