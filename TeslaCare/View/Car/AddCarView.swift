//
//  AddCarView.swift
//  TeslaCare
//
//  Created by Jin on 5/7/26.
//

import SwiftUI
import SwiftData
import OSLog

private let logger = AppLogger(subsystem: "com.teslacare", category: "AddCar")

struct AddCarView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var make = "Tesla"
    @State private var model = ""
    @State private var year = Calendar.current.component(.year, from: Date())
    @State private var mileageText = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Car Information") {
                    TextField("Name (optional)", text: $name)
                        .textContentType(.name)
                    
                    TextField("Make", text: $make)
                        .textContentType(.organizationName)
                    
                    TextField("Model", text: $model)
                    
                    Picker("Year", selection: $year) {
                        ForEach((1990...Calendar.current.component(.year, from: Date()) + 1).reversed(), id: \.self) { year in
                            Text(String(year)).tag(year)
                        }
                    }

                    TextField("Mileage (optional)", text: $mileageText)
                        .keyboardType(.numberPad)
                }
                
                Section {
                    Text("If you don't provide a name, the car will be identified as \"\(year, format: .number.grouping(.never)) \(make.isEmpty ? "Make" : make) \(model.isEmpty ? "Model" : model)\"")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Add Car")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addCar()
                    }
                    .disabled(make.isEmpty || model.isEmpty)
                }
            }
        }
    }
    
    private func addCar() {
        logger.info("Adding car: \(year) \(make) \(model)")
        let newCar = Car(name: name, make: make, model: model, year: year)
        modelContext.insert(newCar)
        if let miles = Int(mileageText) {
            let reading = MileageReading(date: Date(), mileage: miles, source: "manual")
            reading.car = newCar
            modelContext.insert(reading)
            logger.info("Added initial mileage reading: \(miles) mi")
        }
        logger.info("Car added successfully: \(newCar.displayName)")
        dismiss()
    }
}

#Preview {
    AddCarView()
        .modelContainer(for: Car.self, inMemory: true)
}
