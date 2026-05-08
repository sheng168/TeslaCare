//
//  UITestDataHelper.swift
//  TeslaCare
//
//  Created by Jin on 5/7/26.
//

import Foundation
import SwiftData

// NOTE: For this file to work, the following model files must be included in the UI test target:
// - Item.swift (contains Car, TireMeasurement, TirePosition)
// - TireRotation.swift (contains TireRotationEvent, TireRotationPattern)
// - TireReplacement.swift (contains TireReplacementEvent)
// - AirFilterChange.swift (contains AirFilterChangeEvent, AirFilterType)

/// Helper class to create test data for UI tests
/// Use launch arguments to trigger different states
@MainActor
class UITestDataHelper {
    
    static func setupTestData(modelContext: ModelContext, launchArguments: [String]) {
        // Check if we're in UI testing mode
        guard launchArguments.contains("UI-Testing") else { return }
        
        // Clear existing data
        clearAllData(modelContext: modelContext)
        
        // Setup data based on launch arguments
        if launchArguments.contains("EmptyCarState") {
            setupEmptyCar(modelContext: modelContext)
        } else if launchArguments.contains("CarWithMeasurements") {
            setupCarWithMeasurements(modelContext: modelContext)
        } else if launchArguments.contains("HealthyTires") {
            setupHealthyTires(modelContext: modelContext)
        } else if launchArguments.contains("WarningTires") {
            setupWarningTires(modelContext: modelContext)
        } else if launchArguments.contains("DangerousTires") {
            setupDangerousTires(modelContext: modelContext)
        } else if launchArguments.contains("WithRotationHistory") {
            setupWithRotationHistory(modelContext: modelContext)
        } else if launchArguments.contains("WithReplacementHistory") {
            setupWithReplacementHistory(modelContext: modelContext)
        } else if launchArguments.contains("WithAirFilterHistory") {
            setupWithAirFilterHistory(modelContext: modelContext)
        } else if launchArguments.contains("CompleteHistory") {
            setupCompleteHistory(modelContext: modelContext)
        } else if launchArguments.contains("Car2020") {
            setupCar2020(modelContext: modelContext)
        }
        
        // Save context
        try? modelContext.save()
    }
    
    // MARK: - Clear Data
    
    private static func clearAllData(modelContext: ModelContext) {
        // Delete all cars (cascade will delete related data)
        let carDescriptor = FetchDescriptor<Car>()
        if let cars = try? modelContext.fetch(carDescriptor) {
            cars.forEach { modelContext.delete($0) }
        }
    }
    
    // MARK: - Test Data Scenarios
    
    private static func setupEmptyCar(modelContext: ModelContext) {
        let car = Car(name: "My Tesla", make: "Tesla", model: "Model 3", year: 2023)
        modelContext.insert(car)
    }
    
    private static func setupCarWithMeasurements(modelContext: ModelContext) {
        let car = Car(name: "My Tesla", make: "Tesla", model: "Model 3", year: 2023)
        modelContext.insert(car)
        
        // Add measurements for all tires with healthy values
        let positions: [TirePosition] = [.frontLeft, .frontRight, .rearLeft, .rearRight]
        let depths: [Double] = [7.5, 7.8, 7.2, 7.6]
        
        for (index, position) in positions.enumerated() {
            let measurement = TireMeasurement(
                date: Date().addingTimeInterval(Double(-index) * 86400),
                treadDepth: depths[index],
                position: position,
                notes: "Regular inspection",
                mileage: 25000 + (index * 1000)
            )
            measurement.car = car
            modelContext.insert(measurement)
        }
    }
    
    private static func setupHealthyTires(modelContext: ModelContext) {
        let car = Car(name: "My Tesla", make: "Tesla", model: "Model 3", year: 2023)
        modelContext.insert(car)
        
        // All tires have excellent tread depth (8-9/32")
        let positions: [TirePosition] = [.frontLeft, .frontRight, .rearLeft, .rearRight]
        let depths: [Double] = [8.5, 8.8, 8.2, 8.6]
        
        for (index, position) in positions.enumerated() {
            let measurement = TireMeasurement(
                date: Date().addingTimeInterval(Double(-index) * 86400),
                treadDepth: depths[index],
                position: position,
                mileage: 15000
            )
            measurement.car = car
            modelContext.insert(measurement)
        }
    }
    
