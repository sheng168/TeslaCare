//
//  ContentView.swift
//  TeslaCare
//
//  Created by Jin on 5/7/26.
//

import SwiftUI
import SwiftData
import OSLog

private let logger = Logger(subsystem: "com.teslacare", category: "CarList")

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

#Preview {
    CarListView()
        .modelContainer(for: Car.self, inMemory: true)
}
