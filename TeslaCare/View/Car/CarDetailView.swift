//
//  CarDetailView.swift
//  TeslaCare
//
//  Created by Jin on 5/7/26.
//

import SwiftUI
import SwiftData

struct CarDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let car: Car
    
    @State private var showingAddMeasurement = false
    @State private var showingRotateTires = false
    @State private var showingReplaceTires = false
    @State private var showingLogAirFilter = false
    @State private var selectedPosition: TirePosition?
    
    var sortedMeasurements: [TireMeasurement] {
        (car.measurements ?? []).sorted { $0.date > $1.date }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Car Info Header
                VStack(spacing: 8) {
                    Text(car.displayName)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("\(car.year, format: .number.grouping(.never)) \(car.make) \(car.model)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    if let health = car.tireHealthPercentage {
                        VStack(spacing: 8) {
                            Text("Overall Tire Health")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            HStack(spacing: 12) {
                                ProgressView(value: health, total: 100)
                                    .tint(healthColor(for: health))
                                    .frame(maxWidth: 200)
                                
                                Text("\(Int(health))%")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(healthColor(for: health))
                            }
                            
                            if let avg = car.averageTreadDepth {
                                Text(String(format: "Average: %.1f/32\"", avg))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: .black.opacity(0.1), radius: 5)
                    }
                }
                .padding()
                
                // Tire Grid
                TireGridView(car: car, selectedPosition: $selectedPosition)
                    .padding(.horizontal)
                
                // Action Buttons
                HStack(spacing: 12) {
                    Button(action: { showingRotateTires = true }) {
                        VStack(spacing: 4) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.title2)
                            Text("Rotate")
                                .font(.subheadline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    Button(action: { showingReplaceTires = true }) {
                        VStack(spacing: 4) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                            Text("Replace")
                                .font(.subheadline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.horizontal)
                
                // Rotation History
                if let rotations = car.rotationEvents?.sorted(by: { $0.date > $1.date }), !rotations.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Rotation History")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(rotations) { rotation in
                            RotationEventRow(rotation: rotation)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top)
                }
                
                // Replacement History
                if let replacements = car.replacementEvents?.sorted(by: { $0.date > $1.date }), !replacements.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Replacement History")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(replacements) { replacement in
                            ReplacementEventRow(replacement: replacement)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top)
                }
                
                // Air Filter History
                if let airFilters = car.airFilterChanges?.sorted(by: { $0.date > $1.date }), !airFilters.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Air Filter Changes")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(airFilters) { filterChange in
                            AirFilterChangeRow(filterChange: filterChange)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top)
                }
                
                // Measurements History
                VStack(alignment: .leading, spacing: 12) {
                    Text("Measurement History")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    if sortedMeasurements.isEmpty {
                        ContentUnavailableView(
                            "No Measurements",
                            systemImage: "gauge.with.dots.needle.0percent",
                            description: Text("Add tire measurements to track tread depth over time")
                        )
                        .frame(height: 200)
                    } else {
                        ForEach(sortedMeasurements) { measurement in
                            MeasurementRowView(measurement: measurement)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.top)
            }
            .padding(.vertical)
        }
        .navigationTitle("Tire Tracking")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingAddMeasurement = true }) {
                    Label("Add Measurement", systemImage: "plus")
                }
            }
            
            ToolbarItem(placement: .secondaryAction) {
                Button(action: { showingLogAirFilter = true }) {
                    Label("Log Air Filter", systemImage: "air.purifier.fill")
                }
            }
        }
        .sheet(isPresented: $showingAddMeasurement) {
            AddMeasurementView(car: car, preselectedPosition: selectedPosition)
        }
        .sheet(isPresented: $showingRotateTires) {
            RotateTiresView(car: car)
        }
        .sheet(isPresented: $showingReplaceTires) {
            ReplaceTiresView(car: car)
        }
        .sheet(isPresented: $showingLogAirFilter) {
            LogAirFilterChangeView(car: car)
        }
        .onChange(of: selectedPosition) { _, newValue in
            if newValue != nil {
                showingAddMeasurement = true
            }
        }
        .onChange(of: showingAddMeasurement) { _, newValue in
            if !newValue {
                selectedPosition = nil
            }
        }
    }
    
    private func healthColor(for percentage: Double) -> Color {
        switch percentage {
        case 50...100: return .green
        case 25..<50: return .orange
        default: return .red
        }
    }
}

// MARK: - Measurement Row View
struct MeasurementRowView: View {
    let measurement: TireMeasurement
    
