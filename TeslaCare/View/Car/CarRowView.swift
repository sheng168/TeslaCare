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
            HStack {
                Text(car.displayName)
                    .font(.headline)
                if let level = car.batteryLevel {
                    Spacer()
                    batteryBadge(level: level, chargingState: car.chargingState)
                }
            }

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

                
            }

            HStack(spacing: 6) {
                tireDataView
                
                if let health = car.tireHealthPercentage {
                    Spacer()
                    VStack {
                        if let mileage = car.mileage {
//                            Text("·")
//                                .foregroundStyle(.te	rtiary)
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
//                            Text("No gps")
//                                .foregroundStyle(.tertiary)
                            #endif
                        }
//                        Text("\(Int(health))%")
//                            .font(.caption2)
//                            .fontWeight(.medium)
//                            .foregroundStyle(healthColor(for: health))
                    }
                }

            }
        }
        .padding(.vertical, 2)
    }
    
    @ViewBuilder
    private var tireDataView: some View {
        let hasTpms = TirePosition.allCases.contains { car.tpmsPressure(for: $0) != nil }
        let hasTread = car.tireHealthPercentage != nil

        if hasTpms || hasTread {
            Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 1) {
                GridRow {
                    if let health = car.tireHealthPercentage {
                        Text("\(Int(health))%")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundStyle(healthColor(for: health))
                    } else {
                        Text("-")
                    }
                    
                    ForEach(TirePosition.allCases, id: \.self) { position in
                        Text(position.abbreviation)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }
                if hasTpms {
                    GridRow {
                        Text("PSI")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        
                        ForEach(TirePosition.allCases, id: \.self) { position in
                            if let psi = car.tpmsPressure(for: position) {
                                Text(String(format: "%.0f", psi * 14.504))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("—").font(.caption2).foregroundStyle(.tertiary)
                            }
                        }
                    }
                }
                if hasTread {
                    GridRow {
                        Text(String(format: "I/32\""))
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        ForEach(TirePosition.allCases, id: \.self) { position in
                            if let tread = car.latestMeasurement(for: position)?.treadDepth {
                                Text(String(format: "%.1f", tread))
                                    .font(.caption2)
                                    .foregroundStyle(treadColor(for: tread))
                            } else {
                                Text("—").font(.caption2).foregroundStyle(.tertiary)
                            }
                        }
                    }
                }
            }
        } else {
            Text("No measurements")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func batteryBadge(level: Int, chargingState: String?) -> some View {
        let isCharging = chargingState == "Charging" || chargingState == "Starting"
        let color: Color = isCharging ? .blue : (level >= 50 ? .green : level >= 20 ? .orange : .red)
        let icon: String = {
            let bolt = isCharging ? "percent" : ""
            if level >= 88 { return "battery.100\(bolt)" }
            if level >= 63 { return "battery.75\(bolt)" }
            if level >= 38 { return "battery.50\(bolt)" }
            if level >= 13 { return "battery.25\(bolt)" }
            return "battery.0\(bolt)"
        }()
        HStack(spacing: 2) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(color)
            Text("\(level)%")
                .font(.caption2)
                .foregroundStyle(color)
        }
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
    let container = try! ModelContainer(for: Car.self, TireMeasurement.self, Tire.self, TPMSReading.self, MileageReading.self, configurations: config)

    let car = Car(name: "My Tesla", make: "Tesla", model: "Model 3", year: 2023)
    car.trimBadging = "lr awd"
    car.batteryLevel = 82
    car.chargingState = "Charging"
    container.mainContext.insert(car)

    let mileage = MileageReading(date: Date(), mileage: 24_831)
    mileage.car = car
    container.mainContext.insert(mileage)

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
    .environment(LocationManager())
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
    .environment(LocationManager())
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
    .environment(LocationManager())
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
    .environment(LocationManager())
}
