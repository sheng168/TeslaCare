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
    var date: Date = Date()
    var treadDepth: Double = 0.0 // in 32nds of an inch (average if multiple measurements)
    var positionRaw: String = "Front Left"
    var notes: String = ""
    var mileage: Int?
    
    // Multiple measurement points for uneven wear detection
    var innerTreadDepth: Double? // Inner edge measurement
    var centerTreadDepth: Double? // Center measurement
    var outerTreadDepth: Double? // Outer edge measurement

    @Relationship(deleteRule: .cascade, inverse: \TirePhoto.measurement)
    var photos: [TirePhoto]?

    var car: Car?
    var tire: Tire? // Non-optional - every measurement must be associated with a tire
    
    init(date: Date, treadDepth: Double, position: TirePosition, tire: Tire, notes: String = "", mileage: Int? = nil, innerDepth: Double? = nil, centerDepth: Double? = nil, outerDepth: Double? = nil) {
        self.date = date
        self.treadDepth = treadDepth
        self.positionRaw = position.rawValue
        self.tire = tire
        self.notes = notes
        self.mileage = mileage
        self.innerTreadDepth = innerDepth
        self.centerTreadDepth = centerDepth
        self.outerTreadDepth = outerDepth
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
    
    // MARK: - Multi-point Measurement Properties
    
    /// Returns true if this measurement has multiple data points
    var hasMultiplePoints: Bool {
        innerTreadDepth != nil && centerTreadDepth != nil && outerTreadDepth != nil
    }
    
    /// Calculate average from the three measurement points
    var calculatedAverage: Double? {
        guard let inner = innerTreadDepth,
              let center = centerTreadDepth,
              let outer = outerTreadDepth else {
            return nil
        }
        return (inner + center + outer) / 3.0
    }
    
    /// Difference between highest and lowest measurement points
    var wearDifference: Double? {
        guard let inner = innerTreadDepth,
              let center = centerTreadDepth,
              let outer = outerTreadDepth else {
            return nil
        }
        let max = max(inner, center, outer)
        let min = min(inner, center, outer)
        return max - min
    }
    
    /// Returns true if wear difference exceeds threshold (2/32")
    var hasUnevenWear: Bool {
        guard let difference = wearDifference else { return false }
        return difference > 2.0
    }
    
    /// Diagnostic message about wear pattern
    var wearPatternDescription: String? {
        guard let inner = innerTreadDepth,
              let center = centerTreadDepth,
              let outer = outerTreadDepth else {
            return nil
        }
        
        // Check for different wear patterns
        if center < inner && center < outer {
            return "Center wear detected - may indicate over-inflation"
        } else if inner < center && inner < outer {
            return "Inner edge wear - may indicate alignment or camber issues"
        } else if outer < center && outer < inner {
            return "Outer edge wear - may indicate alignment or camber issues"
        } else if (inner < center && outer < center) {
            return "Edge wear - may indicate under-inflation"
        } else {
            return "Even wear pattern"
        }
    }
}