    private static func setupWarningTires(modelContext: ModelContext) {
        let car = Car(name: "My Tesla", make: "Tesla", model: "Model 3", year: 2023)
        modelContext.insert(car)
        
        // Some tires are in warning range (2-4/32")
        let positions: [TirePosition] = [.frontLeft, .frontRight, .rearLeft, .rearRight]
        let depths: [Double] = [3.5, 3.2, 7.5, 7.8]
        
        for (index, position) in positions.enumerated() {
            let measurement = TireMeasurement(
                date: Date().addingTimeInterval(Double(-index) * 86400),
                treadDepth: depths[index],
                position: position,
                notes: index < 2 ? "Front tires showing wear" : "",
                mileage: 45000
            )
            measurement.car = car
            modelContext.insert(measurement)
        }
    }
    
    private static func setupDangerousTires(modelContext: ModelContext) {
        let car = Car(name: "My Tesla", make: "Tesla", model: "Model 3", year: 2023)
        modelContext.insert(car)
        
        // Some tires are dangerously low (≤2/32")
        let positions: [TirePosition] = [.frontLeft, .frontRight, .rearLeft, .rearRight]
        let depths: [Double] = [1.8, 2.0, 3.5, 3.2]
        
        for (index, position) in positions.enumerated() {
            let measurement = TireMeasurement(
                date: Date().addingTimeInterval(Double(-index) * 86400),
                treadDepth: depths[index],
                position: position,
                notes: index < 2 ? "CRITICAL - Replace immediately!" : "Monitor closely",
                mileage: 55000
            )
            measurement.car = car
            modelContext.insert(measurement)
        }
    }
    
    private static func setupWithRotationHistory(modelContext: ModelContext) {
        let car = Car(name: "My Tesla", make: "Tesla", model: "Model 3", year: 2023)
        modelContext.insert(car)
        
        // Add measurements
        setupCarWithMeasurements(modelContext: modelContext)
        
        // Add rotation events
        let rotation1 = TireRotationEvent(
            date: Date().addingTimeInterval(-30 * 86400),
            pattern: .frontToBack,
            mileage: 20000,
            notes: "Regular 6-month rotation"
        )
        rotation1.car = car
        modelContext.insert(rotation1)
        
        let rotation2 = TireRotationEvent(
            date: Date().addingTimeInterval(-180 * 86400),
            pattern: .xPattern,
            mileage: 15000,
            notes: "First rotation"
        )
        rotation2.car = car
        modelContext.insert(rotation2)
    }
    
    private static func setupWithReplacementHistory(modelContext: ModelContext) {
        let car = Car(name: "My Tesla", make: "Tesla", model: "Model 3", year: 2023)
        modelContext.insert(car)
        
        // Add measurements
        let positions: [TirePosition] = [.frontLeft, .frontRight, .rearLeft, .rearRight]
        for (index, position) in positions.enumerated() {
            let measurement = TireMeasurement(
                date: Date(),
                treadDepth: 9.0,
                position: position,
                mileage: 10000
            )
            measurement.car = car
            modelContext.insert(measurement)
        }
        
        // Add replacement events
        let replacement1 = TireReplacementEvent(
            date: Date().addingTimeInterval(-60 * 86400),
            positions: [.frontLeft, .frontRight],
            brand: "Michelin",
            modelName: "Pilot Sport 4S",
            mileage: 45000,
            cost: 850.00,
            notes: "Replaced front tires due to wear"
        )
        replacement1.car = car
        modelContext.insert(replacement1)
        
        let replacement2 = TireReplacementEvent(
            date: Date().addingTimeInterval(-365 * 86400),
            positions: [.frontLeft, .frontRight, .rearLeft, .rearRight],
            brand: "Continental",
            modelName: "ExtremeContact DWS06",
            mileage: 0,
            cost: 1200.00,
            notes: "All season tires for winter"
        )
        replacement2.car = car
        modelContext.insert(replacement2)
    }
    
