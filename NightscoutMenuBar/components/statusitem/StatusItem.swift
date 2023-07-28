//
//  StatusItem.swift
//  Nightscout Menu Bar
//
//  Created by Adam Dinneen on 26/7/2023.
//

import SwiftUI
import Foundation
import Cocoa
import Combine
import Charts

protocol StatusItemProtocol {
    func updateDisplay(message: String, store: EntriesStore, extraMessage: String?)
    func populateHistoryMenu(store: EntriesStore)
    func updateOtherInfo(otherinfo: OtherInfoModel?)
    func emptyHistoryMenu(entries: [String])
    func updateExtraMessage(extraMessage: String?)
}

class StatusItemFactory {
    enum ItemType {
        case legacy
        case normal
    }

    static func makeStatusItem(type: ItemType) -> StatusItemProtocol {
        switch type {
        case .legacy:
            return StatusItemLegacy()
        case .normal:
            return StatusItem()
        }
    }
}

class StatusItem: ObservableObject, StatusItemProtocol {
    
    private var statusItem: NSStatusItem?
    private var hostingView: NSHostingView<StatusItem>?
    private var sizePassthrough = PassthroughSubject<CGSize, Never>()
    private var sizeCancellable: AnyCancellable?
    private var menu = MainMenu()
    private let otherinfo = OtherInfoModel()

    private struct SizePreferenceKey: PreferenceKey {
        static var defaultValue: CGSize = .zero
        static func reduce(value: inout CGSize, nextValue: () -> CGSize) { value = nextValue() }
    }
    
    private struct StatusItem: View {
        var sizePassthrough: PassthroughSubject<CGSize, Never>
        var bgChartData: ChartData?
        var maxVal: Double
        var minVal: Double
        var message: String = "..."
        var graphEnabled = false
        
        @ViewBuilder
        var mainContent: some View {
            HStack {
                Spacer()
                Image("sys-icon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18, alignment: .center)
                    .padding(.bottom, 5)
                    .layoutPriority(5)
                if (graphEnabled && bgChartData != nil) {
                    Chart {
                        ForEach(bgChartData!.values) { entry in
                            if (entry.time > Calendar.current.date(byAdding: .minute, value: -45, to: Date())!) {
                                LineMark(
                                    x: .value("Time", entry.time, unit: .minute),
                                    y: .value("BG", entry.bg)
                                )
                            }
                        }
                    }
                    .chartYAxis(.hidden)
                    .chartXAxis(.hidden)
                    .chartYScale(domain: minVal...maxVal)
                    .chartXScale(domain: Calendar.current.date(byAdding: .minute, value: -45, to: Date())!...Date())
                    .layoutPriority(1)
                    .frame(width: 70, height: 26, alignment: .center)
                    .padding(.bottom, 5)
                }
                Text(message)
                    .fontWeight(.regular)
                    .layoutPriority(3)
                    .frame(alignment: .leading)
                    .padding(.bottom, 4)
                Spacer()
            }
            .fixedSize()
        }
        
        var body: some View {
            mainContent
                .overlay(
                    GeometryReader { geometryProxy in
                        Color.clear
                            .preference(key: SizePreferenceKey.self, value: geometryProxy.size)
                    }
                )
                .onPreferenceChange(SizePreferenceKey.self, perform: { size in
                    sizePassthrough.send(size)
                })
        }
    }
    
    func updateDisplay(message: String, store: EntriesStore, extraMessage: String?) {
        @AppStorage("bgUnits") var userPrefBg = "mgdl"
        @AppStorage("displayShowUpdateTime") var displayShowUpdateTime = false
        @AppStorage("displayShowBGDifference") var displayShowBGDifference = false
        @AppStorage("graphEnabled") var graphEnabled = false
        var maxRange, minRange: Double?
        var chartData: ChartData?
        
        if (!store.entries.isEmpty) {
            
            chartData = store.createChartData()
            let minVal = chartData!.getMinVal()
            let maxVal = chartData!.getMaxVal()
            if (userPrefBg == "mgdl") {
                maxRange = Double(Int(round(maxVal)) + 18)
                minRange = Double(Int(round(minVal)) - 18)
                
            } else {
                maxRange = Double(Int(round(maxVal)) + 1)
                minRange = Double(Int(round(minVal)) - 1)
            }
        }
        let hostingView = NSHostingView(rootView: StatusItem(sizePassthrough: sizePassthrough, bgChartData: chartData, maxVal: maxRange ?? 0, minVal: minRange ?? 0, message: message, graphEnabled: graphEnabled))
            hostingView.frame = NSRect(x: 0, y: 0, width: 50, height: 26)
            let statusItem: NSStatusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
            self.statusItem = statusItem
            self.statusItem?.button?.frame = hostingView.frame
            self.statusItem?.button?.addSubview(hostingView)
            self.statusItem?.menu = self.menu.build()
            self.menu.updateExtraMessage(extraMessage: extraMessage)
            //why can't updatExtraMessage go after updateDisplay?
        
        if (chartData != nil) {
            self.menu.updateMenuChart(chartData: chartData!, maxVal: maxRange ?? 0, minVal: minRange ?? 0)
        }

            self.menu.updateHistory(entries: getHistoryStringArr(store: store))
            
            self.hostingView = hostingView
                        
             sizeCancellable = sizePassthrough.sink { [weak self] size in
                 let frame = NSRect(origin: .zero, size: .init(width: size.width, height: 26))
                 self?.hostingView?.frame = frame
                 self?.statusItem?.button?.frame = frame
             }
//        }
    }
    
    func getHistoryStringArr(store: EntriesStore) -> [String] {
        var historyStringArr = [String]()
        if (!store.entries.isEmpty) {
            store.orderByTime()
            store.entries.forEach({entry in
                historyStringArr.append(bgValueFormattedHistory(entry: entry) + " " + bgMinsAgo(entry: entry) + " m")
            })
        }
        return historyStringArr
    }
    
    func populateHistoryMenu(store: EntriesStore) {
        if (!store.entries.isEmpty) {
            store.orderByTime()
            var historyStringArr = [String]()
            store.entries.forEach({entry in
                historyStringArr.append(bgValueFormattedHistory(entry: entry) + " " + bgMinsAgo(entry: entry) + " m")
            })
            self.menu.updateHistory(entries: historyStringArr)
        }
    }
    
    func updateExtraMessage(extraMessage: String?) {
        if (extraMessage != nil) {
            self.menu.updateExtraMessage(extraMessage: extraMessage)
        } else {
            self.menu.updateExtraMessage(extraMessage: nil)
        }
    }
    
    func updateOtherInfo(otherinfo: OtherInfoModel?) {
        if (otherinfo != nil) {
            self.menu.updateOtherInfo(otherinfo: otherinfo)
        } else {
            self.menu.updateOtherInfo(otherinfo: nil)
        }
    }
    
    func emptyHistoryMenu(entries: [String]) {
        self.menu.updateHistory(entries: entries)
    }
}
