//
//  CarRowView.swift
//  TeslaCare
//
//  Created by Jin on 5/7/26.
//

import SwiftUI
import SwiftData

struct CarRowView: View {
    let car: Car
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(car.displayName)
                .font(.headline)
            
            HStack(spacing: 8) {
                Text("\(car.year, format: .number.grouping(.never)) \(car.make) \(car.model)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let mileage = car.mileage {
                    Text("·")
                        .foregroundStyle(.tertiary)
                    Text("\(mileage.formatted()) mi")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            if let health = car.tireHealthPercentage {
                HStack(spacing: 8) {
                    ProgressView(value: health, total: 100)
                        .tint(healthColor(for: health))
                        .frame(maxWidth: 150)
                    
                    Text("\(Int(health))%")
                        .font(.caption)
                        .foregroundStyle(healthColor(for: health))
                }
            } else {
                Text("No measurements")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func healthColor(for percentage: Double) -> Color {
        switch percentage {
        case 50...100: return .green
        case 25..<50: return .orange
        default: return .red
        }
    }
}

#Preview("Car with Good Health") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Car.self, TireMeasurement.self, Tire.self, configurations: config)
    
    let car = Car(name: "My Tesla", make: "Tesla", model: "Model 3", year: 2023)
    container.mainContext.insert(car)
    
    // Add tires and measurements for good health
    for position in TirePosition.allCases {
        let tire = Tire(brand: "Michelin", modelName: "Pilot Sport", size: "235/45R18", currentPosition: position)
        tire.car = car
        container.mainContext.insert(tire)
        
        let measurement = TireMeasurement(date: Date(), treadDepth: 8.0, position: position, tire: tire, notes: "", mileage: nil)
        measurement.car = car
        container.mainContext.insert(measurement)
    }
    
    return List {
        CarRowView(car: car)
    }
    .modelContainer(container)
}

#Preview("Car with Warning Health") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Car.self, TireMeasurement.self, Tire.self, configurations: config)
    
    let car = Car(name: "Family SUV", make: "Honda", model: "CR-V", year: 2020)
    container.mainContext.insert(car)
    
    // Add tires and measurements for warning health
    for position in TirePosition.allCases {
        let tire = Tire(brand: "Goodyear", modelName: "Assurance", size: "225/65R17", currentPosition: position)
        tire.car = car
        container.mainContext.insert(tire)
        
        let measurement = TireMeasurement(date: Date(), treadDepth: 3.5, position: position, tire: tire, notes: "", mileage: nil)
        measurement.car = car
        container.mainContext.insert(measurement)
    }
    
    return List {
        CarRowView(car: car)
    }
    .modelContainer(container)
}

#Preview("Car with Danger Health") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Car.self, TireMeasurement.self, Tire.self, configurations: config)
    
    let car = Car(name: "", make: "Toyota", model: "Camry", year: 2018)
    container.mainContext.insert(car)
    
    // Add tires and measurements for danger health
    for position in TirePosition.allCases {
        let tire = Tire(brand: "Bridgestone", modelName: "Turanza", size: "215/55R17", currentPosition: position)
        tire.car = car
        container.mainContext.insert(tire)
        
        let measurement = TireMeasurement(date: Date(), treadDepth: 1.5, position: position, tire: tire, notes: "", mileage: nil)
        measurement.car = car
        container.mainContext.insert(measurement)
    }
    
    return List {
        CarRowView(car: car)
    }
    .modelContainer(container)
}

#Preview("Car with No Measurements") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Car.self, TireMeasurement.self, configurations: config)
    
    let car = Car(name: "Work Truck", make: "Ford", model: "F-150", year: 2022)
    container.mainContext.insert(car)
    
    return List {
        CarRowView(car: car)
    }
    .modelContainer(container)
}
