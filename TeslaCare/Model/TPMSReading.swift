//
//  TPMSReading.swift
//  TeslaCare
//

import Foundation
import SwiftData

@Model
final class TPMSReading {
    var date: Date = Date()
    var frontLeft: Double?           // bar (Tesla API; multiply by 14.504 to get PSI)
    var frontRight: Double?          // bar
    var rearLeft: Double?            // bar
    var rearRight: Double?           // bar
    var outsideTemperature: Double?  // °C

    var car: Car?

    init(date: Date, frontLeft: Double?, frontRight: Double?, rearLeft: Double?, rearRight: Double?, outsideTemperature: Double? = nil) {
        self.date = date
        self.frontLeft = frontLeft
        self.frontRight = frontRight
        self.rearLeft = rearLeft
        self.rearRight = rearRight
        self.outsideTemperature = outsideTemperature
    }

    func pressure(for position: TirePosition) -> Double? {
        switch position {
        case .frontLeft:  return frontLeft
        case .frontRight: return frontRight
        case .rearLeft:   return rearLeft
        case .rearRight:  return rearRight
        }
    }
}
