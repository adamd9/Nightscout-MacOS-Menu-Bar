//
//  helpers.swift
//  Nightscout Menu Bar
//
//  Created by adam.d on 6/2/2023.
//

import Foundation

class helpers {
    func convertbgMgToMmol(bgMg: Int) -> Double {
        //Round mmol to 1dp
        let bgMmol = (Double(bgMg)/18.018018*10).rounded()/10;
        return bgMmol;
    }
}
