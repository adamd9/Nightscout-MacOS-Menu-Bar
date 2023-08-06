//
//  PreferencesView.swift
//  NightscoutMenuBar
//
//  Created by adam.d on 10/7/2022.
//

import Foundation
import SwiftUI
import LaunchAtLogin

struct SettingsView: View {
    @AppStorage("nightscoutUrl") private var nightscoutUrl = ""
    @AppStorage("accessToken") private var accessToken = ""
    @AppStorage("bgUnits") private var bgUnits = "mgdl"
    @AppStorage("showLoopData") private var showLoopData = false
    @AppStorage("displayShowUpdateTime") private var displayShowUpdateTime = false
    @AppStorage("displayShowBGDifference") private var displayShowBGDifference = false
    @AppStorage("graphEnabled") private var graphEnabled = false
    @AppStorage("useLegacyStatusItem") private var useLegacyStatusItem = false
    @AppStorage("displayNSIcon") private var displayNSIcon = true
    @EnvironmentObject private var settings: SettingsModel
    @State var isOn = false
    @State var showAlert = false
    
    var body: some View {
        Form {
            Text("To copy/paste, right-click inside the text field")
            HStack {
                TextField("Nightscout URL",
                          text: $settings.glUrlTemp,
                          onEditingChanged: { (isBegin) in
                    if isBegin {
                        settings.glUrl = nightscoutUrl
                        settings.glUrlTemp = settings.glUrl
                        settings.activeTextField = "url"
                        print("Begins editing URL")
                    } else {
                        print("Finishes editing URL")
                    }
                },
                          onCommit: {
                    settings.glIsEdit = false
                    if (settings.glUrlTemp != "") {
                        let rawUrl = URL(string: settings.glUrlTemp)!
                        if (rawUrl.port != nil) {
                            settings.glUrlTemp = (rawUrl.scheme ?? "") + "://" + (rawUrl.host ?? "") + (":" + String(rawUrl.port!))
                        } else {
                            settings.glUrlTemp = (rawUrl.scheme ?? "") + "://" + (rawUrl.host ?? "")
                        }
                    }
                    
                    nightscoutUrl = settings.glUrlTemp
                    settings.glUrl =  settings.glUrlTemp
                    getEntries()
                    print("commit")
                }
                )
                .disabled(settings.glIsEdit ? false : true)
                .onChange(of: settings.glUrlTemp, perform: {newValue in
                    settings.glUrlTemp = removeNewlinesAndWhitespace(from: settings.glUrlTemp)
                })
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
            
            HStack {
                TextField("Token value (optional)",
                          text: $settings.glTokenTemp,
                          onEditingChanged: { (isBegin) in
                    if isBegin {
                        settings.glToken = accessToken
                        settings.glTokenTemp = settings.glToken
                        settings.activeTextField = "token"
                        print("Begins editing token key")
                    } else {
                        print("Finishes editing token key")
                    }
                },
                          onCommit: {
                    settings.glIsEditToken = false
                    accessToken = settings.glTokenTemp
                    settings.glToken =  settings.glTokenTemp
                    getEntries()
                    print("commit")
                }
                )
                .onChange(of: settings.glTokenTemp, perform: {newValue in
                    settings.glTokenTemp = removeNewlinesAndWhitespace(from: settings.glTokenTemp)
                })
                .disabled(settings.glIsEditToken ? false : true)
                .onAppear {
                    settings.glToken = accessToken
                    settings.glTokenTemp = settings.glToken
                }
                
                if (settings.glIsEditToken) {
                    Button("Cancel", action: {
                        settings.glToken = accessToken
                        settings.glTokenTemp = accessToken
                        settings.glIsEditToken = false
                    })
                    Button("Save", action: {
                        
                        let tokenPattern = #"^\w+-\w+$"#
                        
                        let result = settings.glTokenTemp.range(
                            of: tokenPattern,
                            options: .regularExpression
                        )
                        
                        let validToken = (result != nil || settings.glTokenTemp == "")
                        if (validToken) {
                            print(settings.glTokenTemp)
                            settings.glIsEditToken = false
                        } else {
                            isOn = true
                        }
                    })
                } else {
                    Button("Edit", action: {
                        settings.glIsEditToken = true
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
            .pickerStyle(.segmented)
            .frame(width: 300)
            
            Picker("Graph in menu bar:", selection: $graphEnabled) {
                Text("Off").tag(false)
                Text("On").tag(true)
            }
            .onChange(of: graphEnabled, perform: { _ in
                getEntries()
            })
            .pickerStyle(.segmented)
            .frame(width: 400)
            
            Section {
                LaunchAtLogin.Toggle()
                Toggle("Show Loop data (IOB, COB, Pump info)", isOn:$showLoopData)
                    .toggleStyle(.checkbox)
                    .onChange(of: showLoopData, perform: { _ in
                        getEntries()
                    })
                Toggle("Show Icon in Menu Bar", isOn:$displayNSIcon)
                    .toggleStyle(.checkbox)
                    .onChange(of: displayNSIcon, perform: { _ in
                        getEntries()
                    })
                Toggle("Show BG difference from previous reading in Menu Bar", isOn:$displayShowBGDifference)
                    .toggleStyle(.checkbox)
                    .onChange(of: displayShowBGDifference, perform: { _ in
                        getEntries()
                    })
                
                Toggle("Show last update time in Menu Bar", isOn:$displayShowUpdateTime)
                    .toggleStyle(.checkbox)
                    .onChange(of: displayShowUpdateTime, perform: { _ in
                        getEntries()
                    })
            }
            Spacer(minLength: 20)
            Section (header: Text("Advanced Settings")) {
                Toggle("Use Legacy style of menu item", isOn:$useLegacyStatusItem)
                    .toggleStyle(.checkbox)
                    .onChange(of: useLegacyStatusItem, perform: { _ in
                        reset()
                    })
                HStack {
                    Text("Reset All Settings")
                    Button("Reset and relaunch app") {
                        showAlert = true
                    }
                }
            }

        }
        .padding(60)
        .frame(width: 800, height: 400)
        .alert(isPresented: $isOn) {
            Alert(title: Text("Token is invalid!"),
                  message: Text("Please make sure you're entering an access token (Admin Tools > Subjects) and NOT your API_SECRET token."),
                  dismissButton: .default(Text("OK")))
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Are you sure?"),
                  message: Text("All your settings will be reset and you'll need to reconfigure the app."),
                  primaryButton: .default(
                    Text("OK"),
                    action: resetAllSettingsAndQuit
                  ),
                  secondaryButton: .cancel(
                    Text("Cancel"),
                    action: {showAlert = false}
                  )
            )
        }
    }
    
    func removeNewlinesAndWhitespace(from text: String) -> String {
        let pattern = "[\\n\\r\\t ]"
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let range = NSRange(location: 0, length: text.utf16.count)
            let modifiedString = regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: "")
            return modifiedString
        } catch {
            print("Regex Error: \(error)")
            return text
        }
    }
    
    func resetAllSettingsAndQuit() {
        showAlert = true
        nightscoutUrl = ""
        accessToken = ""
        bgUnits = "mgdl"
        showLoopData = false
        displayShowUpdateTime = false
        displayShowBGDifference = false
        graphEnabled = false
        let task = Process()
        task.launchPath = "/usr/bin/env"
        task.arguments = ["open", Bundle.main.bundlePath]
        task.launch()
        NSApp.terminate(nil)
    }
}