    private static func setupWithAirFilterHistory(modelContext: ModelContext) {
        let car = Car(name: "My Tesla", make: "Tesla", model: "Model 3", year: 2023)
        modelContext.insert(car)
        
        // Add measurements
        setupCarWithMeasurements(modelContext: modelContext)
        
        // Add air filter changes
        let filter1 = AirFilterChangeEvent(
            date: Date().addingTimeInterval(-45 * 86400),
            filterType: .cabin,
            mileage: 22000,
            brand: "Tesla OEM",
            partNumber: "1077521-00-C",
            cost: 45.00,
            notes: "Annual cabin filter replacement"
        )
        filter1.car = car
        modelContext.insert(filter1)
        
        let filter2 = AirFilterChangeEvent(
            date: Date().addingTimeInterval(-200 * 86400),
            filterType: .both,
            mileage: 15000,
            brand: "K&N",
            partNumber: "33-5068",
            cost: 120.00,
            notes: "Upgraded to performance filters"
        )
        filter2.car = car
        modelContext.insert(filter2)
    }
    
    private static func setupCompleteHistory(modelContext: ModelContext) {
        let car = Car(name: "My Tesla", make: "Tesla", model: "Model 3", year: 2023)
        modelContext.insert(car)
        
        // Add multiple measurements over time
        let positions: [TirePosition] = [.frontLeft, .frontRight, .rearLeft, .rearRight]
        let dates = [0, -30, -60, -90, -120, -150, -180]
        
        for dayOffset in dates {
            for position in positions {
                let baseTread = 9.0
                let wear = Double(abs(dayOffset)) / 180.0 * 3.0
                let measurement = TireMeasurement(
                    date: Date().addingTimeInterval(Double(dayOffset) * 86400),
                    treadDepth: baseTread - wear,
                    position: position,
                    notes: dayOffset == 0 ? "Latest measurement" : "",
                    mileage: 25000 + (abs(dayOffset) * 50)
                )
                measurement.car = car
                modelContext.insert(measurement)
            }
        }
        
        // Add rotation events
        let rotation = TireRotationEvent(
            date: Date().addingTimeInterval(-90 * 86400),
            pattern: .frontToBack,
            mileage: 20000,
            notes: "Regular rotation service"
        )
        rotation.car = car
        modelContext.insert(rotation)
        
        // Add replacement event
        let replacement = TireReplacementEvent(
            date: Date().addingTimeInterval(-180 * 86400),
            positions: [.frontLeft, .frontRight],
            brand: "Michelin",
            modelName: "Pilot Sport 4S",
            mileage: 15000,
            cost: 850.00,
            notes: "Front tire replacement"
        )
        replacement.car = car
        modelContext.insert(replacement)
        
        // Add air filter changes
        let filter = AirFilterChangeEvent(
            date: Date().addingTimeInterval(-120 * 86400),
            filterType: .cabin,
            mileage: 18000,
            brand: "Tesla OEM",
            partNumber: "1077521-00-C",
            cost: 45.00,
            notes: "Scheduled maintenance"
        )
        filter.car = car
        modelContext.insert(filter)
    }
    
    private static func setupCar2020(modelContext: ModelContext) {
        let car = Car(name: "Model Y", make: "Tesla", model: "Model Y", year: 2020)
        modelContext.insert(car)
        
        // Add some measurements
        let positions: [TirePosition] = [.frontLeft, .frontRight, .rearLeft, .rearRight]
        for (index, position) in positions.enumerated() {
            let measurement = TireMeasurement(
                date: Date(),
                treadDepth: 6.5,
                position: position,
                mileage: 40000 + (index * 100)
            )
            measurement.car = car
            modelContext.insert(measurement)
        }
    }
}
