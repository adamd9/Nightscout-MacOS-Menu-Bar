//
//  OtherInfoBoardView.swift


import SwiftUI
import Charts

struct MenuChartView: View {

    @EnvironmentObject var bgChartData: ChartData
    var maxVal: Double
    var minVal: Double
    
    
    var body: some View {
            VStack {
                Chart {
                    ForEach(bgChartData.values) { entry in
                        if (entry.time > Calendar.current.date(byAdding: .minute, value: -45, to: Date())!) {
                            LineMark(
                                x: .value("Time", entry.time, unit: .minute),
                                y: .value("BG", entry.bg)
                            )
                        }

                    }
                }
                .padding(.leading, 20)
                .chartYAxis{
                    AxisMarks(position: .leading)
                }
                .chartYScale(domain: minVal...maxVal)
                .chartXScale(domain: Calendar.current.date(byAdding: .minute, value: -45, to: Date())!...Date())
                .chartXAxis {
                    let unit: Calendar.Component = .minute

                    AxisMarks(values: .stride(by: unit, count: 15)) { value in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.hour(.defaultDigits(amPM: .omitted)).minute(), centered: false, anchor: .topTrailing)
                        AxisTick(centered: true, length: 10)

                    }
                }
                .frame(width: 200, height: 100)
            }
    }
}
