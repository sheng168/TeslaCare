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
                
                // Rotate Tires Button
                Button(action: { showingRotateTires = true }) {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text("Rotate Tires")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
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
        }
        .sheet(isPresented: $showingAddMeasurement) {
            AddMeasurementView(car: car, preselectedPosition: selectedPosition)
        }
        .sheet(isPresented: $showingRotateTires) {
            RotateTiresView(car: car)
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

#Preview {
    NavigationStack {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: Car.self, TireMeasurement.self, TireRotationEvent.self, configurations: config)
        
        let car = Car(name: "My Tesla", make: "Tesla", model: "Model 3", year: 2023)
        container.mainContext.insert(car)
        
        let measurement1 = TireMeasurement(date: Date(), treadDepth: 7.5, position: .frontLeft)
        measurement1.car = car
        container.mainContext.insert(measurement1)
        
        let measurement2 = TireMeasurement(date: Date().addingTimeInterval(-86400), treadDepth: 3.2, position: .frontRight)
        measurement2.car = car
        container.mainContext.insert(measurement2)
        
        return CarDetailView(car: car)
            .modelContainer(container)
    }
}
