//
//  TireMeasurement.swift
//  TeslaCare
//
//  Created by Jin on 5/7/26.
//

import Foundation
import SwiftData

// MARK: - Tire Measurement Model
@Model
final class TireMeasurement {
    var date: Date
    var treadDepth: Double // in 32nds of an inch
    var positionRaw: String
    var notes: String
    var mileage: Int?
    
    var car: Car?
    var tire: Tire? // Non-optional - every measurement must be associated with a tire
    
    init(date: Date, treadDepth: Double, position: TirePosition, tire: Tire, notes: String = "", mileage: Int? = nil) {
        self.date = date
        self.treadDepth = treadDepth
        self.positionRaw = position.rawValue
        self.tire = tire
        self.notes = notes
        self.mileage = mileage
    }
    
    var position: TirePosition {
        get { TirePosition(rawValue: positionRaw) ?? .frontLeft }
        set { positionRaw = newValue.rawValue }
    }
    
    var treadDepthFormatted: String {
        String(format: "%.1f/32\"", treadDepth)
    }
    
    var isWarning: Bool {
        treadDepth <= 4.0
    }
    
    var isDanger: Bool {
        treadDepth <= 2.0
    }
}
