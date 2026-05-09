//
//  PreferencesView.swift
//  NightscoutMenuBar
//
//  Created by adam.d on 10/7/2022.
//

import Foundation
import SwiftUI
import ServiceManagement

enum ActiveAlert {
    case invalidToken, resetConfirm
}

struct SettingsView: View {
    @AppStorage("nightscoutUrl") private var nightscoutUrl = ""
    @AppStorage("accessToken") private var accessToken = ""
    @AppStorage("bgUnits") private var bgUnits = "mgdl"
    @AppStorage("showLoopData") private var showLoopData = false
    @AppStorage("displayShowUpdateTime") private var displayShowUpdateTime = false
    @AppStorage("displayShowBGDifference") private var displayShowBGDifference = false
    @AppStorage("displayShowIOB") private var displayShowIOB = false
    @AppStorage("showHiddenWarning") private var showHiddenWarning = true
    @AppStorage("graphEnabled") private var graphEnabled = false
    @AppStorage("useLegacyStatusItem") private var useLegacyStatusItem = false
    @AppStorage("displayNSIcon") private var displayNSIcon = true
    @AppStorage("launchAtLoginPreference") private var launchAtLoginPreference = true
    @AppStorage("launchAtLoginPreferenceInitialized") private var launchAtLoginPreferenceInitialized = false
    @EnvironmentObject private var settings: SettingsModel
    @State var showAlert = false
    @State var activeAlert: ActiveAlert = .invalidToken
    @State private var launchAtLoginEnabled = false
    
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
                    settings.glTokenTemp = removeTokenFieldControlChars(from: settings.glTokenTemp)
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

                        let siteIsGluroo = isGlurooSite(urlString: preferredSiteUrl())
                        let result = settings.glTokenTemp.range(of: tokenPattern, options: .regularExpression)
                        let validToken = siteIsGluroo ? true : (result != nil || settings.glTokenTemp == "")
                        if (validToken) {
                            print(settings.glTokenTemp)
                            settings.glIsEditToken = false
                        } else {
                            print("Token is invalid!")
                            activeAlert = .invalidToken
                            showAlert = true
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
                Toggle("Launch at login", isOn: Binding(
                    get: { launchAtLoginEnabled },
                    set: { newValue in
                        launchAtLoginEnabled = newValue
                        setLaunchAtLogin(enabled: newValue, persistPreference: true)
                    }
                ))
                .toggleStyle(.checkbox)
                Toggle("Show Loop data (IOB, COB, Pump info)", isOn:$showLoopData)
                    .toggleStyle(.checkbox)
                    .onChange(of: showLoopData, perform: { _ in
                        getEntries()
                    })
                Toggle("Show Nightscout icon in Menu Bar", isOn:$displayNSIcon)
                    .toggleStyle(.checkbox)
                    .onChange(of: displayNSIcon, perform: { _ in
                        getEntries()
                    })
                Toggle("Show IOB (Insulin on Board) in Menu Bar", isOn:$displayShowIOB)
                    .toggleStyle(.checkbox)
                    .onChange(of: displayShowIOB, perform: { _ in
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
                Toggle("Warn when Menu Bar item is hidden by the OS", isOn:$showHiddenWarning)
                    .toggleStyle(.checkbox)
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
                        activeAlert = .resetConfirm
                        showAlert = true
                    }
                }
            }
            
        }
        .padding(60)
        .frame(width: 800, height: 400)
        .alert(isPresented: $showAlert) {
            switch activeAlert {
            case .invalidToken:
                return Alert(title: Text("Token is invalid!"),
                             message: Text(tokenValidationAlertMessage()),
                             dismissButton: .default(Text("OK"),action: {showAlert = false}))
            case .resetConfirm:
                return Alert(title: Text("Are you sure?"),
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
        .onAppear {
            configureLaunchAtLoginOnAppear()
            NSApplication.shared.activate(ignoringOtherApps: true)
        }
    }

    func preferredSiteUrl() -> String {
        let draft = settings.glUrlTemp.trimmingCharacters(in: .whitespacesAndNewlines)
        if !draft.isEmpty {
            return draft
        }
        return nightscoutUrl.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func isGlurooSite(urlString: String) -> Bool {
        guard let host = URL(string: urlString)?.host?.lowercased() else {
            return false
        }

        let supportedHosts = ["gluroo.com", "gluru.com"]
        return supportedHosts.contains(where: { host == $0 || host.hasSuffix("." + $0) })
    }

    func tokenValidationAlertMessage() -> String {
        if isGlurooSite(urlString: preferredSiteUrl()) {
            return "For Gluroo sites, API secrets are allowed. For other sites, please use a Nightscout access token (Admin Tools > Subjects)."
        }
        return "Please make sure you're entering an access token (Admin Tools > Subjects) and NOT your API_SECRET token."
    }

    func legacyLaunchAtLoginPreference() -> Bool? {
        let defaults = UserDefaults.standard
        let legacyKeys = ["LaunchAtLogin", "launchAtLogin", "LaunchAtLoginEnabled", "launchAtLoginEnabled"]
        for key in legacyKeys {
            if let value = defaults.object(forKey: key) as? Bool {
                return value
            }
        }
        return nil
    }

    func configureLaunchAtLoginOnAppear() {
        guard #available(macOS 13.0, *) else {
            launchAtLoginEnabled = false
            return
        }

        if !launchAtLoginPreferenceInitialized {
            if let legacyPreference = legacyLaunchAtLoginPreference() {
                launchAtLoginPreference = legacyPreference
            }

            setLaunchAtLogin(enabled: launchAtLoginPreference, persistPreference: false)
            launchAtLoginPreferenceInitialized = true
            return
        }

        refreshLaunchAtLoginState()
        launchAtLoginPreference = launchAtLoginEnabled
    }

    func refreshLaunchAtLoginState() {
        if #available(macOS 13.0, *) {
            launchAtLoginEnabled = SMAppService.mainApp.status == .enabled
        } else {
            launchAtLoginEnabled = false
        }
    }

    func setLaunchAtLogin(enabled: Bool, persistPreference: Bool) {
        guard #available(macOS 13.0, *) else {
            launchAtLoginEnabled = false
            return
        }

        if persistPreference {
            launchAtLoginPreference = enabled
        }

        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Failed to update launch at login setting: \(error)")
        }

        refreshLaunchAtLoginState()
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

    func removeTokenFieldControlChars(from text: String) -> String {
        let pattern = "[\\n\\r\\t]"
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let range = NSRange(location: 0, length: text.utf16.count)
            return regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: "")
        } catch {
            print("Regex Error: \(error)")
            return text
        }
    }
    
    func resetAllSettingsAndQuit() {
        showAlert = false
        nightscoutUrl = ""
        accessToken = ""
        bgUnits = "mgdl"
        showLoopData = false
        displayShowUpdateTime = false
        displayShowBGDifference = false
        displayShowIOB = false
        graphEnabled = false
        if #available(macOS 13.0, *) {
            try? SMAppService.mainApp.unregister()
            launchAtLoginEnabled = false
        }
        launchAtLoginPreference = false
        launchAtLoginPreferenceInitialized = true
        let task = Process()
        task.launchPath = "/usr/bin/env"
        task.arguments = ["open", Bundle.main.bundlePath]
        task.launch()
        NSApp.terminate(nil)
    }
}
