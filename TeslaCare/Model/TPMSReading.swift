//
//  TPMSReading.swift
//  TeslaCare
//

import Foundation
import SwiftData

@Model
final class TPMSReading {
    var date: Date
    var frontLeft: Double?
    var frontRight: Double?
    var rearLeft: Double?
    var rearRight: Double?

    var car: Car?

    init(date: Date, frontLeft: Double?, frontRight: Double?, rearLeft: Double?, rearRight: Double?) {
        self.date = date
        self.frontLeft = frontLeft
        self.frontRight = frontRight
        self.rearLeft = rearLeft
        self.rearRight = rearRight
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
