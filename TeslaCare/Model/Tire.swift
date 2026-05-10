//
//  Tire.swift
//  TeslaCare
//
//  Created by Jin on 5/7/26.
//

import Foundation
import SwiftData

// MARK: - Tire Model
@Model
final class Tire {
    var brand: String = ""
    var modelName: String = ""
    var size: String = "" // e.g., "235/45R18"
    var dotNumber: String = "" // DOT serial number
    var purchaseDate: Date = Date()
    var installDate: Date = Date()
    var initialTreadDepth: Double = 10.0 // in 32nds of an inch
    var purchasePrice: Double?
    var currentPosition: String = "Front Left" // Store as raw value
    var mileageAtInstall: Int?
    var notes: String = ""
    
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
        let idString = persistentModelID.hashValue
        let shortID = String(format: "%X", abs(idString)).prefix(3)
        
        if brand.isEmpty && modelName.isEmpty {
            return "Tire #\(shortID)"
        } else if brand.isEmpty {
            return "\(modelName) #\(shortID)"
        } else if modelName.isEmpty {
            return "\(brand) #\(shortID)"
        } else {
            return "\(brand) \(modelName) #\(shortID)"
        }
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
