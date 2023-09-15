//
//  entry.swift
//  NightscountMenuApp
//
//  Created by adam.d on 28/6/2022.
//

import Foundation
import SwiftUI

struct Entry: Identifiable {
    let id = UUID()
    var time: Date
    var bgMg: Int
    var bgMmol: Double
    var direction: String

}

final class EntriesStore: ObservableObject {
    @Published var entries: [Entry] = []

    func orderByTime() {
        entries.sort { $0.time > $1.time }
    }
    
    func getLatest() -> Entry {
        return entries.max (by: { $0.time > $1.time })!
    }
    

}
