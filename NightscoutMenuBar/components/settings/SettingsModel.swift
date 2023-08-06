//
//  SettingsModel.swift
//  Nightscout Menu Bar
//
//  Created by Adam Dinneen on 26/7/2023.
//

import Foundation

class SettingsModel: ObservableObject {
    @Published var glIsEdit = false
    @Published var glUrl = ""
    @Published var glUrlTemp = ""
    @Published var glIsEditToken = false
    @Published var glToken = ""
    @Published var glTokenTemp = ""
    @Published var activeTextField = ""
    @Published var useLegacyStatusItem = false
}
