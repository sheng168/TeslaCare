//
//  AddMeasurementView.swift
//  TeslaCare
//
//  Created by Jin on 5/7/26.
//

import SwiftUI
import SwiftData

struct AddMeasurementView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let car: Car
    let preselectedPosition: TirePosition?
    
    @State private var selectedPosition: TirePosition
    @State private var treadDepth: Double = 8.0
    @State private var date = Date()
    @State private var notes = ""
    @State private var mileage = ""
    @State private var includeMileage = false
    
    init(car: Car, preselectedPosition: TirePosition? = nil) {
        self.car = car
        self.preselectedPosition = preselectedPosition
        let position = preselectedPosition ?? .frontLeft
        _selectedPosition = State(initialValue: position)
        
        // Prefill tread depth with latest measurement for the selected position
        if let latestMeasurement = car.latestMeasurement(for: position) {
            _treadDepth = State(initialValue: latestMeasurement.treadDepth)
        } else {
            _treadDepth = State(initialValue: 8.0)
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Tire Information") {
                    Picker("Tire Position", selection: $selectedPosition) {
                        ForEach(TirePosition.allCases, id: \.self) { position in
                            HStack {
                                Image(systemName: position.systemImage)
                                Text(position.rawValue)
                            }
                            .tag(position)
                        }
                    }
                    .onChange(of: selectedPosition) { oldValue, newValue in
                        // Update tread depth when position changes
                        if let latestMeasurement = car.latestMeasurement(for: newValue) {
                            treadDepth = latestMeasurement.treadDepth
                        } else {
                            treadDepth = 8.0
                        }
                    }
                    
                    // Display tire ID/info if a tire exists at the selected position
                    if let tire = car.tires?.first(where: { $0.position == selectedPosition }) {
                        VStack(alignment: .leading, spacing: 4) {
                            Label {
                                Text(tire.displayName)
                                    .fontWeight(.medium)
                            } icon: {
                                Image(systemName: "car.circle.fill")
                                    .foregroundStyle(.blue)
                            }
                            
                            if !tire.size.isEmpty {
                                Text("Size: \(tire.size)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            if !tire.dotNumber.isEmpty {
                                Text("DOT: \(tire.dotNumber)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            // Show latest measurement info
                            if let latest = car.latestMeasurement(for: selectedPosition) {
                                Divider()
                                    .padding(.vertical, 4)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Last Measurement")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .textCase(.uppercase)
                                    
                                    HStack {
                                        Text(latest.treadDepthFormatted)
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(treadColor(for: latest.treadDepth))
                                        
                                        Text("•")
                                            .foregroundStyle(.secondary)
                                        
                                        Text(latest.date, style: .date)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    } else {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundStyle(.secondary)
                            Text("No tire registered at this position")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }
                
                Section("Tread Depth") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Depth: ")
                            Text(String(format: "%.1f/32\"", treadDepth))
                                .fontWeight(.bold)
                                .foregroundStyle(treadColor(for: treadDepth))
                            
                            Spacer()
                            
                            if treadDepth <= 2.0 {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.red)
                                Text("Replace Now")
                                    .font(.caption)
                                    .foregroundStyle(.red)
                            } else if treadDepth <= 4.0 {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundStyle(.orange)
                                Text("Monitor Closely")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                            }
                        }
                        
                        // Stepper for precise adjustments
                        Stepper(value: $treadDepth, in: 0...12, step: 0.5) {
                            HStack {
                                Image(systemName: "minus.circle")
                                    .foregroundStyle(.secondary)
                                Text("Adjust by 0.5/32\"")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Image(systemName: "plus.circle")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                        
                        Divider()
                        
                        // Slider for quick adjustments
                        Slider(value: $treadDepth, in: 0...12, step: 0.5) {
                            Text("Tread Depth")
                        } minimumValueLabel: {
                            Text("0")
                                .font(.caption)
                        } maximumValueLabel: {
                            Text("12")
                                .font(.caption)
                        }
                        
                        // Visual guide
                        HStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(.red)
                                .frame(height: 4)
                            RoundedRectangle(cornerRadius: 2)
                                .fill(.orange)
                                .frame(height: 4)
                            RoundedRectangle(cornerRadius: 2)
                                .fill(.green)
                                .frame(height: 4)
                        }
                        
                        HStack {
                            Text("Replace")
                                .font(.caption2)
                            Spacer()
                            Text("Monitor")
                                .font(.caption2)
                            Spacer()
                            Text("Good")
                                .font(.caption2)
                        }
                        .foregroundStyle(.secondary)
                    }
                    
                    Text("Use a tire tread depth gauge to measure the depth in 32nds of an inch. New tires typically start at 10-11/32\". Replace at 2/32\" or less.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Section("Additional Information") {
                    Toggle("Include Mileage", isOn: $includeMileage)
                    
                    if includeMileage {
                        TextField("Mileage", text: $mileage)
                            .keyboardType(.numberPad)
                    }
                    
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Add Measurement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addMeasurement()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func treadColor(for depth: Double) -> Color {
        if depth <= 2.0 {
            return .red
        } else if depth <= 4.0 {
            return .orange
        } else {
            return .green
        }
    }
    
    private func addMeasurement() {
        let mileageValue = includeMileage ? Int(mileage) : nil
        
        // Find or create a tire at the selected position
        let tire: Tire
        if let existingTire = car.tires?.first(where: { $0.position == selectedPosition }) {
            tire = existingTire
        } else {
            // Create a placeholder tire if none exists at this position
            tire = Tire(brand: "", modelName: "", size: "", currentPosition: selectedPosition)
            tire.car = car
            modelContext.insert(tire)
        }
        
        let measurement = TireMeasurement(
            date: date,
            treadDepth: treadDepth,
            position: selectedPosition,
            tire: tire,
            notes: notes,
            mileage: mileageValue
        )
        
        measurement.car = car
        modelContext.insert(measurement)
        
        dismiss()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Car.self, TireMeasurement.self, Tire.self, configurations: config)
    
    let car = Car(name: "My Tesla", make: "Tesla", model: "Model 3", year: 2023)
    container.mainContext.insert(car)
    
    // Add some tires to the car
    for position in TirePosition.allCases {
        let tire = Tire(brand: "Michelin", modelName: "Pilot Sport", size: "235/45R18", currentPosition: position)
        tire.car = car
        container.mainContext.insert(tire)
    }
    
    return AddMeasurementView(car: car)
        .modelContainer(container)
}
