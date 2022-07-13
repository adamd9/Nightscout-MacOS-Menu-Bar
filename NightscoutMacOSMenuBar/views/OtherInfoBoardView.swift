//
//  OtherInfoBoardView.swift


import SwiftUI

struct OtherInfoBoardView: View {
    @EnvironmentObject private var otherinfo: OtherInfoModel
    
    var body: some View {
            VStack(alignment: .leading) {
                HStack(alignment: .center) {
                    Text("IOB:")
                        .font(.caption)
                        .fontWeight(.light)
                    Text(otherinfo.loopIob)
                        .font(.caption)
                        .fontWeight(.bold)
                    Text("COB:")
                        .font(.caption)
                        .fontWeight(.light)
                    Text(otherinfo.loopCob)
                        .font(.caption)
                        .fontWeight(.bold)
                }
                HStack(alignment: .center) {
                    Text("Pump:")
                        .font(.caption)
                        .fontWeight(.light)
                    Text(otherinfo.pumpReservoir + " " + otherinfo.pumpBatt + " " + otherinfo.pumpAgo)
                        .font(.caption)
                        .fontWeight(.bold)
                }
            }
    }
}
