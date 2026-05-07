//
//  Item.swift
//  TeslaCare
//
//  Created by Jin on 5/7/26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
// MARK: - Tire Position Enum
enum TirePosition: String, Codable, CaseIterable {
    case frontLeft = "Front Left"
    case frontRight = "Front Right"
    case rearLeft = "Rear Left"
    case rearRight = "Rear Right"
    
    var systemImage: String {
        switch self {
        case .frontLeft: return "arrow.up.left"
        case .frontRight: return "arrow.up.right"
        case .rearLeft: return "arrow.down.left"
        case .rearRight: return "arrow.down.right"
        }
    }
}

// MARK: - Car Model
@Model
final class Car {
    var name: String
    var make: String
    var model: String
    var year: Int
    var dateAdded: Date
    
    @Relationship(deleteRule: .cascade, inverse: \TireMeasurement.car)
    var measurements: [TireMeasurement]?
    
    init(name: String, make: String, model: String, year: Int, dateAdded: Date = Date()) {
        self.name = name
        self.make = make
        self.model = model
        self.year = year
        self.dateAdded = dateAdded
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

// MARK: - Tire Measurement Model
@Model
final class TireMeasurement {
    var date: Date
    var treadDepth: Double // in 32nds of an inch
    var positionRaw: String
    var notes: String
    var mileage: Int?
    
    var car: Car?
    
    init(date: Date, treadDepth: Double, position: TirePosition, notes: String = "", mileage: Int? = nil) {
        self.date = date
        self.treadDepth = treadDepth
        self.positionRaw = position.rawValue
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

