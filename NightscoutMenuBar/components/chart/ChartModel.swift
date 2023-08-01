//
//  ChartData.swift
//  Nightscout Menu Bar
//
//  Created by Adam Dinneen on 14/7/2023.
//

import Foundation

struct BGData: Identifiable {
    let id = UUID()
    let time: Date
    let bg: Double
    init(time: Date, bg: Double) {
        self.time = time
        self.bg = bg
    }
}

final class ChartData: ObservableObject {
    @Published var values: [BGData] = []
    
    func orderByTime() {
        values.sort { $0.time > $1.time }
    }
    
    func getMinVal() -> Double {
        return values.min(by: { $0.bg < $1.bg })!.bg
    }
    
    func getMaxVal() -> Double {
        return values.max(by: { $0.bg < $1.bg })!.bg
    }

    func getMinTime() -> Date {
        return values.min(by: { $0.time < $1.time })!.time
    }
    
    func getMaxTime() -> Date {
        return values.max(by: { $0.time < $1.time })!.time
    }
    
}
