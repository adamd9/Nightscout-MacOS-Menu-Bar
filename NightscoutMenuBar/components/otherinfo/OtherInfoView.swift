//
//  OtherInfoBoardView.swift


import SwiftUI

struct OtherInfoBoardView: View {
    @EnvironmentObject private var otherinfo: OtherInfoModel
    
    var body: some View {
            VStack(alignment: .leading) {
                HStack(alignment: .center) {
                    Spacer()
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
                    Spacer()
                }
                if (otherinfo.pumpReservoir as String != "") {
                    HStack(alignment: .center) {
                        Spacer()
                        Text("Pump:")
                            .font(.caption)
                            .fontWeight(.light)
                        Text(otherinfo.pumpReservoir + " " + otherinfo.pumpBatt + " " + otherinfo.pumpAgo)
                            .font(.caption)
                            .fontWeight(.bold)
                        Spacer()
                    }
                }
                
            }
    }
}
