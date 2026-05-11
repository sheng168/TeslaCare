//
//  TireGridView.swift
//  TeslaCare
//
//  Created by Jin on 5/7/26.
//

import SwiftUI
import SwiftData

struct TireGridView: View {
    let car: Car
    @Binding var selectedPosition: TirePosition?
    
    var body: some View {
        HStack(spacing: 8) {
            VStack(spacing: 12) {
                TireCardView(
                    position: .frontLeft,
                    measurement: car.latestMeasurement(for: .frontLeft),
                    tire: getTire(for: .frontLeft),
                    pressureBar: car.tpmsPressure(for: .frontLeft)
                ) { selectedPosition = .frontLeft }

                TireCardView(
                    position: .rearLeft,
                    measurement: car.latestMeasurement(for: .rearLeft),
                    tire: getTire(for: .rearLeft),
                    pressureBar: car.tpmsPressure(for: .rearLeft)
                ) { selectedPosition = .rearLeft }
            }

            Image(systemName: "car.top.door.front.left.and.front.right.open")
                .font(.system(size: 20))
                .foregroundStyle(.secondary)

            VStack(spacing: 12) {
                TireCardView(
                    position: .frontRight,
                    measurement: car.latestMeasurement(for: .frontRight),
                    tire: getTire(for: .frontRight),
                    pressureBar: car.tpmsPressure(for: .frontRight)
                ) { selectedPosition = .frontRight }

                TireCardView(
                    position: .rearRight,
                    measurement: car.latestMeasurement(for: .rearRight),
                    tire: getTire(for: .rearRight),
                    pressureBar: car.tpmsPressure(for: .rearRight)
                ) { selectedPosition = .rearRight }
            }
        }
    }
    
    // Helper function to find the tire at a specific position
    private func getTire(for position: TirePosition) -> Tire? {
        car.tires?.first { $0.position == position }
    }
}

// MARK: - Tire Card View
struct TireCardView: View {
    let position: TirePosition
    let measurement: TireMeasurement?
    let tire: Tire?
    var pressureBar: Double? = nil
    let onTap: () -> Void

    private var pressurePSI: Double? { pressureBar.map { $0 * 14.504 } }

    private var pressureColor: Color {
        guard let psi = pressurePSI else { return .secondary }
        if psi < 28 { return .red }
        if psi < 36 { return .orange }
        return .primary
    }
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            // Haptic feedback
            #if os(iOS)
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            #endif
            
