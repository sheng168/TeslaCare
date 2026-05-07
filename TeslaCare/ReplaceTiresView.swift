//
//  ReplaceTiresView.swift
//  TeslaCare
//
//  Created by Jin on 5/7/26.
//

import SwiftUI
import SwiftData

struct ReplaceTiresView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let car: Car
    
    @State private var selectedPositions: Set<TirePosition> = []
    @State private var replacementDate = Date()
    @State private var mileage: String = ""
    @State private var brand: String = ""
    @State private var modelName: String = ""
    @State private var cost: String = ""
    @State private var treadDepth: String = "10.0"
    @State private var notes: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Replacement Date", selection: $replacementDate, displayedComponents: .date)
                    
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
                    TireSelectionGrid(selectedPositions: $selectedPositions)
                        .listRowInsets(EdgeInsets())
                } header: {
                    Text("Select Tires to Replace")
                } footer: {
                    Text("Tap the tires you replaced")
                }
                
                Section {
                    TextField("Brand", text: $brand)
                    TextField("Model", text: $modelName)
                    
                    HStack {
                        Text("Cost")
                        TextField("Optional", text: $cost)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                } header: {
                    Text("Tire Information")
                }
                
                Section {
                    HStack {
                        Text("Initial Tread Depth")
                        Spacer()
                        TextField("10.0", text: $treadDepth)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                        Text("/32\"")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Measurement")
                } footer: {
                    Text("New tires typically have 10/32\" to 12/32\" tread depth")
                }
                
                Section {
                    TextField("Add notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("Notes")
                }
            }
            .navigationTitle("Replace Tires")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        replaceTires()
                    }
                    .disabled(selectedPositions.isEmpty)
                }
            }
        }
    }
    
    private func replaceTires() {
        // Create replacement event
        let replacementEvent = TireReplacementEvent(
            date: replacementDate,
            positions: Array(selectedPositions),
            brand: brand,
            modelName: modelName,
            mileage: Int(mileage),
            cost: Double(cost),
            notes: notes
        )
        replacementEvent.car = car
        modelContext.insert(replacementEvent)
        
        // Create measurements for replaced tires with new tread depth
        let depth = Double(treadDepth) ?? 10.0
        for position in selectedPositions {
            let measurement = TireMeasurement(
                date: replacementDate,
                treadDepth: depth,
                position: position,
                notes: "New tire - \(brand) \(modelName)".trimmingCharacters(in: .whitespaces),
                mileage: Int(mileage)
            )
            measurement.car = car
            modelContext.insert(measurement)
        }
        
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Tire Selection Grid
struct TireSelectionGrid: View {
    @Binding var selectedPositions: Set<TirePosition>
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Tap tires to select")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top)
            
            // Top view of car with tires
            VStack(spacing: 40) {
                // Front tires
                HStack(spacing: 80) {
                    SelectableTire(
                        position: .frontLeft,
                        isSelected: selectedPositions.contains(.frontLeft)
                    ) {
                        togglePosition(.frontLeft)
                    }
                    
                    SelectableTire(
                        position: .frontRight,
                        isSelected: selectedPositions.contains(.frontRight)
                    ) {
                        togglePosition(.frontRight)
                    }
                }
                
                // Car body outline
                Rectangle()
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: 120, height: 100)
                    .overlay {
                        Text("Front")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .offset(y: -30)
                    }
                
                // Rear tires
                HStack(spacing: 80) {
                    SelectableTire(
                        position: .rearLeft,
                        isSelected: selectedPositions.contains(.rearLeft)
                    ) {
                        togglePosition(.rearLeft)
                    }
                    
                    SelectableTire(
                        position: .rearRight,
                        isSelected: selectedPositions.contains(.rearRight)
                    ) {
                        togglePosition(.rearRight)
                    }
                }
            }
            .padding(.vertical)
            
            // Quick select buttons
            HStack(spacing: 12) {
                Button("All") {
                    selectedPositions = Set(TirePosition.allCases)
                }
                .buttonStyle(.bordered)
                
                Button("Front") {
                    selectedPositions = [.frontLeft, .frontRight]
                }
                .buttonStyle(.bordered)
                
                Button("Rear") {
                    selectedPositions = [.rearLeft, .rearRight]
                }
                .buttonStyle(.bordered)
                
                Button("Clear") {
                    selectedPositions.removeAll()
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
            .padding(.bottom)
        }
    }
    
    private func togglePosition(_ position: TirePosition) {
        if selectedPositions.contains(position) {
            selectedPositions.remove(position)
        } else {
            selectedPositions.insert(position)
        }
    }
}

struct SelectableTire: View {
    let position: TirePosition
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.green.opacity(0.3) : Color.secondary.opacity(0.2))
                    Circle()
                        .strokeBorder(isSelected ? Color.green : Color.secondary, lineWidth: 3)
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.largeTitle)
                            .foregroundStyle(.green)
                    } else {
                        Image(systemName: "circle")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 70, height: 70)
                
                Text(positionAbbreviation)
                    .font(.caption2)
                    .foregroundStyle(isSelected ? .primary : .secondary)
                    .fontWeight(isSelected ? .bold : .regular)
            }
        }
        .buttonStyle(.plain)
    }
    
    private var positionAbbreviation: String {
        switch position {
        case .frontLeft: return "FL"
        case .frontRight: return "FR"
        case .rearLeft: return "RL"
        case .rearRight: return "RR"
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Car.self, TireMeasurement.self, TireReplacementEvent.self, configurations: config)
    
    let car = Car(name: "My Tesla", make: "Tesla", model: "Model 3", year: 2023)
    container.mainContext.insert(car)
    
    return ReplaceTiresView(car: car)
        .modelContainer(container)
}
