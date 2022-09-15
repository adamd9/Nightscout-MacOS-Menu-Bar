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
    @EnvironmentObject private var settings: SettingsModel
    @State var isOn = false
    
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
                    let rawUrl = URL(string: settings.glUrlTemp)!
                    settings.glUrlTemp = "https://" + (rawUrl.host ?? "")
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

                        let validToken = (result != nil)
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
            .pickerStyle(.inline)
            
            Toggle("Show Loop data (IOB, COB, Pump info)", isOn:$showLoopData)
                .toggleStyle(.checkbox)
                .onChange(of: showLoopData, perform: { _ in
                    getEntries()
                })
            
            Toggle("Show last update time in Menu Bar", isOn:$displayShowUpdateTime)
                .toggleStyle(.checkbox)
                .onChange(of: displayShowUpdateTime, perform: { _ in
                    getEntries()
                })
            
            LaunchAtLogin.Toggle()
            //            HStack {
            //                Button("Cut", action: {
            //                    let pasteBoard = NSPasteboard.general
            //                    pasteBoard.clearContents()
            //                    pasteBoard.setString(settings.glUrlTemp, forType: .string)
            //                    settings.glUrlTemp = ""
            //                }).keyboardShortcut("x")
            //
            //                Button("Copy", action: {
            //                    let pasteBoard = NSPasteboard.general
            //                    pasteBoard.clearContents()
            //                    pasteBoard.setString(settings.glUrlTemp, forType: .string)
            //                }).keyboardShortcut("c")
            //                Button("Paste", action: {
            //                    if let read = NSPasteboard.general.string(forType: .string) {
            //                        settings.glUrlTemp = read  // <-- here
            //                    }
            //                }).keyboardShortcut("v")
            //            }.opacity(0)
        }
        .padding(60)
        .frame(width: 800, height: 200)
        .alert(isPresented: $isOn) {
            Alert(title: Text("Token is invalid!"),
                  message: Text("Please make sure you're entering an access token (Admin Tools > Subjects) and NOT your API_SECRET token."),
                  dismissButton: .default(Text("OK")))
        }
    }
}
