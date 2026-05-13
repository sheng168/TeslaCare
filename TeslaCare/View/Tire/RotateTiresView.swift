//
//  RotateTiresView.swift
//  TeslaCare
//
//  Created by Jin on 5/7/26.
//

import SwiftUI
import SwiftData

struct RotateTiresView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let car: Car
    
    @State private var selectedPattern: TireRotationPattern = .frontToBack
    @State private var rotationDate = Date()
    @State private var mileage: String = ""
    @State private var notes: String = ""
    @State private var showingConfirmation = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Rotation Date", selection: $rotationDate, displayedComponents: .date)
                    
                    HStack {
                        Text("Mileage")
                        TextField("Optional", text: $mileage)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                } header: {
                    Text("Details")
                }
                
                Section {
                    ForEach(TireRotationPattern.allCases, id: \.self) { pattern in
                        Button(action: { selectedPattern = pattern }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Image(systemName: pattern.systemImage)
                                            .foregroundStyle(selectedPattern == pattern ? .blue : .secondary)
                                            .font(.title3)
                                            .frame(width: 30)
                                        
                                        Text(pattern.rawValue)
                                            .foregroundStyle(.primary)
                                            .fontWeight(selectedPattern == pattern ? .semibold : .regular)
                                    }
                                    
                                    Text(pattern.description)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                
                                Spacer()
                                
                                if selectedPattern == pattern {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("Rotation Pattern")
                } footer: {
                    Text("Choose the pattern that matches how your tires were rotated")
                }
                
                Section {
                    TireRotationVisualization(pattern: selectedPattern)
                        .frame(height: 300)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                } header: {
                    Text("Visual Guide")
                }

                Section {
                    TextField("Add notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("Notes")
                }
            }
            .navigationTitle("Rotate Tires")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        showingConfirmation = true
                    }
                }
            }
            .alert("Rotate Tires?", isPresented: $showingConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Rotate", role: .destructive) {
                    rotateTires()
                }
            } message: {
                Text("This will update all tire positions according to the \(selectedPattern.rawValue) pattern. This action cannot be undone.")
            }
        }
    }
    
    private func rotateTires() {
        // Create rotation event
        let rotationEvent = TireRotationEvent(
            date: rotationDate,
            pattern: selectedPattern,
            mileage: Int(mileage),
            notes: notes
        )
        rotationEvent.car = car
        modelContext.insert(rotationEvent)
        
        // Get the mapping for this rotation pattern
        let mapping = selectedPattern.rotationMapping()
        
        // Get the current tires and their latest measurements
        var currentTireData: [TirePosition: (tire: Tire, measurement: TireMeasurement?)] = [:]
        for position in TirePosition.allCases {
            if let tire = car.tires?.first(where: { $0.position == position }) {
                let latestMeasurement = car.latestMeasurement(for: position)
                currentTireData[position] = (tire, latestMeasurement)
            }
        }
        
        // Update tire positions
        for (oldPosition, newPosition) in mapping {
            if let tireData = currentTireData[oldPosition] {
                // Update the tire's position
                tireData.tire.position = newPosition
                
                // Create a new measurement at the new position
                let treadDepth = tireData.measurement?.treadDepth ?? 8.0
                let newMeasurement = TireMeasurement(
                    date: rotationDate,
                    treadDepth: treadDepth,
                    position: newPosition,
                    tire: tireData.tire,
                    notes: "Rotated from \(oldPosition.rawValue)",
                    mileage: Int(mileage)
                )
                newMeasurement.car = car
                modelContext.insert(newMeasurement)
            }
        }
        
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Tire Rotation Visualization
struct TireRotationVisualization: View {
    let pattern: TireRotationPattern
    
    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let tireSize: CGFloat = size * 0.25
            let spacing: CGFloat = size * 0.15
            
            ZStack {
                // Car outline
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(Color.secondary.opacity(0.3), lineWidth: 2)
                    .frame(width: size * 0.5, height: size * 0.8)
                
                // Tires with arrows
                ForEach(TirePosition.allCases, id: \.self) { position in
                    TireWithArrow(
                        position: position,
                        targetPosition: pattern.rotationMapping()[position]!,
                        tireSize: tireSize
                    )
                    .offset(offsetForPosition(position, spacing: spacing))
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
    
    private func offsetForPosition(_ position: TirePosition, spacing: CGFloat) -> CGSize {
        switch position {
        case .frontLeft:
            return CGSize(width: -spacing, height: -spacing)
        case .frontRight:
            return CGSize(width: spacing, height: -spacing)
        case .rearLeft:
            return CGSize(width: -spacing, height: spacing)
        case .rearRight:
            return CGSize(width: spacing, height: spacing)
        }
    }
}

struct TireWithArrow: View {
    let position: TirePosition
    let targetPosition: TirePosition
    let tireSize: CGFloat
    
    var body: some View {
        VStack(spacing: 4) {
            // Tire
            ZStack {
                Circle()
                    .fill(Color.secondary.opacity(0.2))
                Circle()
                    .strokeBorder(Color.secondary, lineWidth: 3)
                
                Text(positionAbbreviation(position))
                    .font(.caption)
                    .fontWeight(.bold)
            }
            .frame(width: tireSize, height: tireSize)
            
            // Arrow indicator
            if position != targetPosition {
                Image(systemName: arrowDirection)
                    .font(.caption)
                    .foregroundStyle(.blue)
            }
        }
    }
    
    private func positionAbbreviation(_ position: TirePosition) -> String {
        switch position {
        case .frontLeft: return "FL"
        case .frontRight: return "FR"
        case .rearLeft: return "RL"
        case .rearRight: return "RR"
        }
    }
    
    private var arrowDirection: String {
        // Determine arrow based on positions
        let isFront = position == .frontLeft || position == .frontRight
        let isLeft = position == .frontLeft || position == .rearLeft
        let targetIsFront = targetPosition == .frontLeft || targetPosition == .frontRight
        let targetIsLeft = targetPosition == .frontLeft || targetPosition == .rearLeft
        
        if isFront && !targetIsFront {
            if isLeft == targetIsLeft {
                return "arrow.down"
            } else if targetIsLeft {
                return "arrow.down.left"
            } else {
                return "arrow.down.right"
            }
        } else if !isFront && targetIsFront {
            if isLeft == targetIsLeft {
                return "arrow.up"
            } else if targetIsLeft {
                return "arrow.up.left"
            } else {
                return "arrow.up.right"
            }
        } else if isLeft != targetIsLeft {
            return "arrow.left.and.right"
        }
        
        return "arrow.up"
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Car.self, TireMeasurement.self, Tire.self, TireRotationEvent.self, configurations: config)
    
    let car = Car(name: "My Tesla", make: "Tesla", model: "Model 3", year: 2023)
    container.mainContext.insert(car)
    
    // Add tires and measurements
    for position in TirePosition.allCases {
        let tire = Tire(brand: "Michelin", modelName: "Pilot Sport", size: "235/45R18", currentPosition: position)
        tire.car = car
        container.mainContext.insert(tire)
        
        let measurement = TireMeasurement(date: Date(), treadDepth: 7.5, position: position, tire: tire, notes: "", mileage: nil)
        measurement.car = car
        container.mainContext.insert(measurement)
    }
    
    return RotateTiresView(car: car)
        .modelContainer(container)
}
