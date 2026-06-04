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
    var treadDepth: Double = 0.0    // 32nds of an inch (average when multiple points recorded)
    var positionRaw: String = "Front Left"
    var notes: String = ""
    var mileage: Int?               // miles

    /// Multi-point depths across the tire width, ordered innermost → outermost.
    /// Empty when the measurement is a single average reading.
    var treadDepths: [Double] = []

    // MARK: - Deprecated multi-point fields
    // Retained as stored properties for one release so existing rows (and JSON/CSV exports
    // produced before `treadDepths` existed) continue to load. Treat as read-only — new
    // writes should set `treadDepths` instead.
    var innerTreadDepth: Double?
    var centerTreadDepth: Double?
    var outerTreadDepth: Double?

    @Relationship(deleteRule: .cascade, inverse: \TirePhoto.measurement)
    var photos: [TirePhoto]?

    var car: Car?
    var tire: Tire? // Non-optional - every measurement must be associated with a tire

    init(date: Date, treadDepth: Double, position: TirePosition, tire: Tire,
         notes: String = "", mileage: Int? = nil, treadDepths: [Double] = []) {
        self.date = date
        self.treadDepth = treadDepth
        self.positionRaw = position.rawValue
        self.tire = tire
        self.notes = notes
        self.mileage = mileage
        self.treadDepths = treadDepths
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

    /// The effective array of depths, preferring the new `treadDepths` array and falling
    /// back to the legacy inner/center/outer fields for records written before that field
    /// existed. Always ordered innermost → outermost.
    var effectiveTreadDepths: [Double] {
        if !treadDepths.isEmpty { return treadDepths }
        let legacy = [innerTreadDepth, centerTreadDepth, outerTreadDepth].compactMap { $0 }
        return legacy.count == 3 ? legacy : []
    }

    /// Returns true if this measurement has multiple data points.
    var hasMultiplePoints: Bool {
        effectiveTreadDepths.count >= 2
    }

    /// Calculate average from the measurement points.
    var calculatedAverage: Double? {
        let depths = effectiveTreadDepths
        guard !depths.isEmpty else { return nil }
        return depths.reduce(0, +) / Double(depths.count)
    }

    /// Difference between highest and lowest measurement points.
    var wearDifference: Double? {
        let depths = effectiveTreadDepths
        guard let lo = depths.min(), let hi = depths.max(), depths.count >= 2 else { return nil }
        return hi - lo
    }

    /// Returns true if wear difference exceeds threshold (2/32").
    var hasUnevenWear: Bool {
        guard let difference = wearDifference else { return false }
        return difference > 2.0
    }

    /// Diagnostic message about wear pattern. Inner = index 0; outer = last index.
    var wearPatternDescription: String? {
        let depths = effectiveTreadDepths
        guard depths.count >= 3 else { return nil }

        guard let minIndex = depths.indices.min(by: { depths[$0] < depths[$1] }) else { return nil }
        let lastIndex = depths.count - 1
        let inner = depths.first!
        let outer = depths.last!
        let edgeAvg = (inner + outer) / 2.0
        let middleAvg = depths[1..<lastIndex].reduce(0, +) / Double(lastIndex - 1)

        switch minIndex {
        case 0:
            return "Inner edge wear - may indicate alignment or camber issues"
        case lastIndex:
            return "Outer edge wear - may indicate alignment or camber issues"
        default:
            if depths[minIndex] < inner && depths[minIndex] < outer {
                return "Center wear detected - may indicate over-inflation"
            } else if edgeAvg < middleAvg {
                return "Edge wear - may indicate under-inflation"
            } else {
                return "Even wear pattern"
            }
        }
    }
}
