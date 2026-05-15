//
//  ContentView.swift
//  TeslaCare
//
//  Created by Jin on 5/7/26.
//

import SwiftUI
import SwiftData
import OSLog

private let logger = AppLogger(subsystem: "com.teslacare", category: "CarList")

enum CarSortOrder: String, CaseIterable {
    case lastModified = "Last Modified"
    case dateAdded = "Date Added"
    case name = "Name"
    case mileage = "Mileage"
    case batteryLevel = "Battery"
}

struct CarListView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var authManager: TeslaAuthManager
    @Query private var cars: [Car]
    @State private var showingAddCar = false
    @State private var sortOrder: CarSortOrder = .lastModified
    @State private var refreshErrorMessage: String?

    private var sortedCars: [Car] {
        switch sortOrder {
        case .lastModified: return cars.sorted { ($0.lastUpdatedAt ?? $0.dateAdded) > ($1.lastUpdatedAt ?? $1.dateAdded) }
        case .dateAdded:    return cars.sorted { $0.dateAdded > $1.dateAdded }
        case .name:         return cars.sorted { $0.displayName < $1.displayName }
        case .mileage:      return cars.sorted { ($0.mileage ?? 0) > ($1.mileage ?? 0) }
        case .batteryLevel: return cars.sorted { ($0.batteryLevel ?? -1) > ($1.batteryLevel ?? -1) }
        }
    }

    private var lastSyncedText: String? {
        guard authManager.lastSyncDate > 0 else { return nil }
        let date = Date(timeIntervalSince1970: authManager.lastSyncDate)
        return "Synced " + date.formatted(.relative(presentation: .named))
    }

    var body: some View {
        NavigationSplitView {
            List {
                ForEach(sortedCars) { car in
                    NavigationLink {
                        CarDetailView(car: car)
                    } label: {
                        CarRowView(car: car)
                    }
                }
                .onDelete(perform: deleteCars)

                if let text = lastSyncedText {
                    Section {
                        EmptyView()
                    } footer: {
                        HStack {
                            Spacer()
                            Text(text)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                            Spacer()
                        }
                    }
                }
            }
            .refreshable {
                authManager.errorMessage = nil
                await authManager.fetchVehicles()
                if let error = authManager.errorMessage {
                    withAnimation { refreshErrorMessage = error }
                } else if authManager.vehicles.isEmpty {
                    withAnimation { refreshErrorMessage = "No vehicles found. Make sure your Tesla account is connected in Settings." }
                } else {
                    withAnimation { refreshErrorMessage = nil }
                    authManager.syncCars(into: modelContext)
                }
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                if let message = refreshErrorMessage {
                    HStack(spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.white)
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(.white)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer()
                        Button {
                            withAnimation { refreshErrorMessage = nil }
                        } label: {
                            Image(systemName: "xmark")
                                .foregroundStyle(.white.opacity(0.8))
                                .font(.footnote.weight(.semibold))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.red.gradient)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .navigationTitle("\(cars.count) Cars")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Picker("Sort by", selection: $sortOrder) {
                            ForEach(CarSortOrder.allCases, id: \.self) { order in
                                Text(order.rawValue).tag(order)
                            }
                        }
                    } label: {
                        Label("Sort", systemImage: "arrow.up.arrow.down")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    if authManager.isLoading {
                        ProgressView()
                    }
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
                logger.info("Deleting car: \(sortedCars[index].displayName)")
                modelContext.delete(sortedCars[index])
            }
        }
    }
}

#Preview("Empty") {
    CarListView()
        .modelContainer(for: Car.self, inMemory: true)
        .environmentObject(TeslaAuthManager())
        .environment(LocationManager())
}

#Preview("With Cars") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Car.self, Tire.self, TireMeasurement.self, TPMSReading.self, MileageReading.self, configurations: config)
    let ctx = container.mainContext

    let car1 = Car(name: "My Tesla", make: "Tesla", model: "Model 3", year: 2023)
    car1.trimBadging = "lr awd"
    car1.batteryLevel = 82
    car1.chargingState = "Charging"
    ctx.insert(car1)
    let mileage1 = MileageReading(date: Date(), mileage: 24_831)
    mileage1.car = car1
    ctx.insert(mileage1)
    let tpms1 = TPMSReading(date: Date(), frontLeft: 2.93, frontRight: 2.93, rearLeft: 2.76, rearRight: 2.79)
    tpms1.car = car1
    ctx.insert(tpms1)
    for position in TirePosition.allCases {
        let tire = Tire(brand: "Michelin", modelName: "Pilot Sport 4S", size: "235/45R18", currentPosition: position)
        tire.car = car1
        ctx.insert(tire)
        let m = TireMeasurement(date: Date(), treadDepth: 7.5, position: position, tire: tire)
        m.car = car1
        ctx.insert(m)
    }

    let car2 = Car(name: "Family Car", make: "Tesla", model: "Model Y", year: 2022)
    car2.trimBadging = "p100d"
    car2.batteryLevel = 41
    ctx.insert(car2)
    let mileage2 = MileageReading(date: .now.addingTimeInterval(-86400), mileage: 51_200)
    mileage2.car = car2
    ctx.insert(mileage2)
    for position in TirePosition.allCases {
        let tire = Tire(brand: "Goodyear", modelName: "Eagle F1", size: "255/45R19", currentPosition: position)
        tire.car = car2
        ctx.insert(tire)
        let m = TireMeasurement(date: .now.addingTimeInterval(-86400), treadDepth: 3.5, position: position, tire: tire)
        m.car = car2
        ctx.insert(m)
    }

    let car3 = Car(name: "", make: "Tesla", model: "Cybertruck", year: 2024)
    car3.batteryLevel = 15
    ctx.insert(car3)

    return CarListView()
        .modelContainer(container)
        .environmentObject(TeslaAuthManager())
        .environment(LocationManager())
}
