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
        VStack(spacing: 20) {
            Text("Tap any tire to add measurement")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            // Front tires
            HStack(spacing: 20) {
                TireCardView(
                    position: .frontLeft,
                    measurement: car.latestMeasurement(for: .frontLeft)
                ) {
                    selectedPosition = .frontLeft
                }
                
                TireCardView(
                    position: .frontRight,
                    measurement: car.latestMeasurement(for: .frontRight)
                ) {
                    selectedPosition = .frontRight
                }
            }
            
            Image(systemName: "car.top.door.front.left.and.front.right.open")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            
            // Rear tires
            HStack(spacing: 20) {
                TireCardView(
                    position: .rearLeft,
                    measurement: car.latestMeasurement(for: .rearLeft)
                ) {
                    selectedPosition = .rearLeft
                }
                
                TireCardView(
                    position: .rearRight,
                    measurement: car.latestMeasurement(for: .rearRight)
                ) {
                    selectedPosition = .rearRight
                }
            }
        }
    }
}

// MARK: - Tire Card View
struct TireCardView: View {
    let position: TirePosition
    let measurement: TireMeasurement?
    let onTap: () -> Void
    
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
            VStack(spacing: 8) {
                Image(systemName: position.systemImage)
                    .font(.title2)
                
                Text(position.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                
                if let measurement = measurement {
                    Text(measurement.treadDepthFormatted)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(treadColor(for: measurement))
                    
                    if measurement.isDanger {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                            .font(.caption)
                    } else if measurement.isWarning {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundStyle(.orange)
                            .font(.caption)
                    }
                } else {
                    VStack(spacing: 4) {
                        Text("No data")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Image(systemName: "plus.circle.fill")
                            .font(.caption2)
                            .foregroundStyle(.blue)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
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
    let container = try! ModelContainer(for: Car.self, TireMeasurement.self, configurations: config)
    
    let car = Car(name: "My Tesla", make: "Tesla", model: "Model 3", year: 2023)
    container.mainContext.insert(car)
    
    // Add good measurements for all tires
    for position in TirePosition.allCases {
        let measurement = TireMeasurement(date: Date(), treadDepth: 8.0, position: position)
        measurement.car = car
        container.mainContext.insert(measurement)
    }
    
    @State var selectedPosition: TirePosition? = nil
    
    return VStack {
        TireGridView(car: car, selectedPosition: $selectedPosition)
            .padding()
        
        if let selected = selectedPosition {
            Text("Selected: \(selected.rawValue)")
                .font(.caption)
        }
    }
    .modelContainer(container)
}

#Preview("Mixed Tire Health") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Car.self, TireMeasurement.self, configurations: config)
    
    let car = Car(name: "Work Truck", make: "Ford", model: "F-150", year: 2020)
    container.mainContext.insert(car)
    
    // Front left - good
    let fl = TireMeasurement(date: Date(), treadDepth: 7.5, position: .frontLeft)
    fl.car = car
    container.mainContext.insert(fl)
    
    // Front right - warning
    let fr = TireMeasurement(date: Date(), treadDepth: 3.5, position: .frontRight)
    fr.car = car
    container.mainContext.insert(fr)
    
    // Rear left - danger
    let rl = TireMeasurement(date: Date(), treadDepth: 1.8, position: .rearLeft)
    rl.car = car
    container.mainContext.insert(rl)
    
    // Rear right - good
    let rr = TireMeasurement(date: Date(), treadDepth: 8.2, position: .rearRight)
    rr.car = car
    container.mainContext.insert(rr)
    
    @State var selectedPosition: TirePosition? = nil
    
    return VStack {
        TireGridView(car: car, selectedPosition: $selectedPosition)
            .padding()
        
        if let selected = selectedPosition {
            Text("Selected: \(selected.rawValue)")
                .font(.caption)
        }
    }
    .modelContainer(container)
}

#Preview("No Measurements") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Car.self, TireMeasurement.self, configurations: config)
    
    let car = Car(name: "New Car", make: "Honda", model: "Accord", year: 2024)
    container.mainContext.insert(car)
    
    @State var selectedPosition: TirePosition? = nil
    
    return VStack {
        TireGridView(car: car, selectedPosition: $selectedPosition)
            .padding()
        
        if let selected = selectedPosition {
            Text("Selected: \(selected.rawValue)")
                .font(.caption)
        }
    }
    .modelContainer(container)
}

#Preview("Single Tire Card - Good") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Car.self, TireMeasurement.self, configurations: config)
    
    let car = Car(name: "Test", make: "Test", model: "Test", year: 2023)
    container.mainContext.insert(car)
    
    let measurement = TireMeasurement(date: Date(), treadDepth: 8.5, position: .frontLeft)
    measurement.car = car
    container.mainContext.insert(measurement)
    
    return TireCardView(
        position: .frontLeft,
        measurement: measurement
    ) {
        print("Tapped!")
    }
    .frame(width: 150)
    .padding()
    .modelContainer(container)
}

#Preview("Single Tire Card - Warning") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Car.self, TireMeasurement.self, configurations: config)
    
    let car = Car(name: "Test", make: "Test", model: "Test", year: 2023)
    container.mainContext.insert(car)
    
    let measurement = TireMeasurement(date: Date(), treadDepth: 3.2, position: .frontRight)
    measurement.car = car
    container.mainContext.insert(measurement)
    
    return TireCardView(
        position: .frontRight,
        measurement: measurement
    ) {
        print("Tapped!")
    }
    .frame(width: 150)
    .padding()
    .modelContainer(container)
}

#Preview("Single Tire Card - Danger") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Car.self, TireMeasurement.self, configurations: config)
    
    let car = Car(name: "Test", make: "Test", model: "Test", year: 2023)
    container.mainContext.insert(car)
    
    let measurement = TireMeasurement(date: Date(), treadDepth: 1.5, position: .rearLeft)
    measurement.car = car
    container.mainContext.insert(measurement)
    
    return TireCardView(
        position: .rearLeft,
        measurement: measurement
    ) {
        print("Tapped!")
    }
    .frame(width: 150)
    .padding()
    .modelContainer(container)
}

#Preview("Single Tire Card - No Data") {
    return TireCardView(
        position: .rearRight,
        measurement: nil
    ) {
        print("Tapped!")
    }
    .frame(width: 150)
    .padding()
}
