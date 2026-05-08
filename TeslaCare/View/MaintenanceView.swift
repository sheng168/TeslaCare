//
//  MaintenanceView.swift
//  TeslaCare
//
//  Created by Jin on 5/8/26.
//

import SwiftUI
import SwiftData

struct MaintenanceView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Car.dateAdded, order: .reverse) private var cars: [Car]
    
    var body: some View {
        NavigationStack {
            List {
                if !cars.isEmpty {
                    ForEach(cars) { car in
                        Section {
                            NavigationLink {
                                CarMaintenanceDetailView(car: car)
                            } label: {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(car.displayName)
                                        .font(.headline)
                                    
                                    Text("\(car.year, format: .number.grouping(.never)) \(car.make) \(car.model)")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        } header: {
                            Text(car.displayName)
                        }
                    }
                } else {
                    ContentUnavailableView(
                        "No Cars",
                        systemImage: "car.fill",
                        description: Text("Add a car in the Cars tab to track maintenance")
                    )
                }
            }
            .navigationTitle("Maintenance")
        }
    }
}

struct CarMaintenanceDetailView: View {
    let car: Car
    @State private var showingRotateTires = false
    @State private var showingReplaceTires = false
    @State private var showingLogAirFilter = false
    
    var body: some View {
        List {
            Section("Tire Maintenance") {
                NavigationLink {
                    TireRotationHistoryView(car: car)
                } label: {
                    Label("Rotation History", systemImage: "arrow.triangle.2.circlepath")
                }
                
                NavigationLink {
                    TireReplacementHistoryView(car: car)
                } label: {
                    Label("Replacement History", systemImage: "plus.circle.fill")
                }
                
                Button {
                    showingRotateTires = true
                } label: {
                    Label("Log Tire Rotation", systemImage: "arrow.triangle.2.circlepath")
                }
            }
            
            Section("Air Filter") {
                NavigationLink {
                    AirFilterHistoryView(car: car)
                } label: {
                    Label("Change History", systemImage: "wind")
                }
                
                Button {
                    showingLogAirFilter = true
                } label: {
                    Label("Log Air Filter Change", systemImage: "plus.circle")
                }
            }
        }
        .navigationTitle(car.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingRotateTires) {
            RotateTiresView(car: car)
        }
        .sheet(isPresented: $showingReplaceTires) {
            ReplaceTiresView(car: car)
        }
        .sheet(isPresented: $showingLogAirFilter) {
            LogAirFilterChangeView(car: car)
        }
    }
}

// MARK: - History Views

struct TireRotationHistoryView: View {
    let car: Car
    
    var rotations: [TireRotationEvent] {
        (car.rotationEvents ?? []).sorted { $0.date > $1.date }
    }
    
    var body: some View {
        List {
            if rotations.isEmpty {
                ContentUnavailableView(
                    "No Rotations",
                    systemImage: "arrow.triangle.2.circlepath",
                    description: Text("No tire rotations have been logged yet")
                )
            } else {
                ForEach(rotations) { rotation in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(rotation.date, style: .date)
                            .font(.headline)
                        
                        if let mileage = rotation.mileage {
                            Text("\(mileage, format: .number) miles")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        if !rotation.notes.isEmpty {
                            Text(rotation.notes)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Rotation History")
    }
}

struct TireReplacementHistoryView: View {
    let car: Car
    
    var replacements: [TireReplacementEvent] {
        (car.replacementEvents ?? []).sorted { $0.date > $1.date }
    }
    
    var body: some View {
        List {
            if replacements.isEmpty {
                ContentUnavailableView(
                    "No Replacements",
                    systemImage: "plus.circle.fill",
                    description: Text("No tire replacements have been logged yet")
                )
            } else {
                ForEach(replacements) { replacement in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(replacement.date, style: .date)
                            .font(.headline)
                        
                        Text(replacement.replacementDescription)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        if !replacement.brand.isEmpty {
                            Text("\(replacement.brand) \(replacement.modelName)")
                                .font(.caption)
                        }
                        
                        HStack(spacing: 16) {
                            if let mileage = replacement.mileage {
                                Label("\(mileage, format: .number) mi", systemImage: "gauge")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            if let cost = replacement.cost {
                                Label(cost.formatted(.currency(code: "USD")), systemImage: "dollarsign.circle")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        if !replacement.notes.isEmpty {
                            Text(replacement.notes)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.top, 2)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Replacement History")
    }
}

struct AirFilterHistoryView: View {
    let car: Car
    
    var changes: [AirFilterChangeEvent] {
        (car.airFilterChanges ?? []).sorted { $0.date > $1.date }
    }
    
    var body: some View {
        List {
            if changes.isEmpty {
                ContentUnavailableView(
                    "No Changes",
                    systemImage: "wind",
                    description: Text("No air filter changes have been logged yet")
                )
            } else {
                ForEach(changes) { change in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(change.date, style: .date)
                            .font(.headline)
                        
                        if let mileage = change.mileage {
                            Text("\(mileage, format: .number) miles")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        if !change.notes.isEmpty {
                            Text(change.notes)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Air Filter Changes")
    }
}

// LogAirFilterChangeView is defined in LogAirFilterChangeView.swift

// MARK: - Previews

#Preview("Maintenance View") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Car.self, configurations: config)
    
    let car = Car(name: "My Tesla", make: "Tesla", model: "Model 3", year: 2023)
    container.mainContext.insert(car)
    
    return MaintenanceView()
        .modelContainer(container)
}

#Preview("Empty Maintenance View") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Car.self, configurations: config)
    
    return MaintenanceView()
        .modelContainer(container)
}