    var body: some View {
        HStack {
            Image(systemName: measurement.position.systemImage)
                .font(.title3)
                .foregroundStyle(.secondary)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(measurement.position.rawValue)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    if measurement.isDanger {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                            .font(.caption)
                    } else if measurement.isWarning {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundStyle(.orange)
                            .font(.caption)
                    }
                }
                
                Text(measurement.date, format: .dateTime.month().day().year())
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if !measurement.notes.isEmpty {
                    Text(measurement.notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                
                if let mileage = measurement.mileage {
                    Text("\(mileage.formatted()) miles")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            Text(measurement.treadDepthFormatted)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(treadColor(for: measurement))
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
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

// MARK: - Rotation Event Row
struct RotationEventRow: View {
    let rotation: TireRotationEvent
    
    var body: some View {
        HStack {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(rotation.pattern.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(rotation.date, format: .dateTime.month().day().year())
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if !rotation.notes.isEmpty {
                    Text(rotation.notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                
                if let mileage = rotation.mileage {
                    Text("\(mileage.formatted()) miles")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: rotation.pattern.systemImage)
                .font(.title2)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Replacement Event Row
struct ReplacementEventRow: View {
    let replacement: TireReplacementEvent
    
    var body: some View {
        HStack {
            Image(systemName: "plus.circle.fill")
                .font(.title3)
                .foregroundStyle(.green)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(replacement.replacementDescription)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if !replacement.brand.isEmpty || !replacement.modelName.isEmpty {
                    Text("\(replacement.brand) \(replacement.modelName)".trimmingCharacters(in: .whitespaces))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Text(replacement.date, format: .dateTime.month().day().year())
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 8) {
                    if let mileage = replacement.mileage {
                        Text("\(mileage.formatted()) miles")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    
                    if let cost = replacement.cost {
                        Text("$\(cost, format: .number.precision(.fractionLength(2)))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                
                if !replacement.notes.isEmpty {
                    Text(replacement.notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            VStack(spacing: 2) {
                ForEach(replacement.replacedPositions.prefix(2), id: \.self) { position in
                    Image(systemName: position.systemImage)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                if replacement.replacedCount > 2 {
                    Text("+\(replacement.replacedCount - 2)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Air Filter Change Row
struct AirFilterChangeRow: View {
    let filterChange: AirFilterChangeEvent
    
    var body: some View {
        HStack {
            Image(systemName: filterChange.filterType.systemImage)
                .font(.title3)
                .foregroundStyle(.purple)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(filterChange.filterType.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if !filterChange.brand.isEmpty {
                    Text(filterChange.brand)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Text(filterChange.date, format: .dateTime.month().day().year())
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 8) {
                    if let mileage = filterChange.mileage {
                        Text("\(mileage.formatted()) miles")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    
                    if let cost = filterChange.cost {
                        Text("$\(cost, format: .number.precision(.fractionLength(2)))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                
                if !filterChange.partNumber.isEmpty {
                    Text("Part #: \(filterChange.partNumber)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                if !filterChange.notes.isEmpty {
                    Text(filterChange.notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    NavigationStack {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: Car.self, TireMeasurement.self, Tire.self, TireRotationEvent.self, TireReplacementEvent.self, AirFilterChangeEvent.self, configurations: config)
        
        let car = Car(name: "My Tesla", make: "Tesla", model: "Model 3", year: 2023)
        container.mainContext.insert(car)
        
        // Create tires
        let tire1 = Tire(brand: "Michelin", modelName: "Pilot Sport", size: "235/45R18", currentPosition: .frontLeft)
        tire1.car = car
        container.mainContext.insert(tire1)
        
        let tire2 = Tire(brand: "Michelin", modelName: "Pilot Sport", size: "235/45R18", currentPosition: .frontRight)
        tire2.car = car
        container.mainContext.insert(tire2)
        
        // Create measurements with required tire parameter
        let measurement1 = TireMeasurement(date: Date(), treadDepth: 7.5, position: .frontLeft, tire: tire1, notes: "", mileage: nil)
        measurement1.car = car
        container.mainContext.insert(measurement1)
        
        let measurement2 = TireMeasurement(date: Date().addingTimeInterval(-86400), treadDepth: 3.2, position: .frontRight, tire: tire2, notes: "", mileage: nil)
        measurement2.car = car
        container.mainContext.insert(measurement2)
        
        return CarDetailView(car: car)
            .modelContainer(container)
    }
}
