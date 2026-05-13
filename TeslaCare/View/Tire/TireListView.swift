//
//  TireListView.swift
//  TeslaCare
//
//  Created by Jin on 5/8/26.
//

import SwiftUI
import SwiftData
import OSLog

private let logger = Logger(subsystem: "com.teslacare", category: "TireList")

struct TireListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Tire.installDate, order: .reverse) private var allTires: [Tire]
    @State private var showingAddTire = false

    private var groupedTires: [(key: String, tires: [Tire])] {
        var groups: [String: [Tire]] = [:]
        for tire in allTires {
            let key = tire.car?.name ?? "Unassigned"
            groups[key, default: []].append(tire)
        }
        return groups
            .map { (key: $0.key, tires: $0.value) }
            .sorted { $0.key < $1.key }
    }

    var body: some View {
        NavigationSplitView {
            Group {
                if allTires.isEmpty {
                    ContentUnavailableView(
                        "No Tires",
                        systemImage: "circle.dotted",
                        description: Text("Add a tire to start tracking wear and maintenance")
                    )
                } else {
                    List {
                        ForEach(groupedTires, id: \.key) { group in
                            Section(group.key) {
                                ForEach(group.tires) { tire in
                                    NavigationLink {
                                        TireDetailView(tire: tire)
                                    } label: {
                                        TireRowView(tire: tire)
                                    }
                                }
                                .onDelete { offsets in
                                    deleteTires(group.tires, offsets: offsets)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("All \(allTires.count) Tires")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: { showingAddTire = true }) {
                        Label("Add Tire", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddTire) {
                AddTireView()
            }
        } detail: {
            Text("Select a tire")
                .foregroundStyle(.secondary)
        }
    }

    private func deleteTires(_ tires: [Tire], offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                logger.info("Deleting tire: \(tires[index].displayName)")
                modelContext.delete(tires[index])
            }
        }
    }
}

#Preview("With Tires") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Tire.self, TireMeasurement.self, Car.self, configurations: config)
    
    // Create a car
    let car = Car(name: "My Tesla", make: "Tesla", model: "Model 3", year: 2023)
    container.mainContext.insert(car)
    
    // Add multiple tires with different conditions
    let tire1 = Tire(
        brand: "Michelin",
        modelName: "Pilot Sport 4S",
        size: "235/45R18",
        dotNumber: "DOT1234",
        purchaseDate: Date().addingTimeInterval(-180 * 24 * 60 * 60),
        installDate: Date().addingTimeInterval(-150 * 24 * 60 * 60),
        initialTreadDepth: 10.0,
        purchasePrice: 250.0,
        currentPosition: .frontLeft,
        mileageAtInstall: 25000,
        notes: ""
    )
    tire1.car = car
    container.mainContext.insert(tire1)
    
    let measurement1 = TireMeasurement(
        date: Date(),
        treadDepth: 8.5,
        position: .frontLeft,
        tire: tire1,
        notes: "",
        mileage: 28000
    )
    container.mainContext.insert(measurement1)
    
    let tire2 = Tire(
        brand: "Goodyear",
        modelName: "Eagle F1",
        size: "245/40R19",
        dotNumber: "DOT5678",
        purchaseDate: Date().addingTimeInterval(-730 * 24 * 60 * 60),
        installDate: Date().addingTimeInterval(-700 * 24 * 60 * 60),
        initialTreadDepth: 10.0,
        purchasePrice: 200.0,
        currentPosition: .frontRight,
        mileageAtInstall: 15000,
        notes: ""
    )
    tire2.car = car
    container.mainContext.insert(tire2)
    
    let measurement2 = TireMeasurement(
        date: Date(),
        treadDepth: 3.5,
        position: .frontRight,
        tire: tire2,
        notes: "",
        mileage: 35000
    )
    container.mainContext.insert(measurement2)
    
    let tire3 = Tire(
        brand: "Bridgestone",
        modelName: "Turanza",
        size: "225/50R17",
        dotNumber: "DOT9012",
        purchaseDate: Date().addingTimeInterval(-1095 * 24 * 60 * 60),
        installDate: Date().addingTimeInterval(-1065 * 24 * 60 * 60),
        initialTreadDepth: 10.0,
        purchasePrice: 180.0,
        currentPosition: .rearLeft,
        mileageAtInstall: 10000,
        notes: "Showing uneven wear"
    )
    tire3.car = car
    container.mainContext.insert(tire3)
    
    let measurement3 = TireMeasurement(
        date: Date(),
        treadDepth: 1.8,
        position: .rearLeft,
        tire: tire3,
        notes: "Critical",
        mileage: 45000
    )
    container.mainContext.insert(measurement3)
    
    let tire4 = Tire(
        brand: "Continental",
        modelName: "ExtremeContact",
        size: "255/35R20",
        dotNumber: "DOT3456",
        purchaseDate: Date(),
        installDate: Date(),
        initialTreadDepth: 10.0,
        purchasePrice: 300.0,
        currentPosition: .rearRight,
        mileageAtInstall: 50000,
        notes: "Brand new"
    )
    tire4.car = car
    container.mainContext.insert(tire4)
    
    // Unassigned tires (no car)
    let spare1 = Tire(brand: "Michelin", modelName: "Primacy 4", size: "205/55R16",
                      currentPosition: .frontLeft)
    container.mainContext.insert(spare1)
    let spareM = TireMeasurement(date: .now.addingTimeInterval(-30 * 86400), treadDepth: 9.0,
                                 position: .frontLeft, tire: spare1)
    container.mainContext.insert(spareM)

    let spare2 = Tire(brand: "Pirelli", modelName: "P Zero", size: "245/40R19",
                      currentPosition: .rearRight)
    container.mainContext.insert(spare2)

    return TireListView()
        .modelContainer(container)
}

#Preview("Empty State") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Tire.self, configurations: config)
    
    return TireListView()
        .modelContainer(container)
}