            onTap()
        }) {
            VStack(spacing: 3) {
                HStack(spacing: 4) {
                    Image(systemName: position.systemImage)
                        .font(.caption)
                    Text(position.rawValue)
                        .font(.caption)
                        .fontWeight(.medium)
                }

                if let measurement = measurement {
                    HStack(spacing: 4) {
                        Text(measurement.treadDepthFormatted)
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundStyle(treadColor(for: measurement))
                        if measurement.isDanger {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                                .font(.caption2)
                        } else if measurement.isWarning {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundStyle(.orange)
                                .font(.caption2)
                        }
                    }
                } else {
                    HStack(spacing: 3) {
                        Image(systemName: "plus.circle.fill")
                            .font(.caption2)
                            .foregroundStyle(.blue)
                        Text("No data")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                if let psi = pressurePSI {
                    Text(String(format: "%.0f PSI", psi))
                        .font(.caption2)
                        .foregroundStyle(pressureColor)
                }

                if let tire {
                    Text(tire.displayName)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.accentColor.opacity(isPressed ? 0.5 : 0), lineWidth: 2)
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    isPressed = true
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
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

#Preview("All Tires - Good Health") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Car.self, TireMeasurement.self, Tire.self, configurations: config)
    
    let car = Car(name: "My Tesla", make: "Tesla", model: "Model 3", year: 2023)
    container.mainContext.insert(car)
    
    // Add good measurements for all tires
    for position in TirePosition.allCases {
        let tire = Tire(brand: "Michelin", modelName: "Pilot Sport", size: "235/45R18", currentPosition: position)
        tire.car = car
        container.mainContext.insert(tire)
        
        let measurement = TireMeasurement(date: Date(), treadDepth: 8.0, position: position, tire: tire, notes: "", mileage: nil)
        measurement.car = car
        container.mainContext.insert(measurement)
    }
    
    return PreviewWrapper(car: car)
        .modelContainer(container)
}

private struct PreviewWrapper: View {
    let car: Car
    @State private var selectedPosition: TirePosition? = nil
    
    var body: some View {
        VStack {
            TireGridView(car: car, selectedPosition: $selectedPosition)
                .padding()
            
            if let selected = selectedPosition {
                Text("Selected: \(selected.rawValue)")
                    .font(.caption)
            }
        }
    }
}

#Preview("Mixed Tire Health") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Car.self, TireMeasurement.self, Tire.self, configurations: config)
    
    let car = Car(name: "Work Truck", make: "Ford", model: "F-150", year: 2020)
    container.mainContext.insert(car)
    
    // Front left - good
    let tireFL = Tire(brand: "Goodyear", modelName: "Wrangler", size: "265/70R17", currentPosition: .frontLeft)
    tireFL.car = car
    container.mainContext.insert(tireFL)
    let fl = TireMeasurement(date: Date(), treadDepth: 7.5, position: .frontLeft, tire: tireFL, notes: "", mileage: nil)
    fl.car = car
    container.mainContext.insert(fl)
    
    // Front right - warning
    let tireFR = Tire(brand: "Goodyear", modelName: "Wrangler", size: "265/70R17", currentPosition: .frontRight)
    tireFR.car = car
    container.mainContext.insert(tireFR)
    let fr = TireMeasurement(date: Date(), treadDepth: 3.5, position: .frontRight, tire: tireFR, notes: "", mileage: nil)
    fr.car = car
    container.mainContext.insert(fr)
    
    // Rear left - danger
    let tireRL = Tire(brand: "Goodyear", modelName: "Wrangler", size: "265/70R17", currentPosition: .rearLeft)
    tireRL.car = car
    container.mainContext.insert(tireRL)
    let rl = TireMeasurement(date: Date(), treadDepth: 1.8, position: .rearLeft, tire: tireRL, notes: "", mileage: nil)
    rl.car = car
    container.mainContext.insert(rl)
    
    // Rear right - good
    let tireRR = Tire(brand: "Goodyear", modelName: "Wrangler", size: "265/70R17", currentPosition: .rearRight)
    tireRR.car = car
    container.mainContext.insert(tireRR)
    let rr = TireMeasurement(date: Date(), treadDepth: 8.2, position: .rearRight, tire: tireRR, notes: "", mileage: nil)
    rr.car = car
    container.mainContext.insert(rr)
    
    return PreviewWrapper(car: car)
        .modelContainer(container)
}

#Preview("No Measurements") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Car.self, TireMeasurement.self, configurations: config)
    
    let car = Car(name: "New Car", make: "Honda", model: "Accord", year: 2024)
    container.mainContext.insert(car)
    
    return PreviewWrapper(car: car)
        .modelContainer(container)
}

#Preview("Single Tire Card - Good") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Car.self, TireMeasurement.self, Tire.self, configurations: config)
    
    let car = Car(name: "Test", make: "Test", model: "Test", year: 2023)
    container.mainContext.insert(car)
    
    let tire = Tire(brand: "Michelin", modelName: "Pilot Sport", size: "235/45R18", currentPosition: .frontLeft)
    tire.car = car
    container.mainContext.insert(tire)
    
    let measurement = TireMeasurement(date: Date(), treadDepth: 8.5, position: .frontLeft, tire: tire, notes: "", mileage: nil)
    measurement.car = car
    container.mainContext.insert(measurement)
    
    return TireCardView(
        position: .frontLeft,
        measurement: measurement,
        tire: tire,
        onTap: {
            print("Tapped!")
        }
    )
    .frame(width: 150)
    .padding()
    .modelContainer(container)
}

#Preview("Single Tire Card - Warning") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Car.self, TireMeasurement.self, Tire.self, configurations: config)
    
    let car = Car(name: "Test", make: "Test", model: "Test", year: 2023)
    container.mainContext.insert(car)
    
    let tire = Tire(brand: "Goodyear", modelName: "Eagle F1", size: "245/40R19", currentPosition: .frontRight)
    tire.car = car
    container.mainContext.insert(tire)
    
    let measurement = TireMeasurement(date: Date(), treadDepth: 3.2, position: .frontRight, tire: tire, notes: "", mileage: nil)
    measurement.car = car
    container.mainContext.insert(measurement)
    
    return TireCardView(
        position: .frontRight,
        measurement: measurement,
        tire: tire,
        onTap: {
            print("Tapped!")
        }
    )
    .frame(width: 150)
    .padding()
    .modelContainer(container)
}

#Preview("Single Tire Card - Danger") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Car.self, TireMeasurement.self, Tire.self, configurations: config)
    
    let car = Car(name: "Test", make: "Test", model: "Test", year: 2023)
    container.mainContext.insert(car)
    
    let tire = Tire(brand: "Bridgestone", modelName: "Turanza", size: "225/50R17", currentPosition: .rearLeft)
    tire.car = car
    container.mainContext.insert(tire)
    
    let measurement = TireMeasurement(date: Date(), treadDepth: 1.5, position: .rearLeft, tire: tire, notes: "", mileage: nil)
    measurement.car = car
    container.mainContext.insert(measurement)
    
    return TireCardView(
        position: .rearLeft,
        measurement: measurement,
        tire: tire,
        onTap: {
            print("Tapped!")
        }
    )
    .frame(width: 150)
    .padding()
    .modelContainer(container)
}

#Preview("Single Tire Card - No Data") {
    return TireCardView(
        position: .rearRight,
        measurement: nil,
        tire: nil,
        onTap: {
            print("Tapped!")
        }
    )
    .frame(width: 150)
    .padding()
}
