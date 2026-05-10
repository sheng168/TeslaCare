//
//  CarRowView.swift
//  TeslaCare
//
//  Created by Jin on 5/7/26.
//

import SwiftUI
import SwiftData
import CoreLocation

struct CarRowView: View {
    let car: Car
    @Environment(LocationManager.self) private var locationManager

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(car.displayName)
                .font(.headline)

            HStack(spacing: 8) {
                Text("\(car.year, format: .number.grouping(.never)) \(car.make) \(car.model)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let summary = car.drivetrainSummary {
                    Text(summary)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(.blue)
                }

                if let mileage = car.mileage {
                    Text("·")
                        .foregroundStyle(.tertiary)
                    Text("\(mileage.formatted()) mi")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if let distanceText = distanceFromUser {
                    Text("·")
                        .foregroundStyle(.tertiary)
                    Image(systemName: "location.fill")
                        .font(.caption2)
                        .foregroundStyle(.blue)
                    Text(distanceText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    #if DEBUG
                    Text("No gps")
                    #endif
                }
            }

            tireDataView
        }
        .padding(.vertical, 4)
    }
    
    @ViewBuilder
    private var tireDataView: some View {
        let hasTpms = TirePosition.allCases.contains { car.tpmsPressure(for: $0) != nil }
        let hasTread = car.tireHealthPercentage != nil

        if hasTpms || hasTread {
            VStack(alignment: .leading, spacing: 6) {
                Grid(horizontalSpacing: 16, verticalSpacing: 4) {
                    GridRow {
                        tireCellView(for: .frontLeft)
                        tireCellView(for: .frontRight)
                    }
                    GridRow {
                        tireCellView(for: .rearLeft)
                        tireCellView(for: .rearRight)
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
                }

                if let updated = lastUpdatedDate {
                    Text("Updated \(updated, format: .relative(presentation: .named))")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        } else {
            Text("No measurements")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func tireCellView(for position: TirePosition) -> some View {
        let psi = car.tpmsPressure(for: position)
        let tread = car.latestMeasurement(for: position)?.treadDepth

        return HStack(spacing: 4) {
            Text(position.abbreviation)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)

            if let psi {
                Text(String(format: "%.0f psi", psi * 14.504))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if psi != nil, tread != nil {
                Text("·")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            if let tread {
                Text(String(format: "%.1f/32\"", tread))
                    .font(.caption2)
                    .foregroundStyle(treadColor(for: tread))
            }

            if psi == nil, tread == nil {
                Text("—")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var distanceFromUser: String? {
        guard let carLat = car.latitude, let carLon = car.longitude,
              let userLocation = locationManager.userLocation else { return nil }
        let carLocation = CLLocation(latitude: carLat, longitude: carLon)
        let meters = userLocation.distance(from: carLocation)
        if meters < 1000 {
            return String(format: "%.0f m", meters)
        } else {
            return String(format: "%.1f km", meters / 1000)
        }
    }

    private var lastUpdatedDate: Date? {
        let tpmsDate = car.tpmsUpdatedAt
        let treadDate = TirePosition.allCases
            .compactMap { car.latestMeasurement(for: $0)?.date }
            .max()
        switch (tpmsDate, treadDate) {
        case let (t?, m?): return t > m ? t : m
        case let (t?, nil): return t
        case let (nil, m?): return m
        default: return nil
        }
    }

    private func healthColor(for percentage: Double) -> Color {
        switch percentage {
        case 50...100: return .green
        case 25..<50: return .orange
        default: return .red
        }
    }

    private func treadColor(for depth: Double) -> Color {
        if depth <= 2.0 { return .red }
        if depth <= 4.0 { return .orange }
        return .green
    }
}

#Preview("Car with Good Health") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Car.self, TireMeasurement.self, Tire.self, TPMSReading.self, configurations: config)

    let car = Car(name: "My Tesla", make: "Tesla", model: "Model 3", year: 2023)
    container.mainContext.insert(car)

    let reading = TPMSReading(date: Date(), frontLeft: 2.93, frontRight: 2.93, rearLeft: 2.76, rearRight: 2.79)
    reading.car = car
    container.mainContext.insert(reading)

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
