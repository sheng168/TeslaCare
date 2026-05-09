//
//  Car.swift
//  TeslaCare
//
//  Created by Jin on 5/7/26.
//

import Foundation
import SwiftData

// MARK: - Car Model
@Model
final class Car {
    var name: String
    var make: String
    var model: String
    var year: Int
    var dateAdded: Date
    var vin: String?
    var mileage: Int?
    var tpmsFrontLeft: Double?
    var tpmsFrontRight: Double?
    var tpmsRearLeft: Double?
    var tpmsRearRight: Double?
    var tpmsUpdatedAt: Date?
    
    @Relationship(deleteRule: .cascade, inverse: \TireMeasurement.car)
    var measurements: [TireMeasurement]?
    
    @Relationship(deleteRule: .cascade, inverse: \TireRotationEvent.car)
    var rotationEvents: [TireRotationEvent]?
    
    @Relationship(deleteRule: .cascade, inverse: \TireReplacementEvent.car)
    var replacementEvents: [TireReplacementEvent]?
    
    @Relationship(deleteRule: .cascade, inverse: \AirFilterChangeEvent.car)
    var airFilterChanges: [AirFilterChangeEvent]?
    
    @Relationship(deleteRule: .cascade, inverse: \Tire.car)
    var tires: [Tire]?
    
    init(name: String, make: String, model: String, year: Int, dateAdded: Date = Date()) {
        self.name = name
        self.make = make
        self.model = model
        self.year = year
        self.dateAdded = dateAdded
    }
    
    func tpmsPressure(for position: TirePosition) -> Double? {
        switch position {
        case .frontLeft:  return tpmsFrontLeft
        case .frontRight: return tpmsFrontRight
        case .rearLeft:   return tpmsRearLeft
        case .rearRight:  return tpmsRearRight
        }
    }

    var displayName: String {
        if name.isEmpty {
            return "\(year) \(make) \(model)"
        }
        return name
    }
    
    // Get the most recent measurement for a specific tire position
    func latestMeasurement(for position: TirePosition) -> TireMeasurement? {
        measurements?
            .filter { $0.position == position }
            .sorted { $0.date > $1.date }
            .first
    }
    
    // Get average tread depth across all tires from most recent measurements
    var averageTreadDepth: Double? {
        let latestMeasurements = TirePosition.allCases.compactMap { latestMeasurement(for: $0) }
        guard !latestMeasurements.isEmpty else { return nil }
        let sum = latestMeasurements.reduce(0.0) { $0 + $1.treadDepth }
        return sum / Double(latestMeasurements.count)
    }
    
    // Calculate tire health percentage (assuming 10/32" is new, 2/32" is replacement threshold)
    var tireHealthPercentage: Double? {
        guard let avg = averageTreadDepth else { return nil }
        let newTread = 10.0
        let replacementThreshold = 2.0
        let usableDepth = newTread - replacementThreshold
        let remainingDepth = max(0, avg - replacementThreshold)
        return min(100, (remainingDepth / usableDepth) * 100)
    }
}
