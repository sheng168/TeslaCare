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
    @State private var showingTeslaLogin = false
    @State private var showingAddMenu = false

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
                    Menu {
                        Button {
                            showingAddCar = true
                        } label: {
                            Label("Add Car Manually", systemImage: "plus")
                        }
                        
                        Button {
                            showingTeslaLogin = true
                        } label: {
                            Label("Connect Tesla Account", systemImage: "bolt.car.fill")
                        }
                    } label: {
                        Label("Add Car", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddCar) {
                AddCarView()
            }
            .sheet(isPresented: $showingTeslaLogin) {
                TeslaLoginView()
            }
            .overlay {
                if cars.isEmpty {
                    ContentUnavailableView {
                        Label("No Cars", systemImage: "car.fill")
                    } description: {
                        Text("Add a car to start tracking tire tread depth")
                    } actions: {
                        VStack(spacing: 12) {
                            Button {
                                showingTeslaLogin = true
                            } label: {
                                Label("Connect Tesla Account", systemImage: "bolt.car.fill")
                            }
                            .buttonStyle(.borderedProminent)
                            
                            Button {
                                showingAddCar = true
                            } label: {
                                Label("Add Car Manually", systemImage: "plus")
                            }
                            .buttonStyle(.bordered)
                        }
                    }
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
