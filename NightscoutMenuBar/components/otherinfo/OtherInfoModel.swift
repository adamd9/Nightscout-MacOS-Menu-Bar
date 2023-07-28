//
//  OtherInfoModel.swift
//  Nightscout Menu Bar
//
//  Created by Adam Dinneen on 26/7/2023.
//

import Foundation

class OtherInfoModel: ObservableObject {
    @Published var loopIob = ""
    @Published var loopCob = ""
    @Published var pumpReservoir = ""
    @Published var pumpBatt = ""
    @Published var pumpAgo = ""
    @Published var cgmSensorAge = ""
    @Published var cgmTransmitterAge = ""
    @Published var loopPredictions = NSArray()
    
}
