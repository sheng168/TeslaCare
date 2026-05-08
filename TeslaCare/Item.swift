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

// MARK: - Tire Model
@Model
final class Tire {
    var brand: String
    var modelName: String
    var size: String // e.g., "235/45R18"
    var dotNumber: String // DOT serial number
    var purchaseDate: Date
    var installDate: Date
    var initialTreadDepth: Double // in 32nds of an inch
    var purchasePrice: Double?
    var currentPosition: String // Store as raw value
    var mileageAtInstall: Int?
    var notes: String
    
    var car: Car?
    
    @Relationship(deleteRule: .cascade, inverse: \TireMeasurement.tire)
    var measurements: [TireMeasurement]?
    
    init(brand: String, 
         modelName: String, 
         size: String, 
         dotNumber: String = "",
         purchaseDate: Date = Date(),
         installDate: Date = Date(),
         initialTreadDepth: Double = 10.0,
         purchasePrice: Double? = nil,
         currentPosition: TirePosition,
         mileageAtInstall: Int? = nil,
         notes: String = "") {
        self.brand = brand
        self.modelName = modelName
        self.size = size
        self.dotNumber = dotNumber
        self.purchaseDate = purchaseDate
        self.installDate = installDate
        self.initialTreadDepth = initialTreadDepth
        self.purchasePrice = purchasePrice
        self.currentPosition = currentPosition.rawValue
        self.mileageAtInstall = mileageAtInstall
        self.notes = notes
    }
    
    var position: TirePosition {
        get { TirePosition(rawValue: currentPosition) ?? .frontLeft }
        set { currentPosition = newValue.rawValue }
    }
    
    var displayName: String {
        "\(brand) \(modelName)"
    }
    
    var ageInMonths: Int {
        Calendar.current.dateComponents([.month], from: purchaseDate, to: Date()).month ?? 0
    }
    
    // Get the most recent measurement for this tire
    var latestMeasurement: TireMeasurement? {
        measurements?.sorted { $0.date > $1.date }.first
    }
    
    // Calculate wear percentage
    var wearPercentage: Double? {
        guard let latest = latestMeasurement else { return nil }
        let worn = initialTreadDepth - latest.treadDepth
        return (worn / initialTreadDepth) * 100
    }
    
    // Calculate remaining life percentage
    var remainingLifePercentage: Double? {
        guard let latest = latestMeasurement else { return nil }
        let replacementThreshold = 2.0
        let usableDepth = initialTreadDepth - replacementThreshold
        let remainingDepth = max(0, latest.treadDepth - replacementThreshold)
        return min(100, (remainingDepth / usableDepth) * 100)
    }
    
    var needsReplacement: Bool {
        guard let latest = latestMeasurement else { return false }
        return latest.treadDepth <= 2.0
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
    var tire: Tire?
    
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

