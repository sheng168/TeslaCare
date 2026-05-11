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
    var name: String = ""
    var make: String = ""
    var model: String = ""
    var year: Int = 0
    var dateAdded: Date = Date()
    var vin: String?
    var trimBadging: String?
    var perfConfig: String?
    var batteryLevel: Int?
    var chargingState: String?
    var latitude: Double?
    var longitude: Double?
    var heading: Double?
    var locationUpdatedAt: Date?

    @Relationship(deleteRule: .cascade, inverse: \MileageReading.car)
    var mileageReadings: [MileageReading]?

    var mileage: Int? { mileageReadings?.max(by: { $0.date < $1.date })?.mileage }

    @Relationship(deleteRule: .cascade, inverse: \TPMSReading.car)
    var tpmsReadings: [TPMSReading]?

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

    @Relationship(deleteRule: .cascade, inverse: \NearbyCharger.car)
    var nearbyChargers: [NearbyCharger]?
    
    init(name: String, make: String, model: String, year: Int, dateAdded: Date = Date()) {
        self.name = name
        self.make = make
        self.model = model
        self.year = year
        self.dateAdded = dateAdded
    }
    
    var lastUpdatedAt: Date? {
        [
            mileageReadings?.max(by: { $0.date < $1.date })?.date,
            tpmsReadings?.max(by: { $0.date < $1.date })?.date,
            measurements?.max(by: { $0.date < $1.date })?.date,
            rotationEvents?.max(by: { $0.date < $1.date })?.date,
            replacementEvents?.max(by: { $0.date < $1.date })?.date,
            airFilterChanges?.max(by: { $0.date < $1.date })?.date,
        ]
        .compactMap { $0 }
        .max()
    }

    var latestTPMSReading: TPMSReading? {
        tpmsReadings?.sorted { $0.date > $1.date }.first
    }

    var tpmsUpdatedAt: Date? { latestTPMSReading?.date }

    func tpmsPressure(for position: TirePosition) -> Double? {
        latestTPMSReading?.pressure(for: position)
    }

    /// Derived from trimBadging + perfConfig. Examples: "Long Range AWD", "Standard Range RWD", "Performance AWD", "Plaid AWD"
    var drivetrainSummary: String? {
        guard let raw = trimBadging?.lowercased(), !raw.isEmpty else { return nil }

        let isPlaid     = raw.contains("plaid")
        let isPerf      = isPlaid || raw.hasPrefix("p") || perfConfig?.lowercased() == "sport"
        let isAWD       = raw.contains("awd") || raw.hasSuffix("d") // "100d","75d","p100d" etc.
        let isLR        = !isPlaid && (raw.contains("lr") || (!isPerf && ["100d","90d","85d","75d","100"].contains(raw)))
        let isSR        = raw.contains("sr") || raw.contains("standard") || ["base","60","40","75"].contains(raw)

        let range: String
        if isPlaid      { range = "Plaid" }
        else if isPerf  { range = "Performance" }
        else if isLR    { range = "Long Range" }
        else if isSR    { range = "Standard Range" }
        else            { range = "" }

        let drive = isAWD ? "AWD" : "RWD"
        return range.isEmpty ? drive : "\(range) \(drive)"
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
