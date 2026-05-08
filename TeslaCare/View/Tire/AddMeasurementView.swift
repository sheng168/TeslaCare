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
        _selectedPosition = State(initialValue: preselectedPosition ?? .frontLeft)
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
                
                Section {
                    Button("Add Measurement") {
                        addMeasurement()
                    }
                    .frame(maxWidth: .infinity)
                    .fontWeight(.semibold)
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
        let measurement = TireMeasurement(
            date: date,
            treadDepth: treadDepth,
            position: selectedPosition,
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
    let container = try! ModelContainer(for: Car.self, TireMeasurement.self, configurations: config)
    
    let car = Car(name: "My Tesla", make: "Tesla", model: "Model 3", year: 2023)
    container.mainContext.insert(car)
    
    return AddMeasurementView(car: car)
        .modelContainer(container)
}
