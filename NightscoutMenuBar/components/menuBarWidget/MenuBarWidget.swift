//
//  MenuBarWidget.swift
//  Nightscout Menu Bar
//
//  Created by Adam Dinneen on 26/7/2023.
//

import SwiftUI
import Foundation
import Cocoa
import Combine
import Charts

protocol MenuBarWidgetProtocol {
    func updateDisplay(message: String, store: EntriesStore, extraMessage: String?)
    func populateHistoryMenu(store: EntriesStore)
    func updateOtherInfo(otherinfo: OtherInfoModel?)
    func emptyHistoryMenu(entries: [String])
    func updateExtraMessage(extraMessage: String?)
    func destroyStatusItem()
    func checkVisibility()
}

class MenuBarWidgetFactory {
    enum ItemType {
        case legacy
        case normal
    }
    
    static func makeStatusItem(type: ItemType) -> MenuBarWidgetProtocol {
        switch type {
        case .legacy:
            return MenuBarWidgetLegacy()
        case .normal:
            return MenuBarWidget()
        }
    }
}

class MenuBarWidget: ObservableObject, MenuBarWidgetProtocol {
    
    private var statusItem: NSStatusItem
    private var hostingView: NSHostingView<MenuBarWidget>?
    private var sizePassthrough = PassthroughSubject<CGSize, Never>()
    private var sizeCancellable: AnyCancellable?
    private var menu = MainMenu()
    private let otherinfo = OtherInfoModel()
    private let debouncer = Debouncer()
    
    init() {
        let statusItem: NSStatusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        self.statusItem = statusItem
        self.hostingView = nil
        self.sizeCancellable = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [] in
            self.checkVisibility()
            self.startTopNotchDetector()
        }
    }
    
    
    func updateDisplay(message: String, store: EntriesStore, extraMessage: String?) {
        @AppStorage("bgUnits") var userPrefBg = "mgdl"
        @AppStorage("displayShowUpdateTime") var displayShowUpdateTime = false
        @AppStorage("displayShowBGDifference") var displayShowBGDifference = false
        @AppStorage("graphEnabled") var graphEnabled = false
        @AppStorage("displayNSIcon") var displayNSIcon = true
        
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
        let hostingView = NSHostingView(rootView: MenuBarWidget(sizePassthrough: sizePassthrough, bgChartData: chartData, maxVal: maxRange ?? 0, minVal: minRange ?? 0, message: message, graphEnabled: graphEnabled, displayNSIcon: displayNSIcon))
        hostingView.frame = NSRect(x: 0, y: 0, width: 50, height: 26)
        self.statusItem.button?.frame = hostingView.frame
        self.statusItem.button?.subviews.forEach { $0.removeFromSuperview() }
        
        self.statusItem.button?.addSubview(hostingView)
        
        self.statusItem.menu = self.menu.build()
        
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
            self?.statusItem.button?.frame = frame
        }
    }
    
    func checkVisibility() {
        let isForceHidden = self.statusItem.button?.window?.occlusionState.contains(.visible) == false
        print("Is status item force-hidden by the system:", isForceHidden)
        if (isForceHidden == true) {
            dockIconManager.showDock(alert: true)
        } else {
            dockIconManager.hideDock()
        }
    }
    
    private func startTopNotchDetector() {
        
        NotificationCenter.default.addObserver(
            forName: NSWindow.didChangeOcclusionStateNotification,
            object: statusItem.button!.window,
            queue: nil
        ) { [weak self] _ in
            guard let strongSelf = self else {
                return
            }

            // Debounce the function call with a 0.5-second delay
            strongSelf.debouncer.debounce(delay: 0.5) {
                strongSelf.checkVisibility()
            }
        }
    }
    
    private func getHistoryStringArr(store: EntriesStore) -> [String] {
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
    
    func destroyStatusItem() {
        // Remove the status item from the status bar
        NSStatusBar.system.removeStatusItem(statusItem)
        
        // Optionally, also remove the observer if it's no longer needed
        NotificationCenter.default.removeObserver(self, name: NSWindow.didChangeOcclusionStateNotification, object: statusItem.button?.window)
    }
    
    private struct SizePreferenceKey: PreferenceKey {
        static var defaultValue: CGSize = .zero
        static func reduce(value: inout CGSize, nextValue: () -> CGSize) { value = nextValue() }
    }
    
    private struct MenuBarWidget: View {
        var sizePassthrough: PassthroughSubject<CGSize, Never>
        var bgChartData: ChartData?
        var maxVal: Double
        var minVal: Double
        var message: String = "..."
        var graphEnabled = false
        var displayNSIcon = false
        
        @ViewBuilder
        var mainContent: some View {
            HStack {
                Spacer()
                if (displayNSIcon) {
                    Image("sys-icon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18, alignment: .center)
                        .padding(.bottom, 5)
                        .layoutPriority(5)
                }
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
}
