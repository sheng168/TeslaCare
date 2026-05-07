//
//  ContentView.swift
//  TeslaCare
//
//  Created by Jin on 5/7/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Car.dateAdded, order: .reverse) private var cars: [Car]
    @State private var showingAddCar = false

    var body: some View {
        NavigationSplitView {
            List {
                ForEach(cars) { car in
                    NavigationLink {
                        CarDetailView(car: car)
                    } label: {
                        CarRowView(car: car)
                    }
                }
                .onDelete(perform: deleteCars)
            }
            .navigationTitle("My Cars")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: { showingAddCar = true }) {
                        Label("Add Car", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddCar) {
                AddCarView()
            }
            .overlay {
                if cars.isEmpty {
                    ContentUnavailableView(
                        "No Cars",
                        systemImage: "car.fill",
                        description: Text("Add a car to start tracking tire tread depth")
                    )
                }
            }
        } detail: {
            Text("Select a car")
                .foregroundStyle(.secondary)
        }
    }

    private func deleteCars(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(cars[index])
            }
        }
    }
}

// MARK: - Car Row View
struct CarRowView: View {
    let car: Car
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(car.displayName)
                .font(.headline)
            
            Text("\(car.year) \(car.make) \(car.model)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            if let health = car.tireHealthPercentage {
                HStack(spacing: 8) {
                    ProgressView(value: health, total: 100)
                        .tint(healthColor(for: health))
                        .frame(maxWidth: 150)
                    
                    Text("\(Int(health))%")
                        .font(.caption)
                        .foregroundStyle(healthColor(for: health))
                }
            } else {
                Text("No measurements")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func healthColor(for percentage: Double) -> Color {
        switch percentage {
        case 50...100: return .green
        case 25..<50: return .orange
        default: return .red
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Car.self, inMemory: true)
}
