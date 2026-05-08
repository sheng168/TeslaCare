//
//  TireRowView.swift
//  TeslaCare
//
//  Created by Jin on 5/8/26.
//

import SwiftUI
import SwiftData

struct TireRowView: View {
    let tire: Tire
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Primary tire info
            HStack {
                Text(tire.displayName)
                    .font(.headline)
                
                Spacer()
                
                // Status badge
                if tire.needsReplacement {
                    Label("Replace", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red)
                        .clipShape(Capsule())
                }
            }
            
            // Size and position
            HStack(spacing: 12) {
                Label(tire.size, systemImage: "ruler")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Label(tire.position.rawValue, systemImage: tire.position.systemImage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            // Tread depth and wear info
            if let latestMeasurement = tire.latestMeasurement {
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Tread Depth")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(latestMeasurement.treadDepthFormatted)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(treadColor(for: latestMeasurement))
                    }
                    
                    if let wearPercentage = tire.wearPercentage {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Wear")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text("\(Int(wearPercentage))%")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                    }
                    
                    Spacer()
                    
                    // Age indicator
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Age")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text("\(tire.ageInMonths) mo")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
                .padding(.top, 4)
            } else {
                Text("No measurements yet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func treadColor(for measurement: TireMeasurement) -> Color {
        if measurement.isDanger {
            return .red
        } else if measurement.isWarning {
            return .orange
        } else {
            return .green
        }
    }
}

#Preview("Tire - Good Condition") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Tire.self, TireMeasurement.self, configurations: config)
    
    let tire = Tire(
        brand: "Michelin",
        modelName: "Pilot Sport 4S",
        size: "235/45R18",
        dotNumber: "DOT1234",
        purchaseDate: Date().addingTimeInterval(-180 * 24 * 60 * 60), // 6 months ago
        installDate: Date().addingTimeInterval(-150 * 24 * 60 * 60),
        initialTreadDepth: 10.0,
        purchasePrice: 250.0,
        currentPosition: .frontLeft,
        mileageAtInstall: 25000,
        notes: ""
    )
    container.mainContext.insert(tire)
    
    let measurement = TireMeasurement(
        date: Date(),
        treadDepth: 8.5,
        position: .frontLeft,
        tire: tire,
        notes: "",
        mileage: 28000
    )
    container.mainContext.insert(measurement)
    
    return List {
        TireRowView(tire: tire)
    }
    .modelContainer(container)
}

#Preview("Tire - Warning") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Tire.self, TireMeasurement.self, configurations: config)
    
    let tire = Tire(
        brand: "Goodyear",
        modelName: "Eagle F1",
        size: "245/40R19",
        dotNumber: "DOT5678",
        purchaseDate: Date().addingTimeInterval(-730 * 24 * 60 * 60), // 2 years ago
        installDate: Date().addingTimeInterval(-700 * 24 * 60 * 60),
        initialTreadDepth: 10.0,
        purchasePrice: 200.0,
        currentPosition: .rearRight,
        mileageAtInstall: 15000,
        notes: ""
    )
    container.mainContext.insert(tire)
    
    let measurement = TireMeasurement(
        date: Date(),
        treadDepth: 3.5,
        position: .rearRight,
        tire: tire,
        notes: "",
        mileage: 35000
    )
    container.mainContext.insert(measurement)
    
    return List {
        TireRowView(tire: tire)
    }
    .modelContainer(container)
}

#Preview("Tire - Needs Replacement") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Tire.self, TireMeasurement.self, configurations: config)
    
    let tire = Tire(
        brand: "Bridgestone",
        modelName: "Turanza",
        size: "225/50R17",
        dotNumber: "DOT9012",
        purchaseDate: Date().addingTimeInterval(-1095 * 24 * 60 * 60), // 3 years ago
        installDate: Date().addingTimeInterval(-1065 * 24 * 60 * 60),
        initialTreadDepth: 10.0,
        purchasePrice: 180.0,
        currentPosition: .frontRight,
        mileageAtInstall: 10000,
        notes: "Showing uneven wear"
    )
    container.mainContext.insert(tire)
    
    let measurement = TireMeasurement(
        date: Date(),
        treadDepth: 1.8,
        position: .frontRight,
        tire: tire,
        notes: "Critical - needs immediate replacement",
        mileage: 45000
    )
    container.mainContext.insert(measurement)
    
    return List {
        TireRowView(tire: tire)
    }
    .modelContainer(container)
}

#Preview("Tire - No Measurements") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Tire.self, configurations: config)
    
    let tire = Tire(
        brand: "Continental",
        modelName: "ExtremeContact",
        size: "255/35R20",
        dotNumber: "DOT3456",
        purchaseDate: Date(),
        installDate: Date(),
        initialTreadDepth: 10.0,
        purchasePrice: 300.0,
        currentPosition: .rearLeft,
        mileageAtInstall: 50000,
        notes: "Just installed"
    )
    container.mainContext.insert(tire)
    
    return List {
        TireRowView(tire: tire)
    }
    .modelContainer(container)
}
