//
//  PreferencesView.swift
//  NightscoutMacOSMenuBar
//
//  Created by adam.d on 10/7/2022.
//

import Foundation
import SwiftUI
import LaunchAtLogin

struct SettingsView: View {
    @AppStorage("nightscoutUrl") private var nightscoutUrl = ""
    @AppStorage("bgUnits") private var bgUnits = "mgdl"
    @AppStorage("showLoopData") private var showLoopData = false
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
            
            Toggle("Show Loop data (IOB, COB, Pump info)", isOn:$showLoopData)
                .toggleStyle(.checkbox)
                .onChange(of: showLoopData, perform: { _ in
                    getEntries()
                })
            
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
