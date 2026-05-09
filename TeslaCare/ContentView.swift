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
            .navigationTitle("\(cars.count) Cars")
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

#Preview {
    ContentView()
        .modelContainer(for: Car.self, inMemory: true)
}
