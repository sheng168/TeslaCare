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
    @State private var customMapping: [TirePosition: TirePosition] = TireRotationPattern.frontToBack.rotationMapping()
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
                    TextField("Add notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("Notes")
                }
                
                Section {
                    TireSwapGrid(arrangement: $customMapping) {
                        selectedPattern = .custom
                    }
                    .frame(height: 140)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .padding(.horizontal)
                } header: {
                    Text("Arrangement")
                } footer: {
                    Text(selectedPattern == .custom ? "Custom — drag tiles to reassign positions" : "Drag tiles to create a custom arrangement")
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
            .onChange(of: selectedPattern) { _, newPattern in
                if newPattern != .custom {
                    customMapping = newPattern.rotationMapping()
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
        
        // Use the live mapping (synced from predefined pattern or customised by drag-drop)
        let mapping = customMapping
        
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

// MARK: - Drag-and-Drop Tile Grid

struct TireSwapGrid: View {
    @Binding var arrangement: [TirePosition: TirePosition]
    let onSwap: () -> Void

    @State private var dragging: TirePosition?
    @State private var hoverSlot: TirePosition?

    private func tireAt(slot: TirePosition) -> TirePosition {
        arrangement.first(where: { $0.value == slot })?.key ?? slot
    }

    private func slotAt(_ point: CGPoint, in size: CGSize) -> TirePosition {
        let col = point.x < size.width / 2 ? 0 : 1
        let row = point.y < size.height / 2 ? 0 : 1
        let positions: [[TirePosition]] = [[.frontLeft, .frontRight], [.rearLeft, .rearRight]]
        return positions[row][col]
    }

    private func performSwap(from: TirePosition, to: TirePosition) {
        let sourceTire = tireAt(slot: from)
        let targetTire = tireAt(slot: to)
        arrangement[sourceTire] = to
        arrangement[targetTire] = from
        onSwap()
    }

    @ViewBuilder
    private func tileView(slot: TirePosition) -> some View {
        let tire = tireAt(slot: slot)
        let isHover = hoverSlot == slot && dragging != nil && dragging != slot
        let isDragging = dragging == slot
        VStack(spacing: 2) {
            Text(slot.abbreviation)
                .font(.caption2)
                .foregroundStyle(.tertiary)
            Text(tire.abbreviation)
                .font(.title3.bold())
                .foregroundStyle(tire != slot ? Color.accentColor : .primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(isHover ? Color.accentColor.opacity(0.15) : Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    isHover ? Color.accentColor : (isDragging ? Color.accentColor.opacity(0.5) : Color.clear),
                    lineWidth: 2
                )
        )
        .opacity(isDragging ? 0.5 : 1.0)
    }

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    tileView(slot: .frontLeft)
                    tileView(slot: .frontRight)
                }
                HStack(spacing: 10) {
                    tileView(slot: .rearLeft)
                    tileView(slot: .rearRight)
                }
            }
            .highPriorityGesture(
                DragGesture(minimumDistance: 5)
                    .onChanged { value in
                        if dragging == nil {
                            dragging = slotAt(value.startLocation, in: geo.size)
                        }
                        hoverSlot = slotAt(value.location, in: geo.size)
                    }
                    .onEnded { value in
                        defer { dragging = nil; hoverSlot = nil }
                        guard let from = dragging else { return }
                        let to = slotAt(value.location, in: geo.size)
                        guard from != to else { return }
                        performSwap(from: from, to: to)
                    }
            )
        }
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
