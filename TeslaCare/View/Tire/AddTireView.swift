//
//  AddTireView.swift
//  TeslaCare
//
//  Created by Jin on 5/8/26.
//

import SwiftUI
import SwiftData

struct AddTireView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var cars: [Car]
    
    @State private var selectedCar: Car?
    @State private var brand: String = ""
    @State private var modelName: String = ""
    @State private var size: String = ""
    @State private var dotNumber: String = ""
    @State private var purchaseDate: Date = Date()
    @State private var installDate: Date = Date()
    @State private var initialTreadDepth: Double = 10.0
    @State private var purchasePrice: String = ""
    @State private var currentPosition: TirePosition = .frontLeft
    @State private var mileageAtInstall: String = ""
    @State private var notes: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Car") {
                    Picker("Select Car", selection: $selectedCar) {
                        Text("Select a car").tag(nil as Car?)
                        ForEach(cars) { car in
                            Text(car.displayName).tag(car as Car?)
                        }
                    }
                    
                    if cars.isEmpty {
                        Text("No cars available. Add a car first.")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                }
                
                Section("Tire Details") {
                    TextField("Brand (e.g., Michelin)", text: $brand)
                    TextField("Model (e.g., Pilot Sport 4S)", text: $modelName)
                    TextField("Size (e.g., 235/45R18)", text: $size)
                    TextField("DOT Number", text: $dotNumber)
                }
                
                Section("Position") {
                    Picker("Current Position", selection: $currentPosition) {
                        ForEach(TirePosition.allCases, id: \.self) { position in
                            Label(position.rawValue, systemImage: position.systemImage)
                                .tag(position)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section("Dates") {
                    DatePicker("Purchase Date", selection: $purchaseDate, displayedComponents: .date)
                    DatePicker("Install Date", selection: $installDate, displayedComponents: .date)
                }
                
                Section("Tread and Condition") {
                    HStack {
                        Text("Initial Tread Depth")
                        Spacer()
                        TextField("10.0", value: $initialTreadDepth, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("/32\"")
                            .foregroundStyle(.secondary)
                    }
                    
                    Stepper(value: $initialTreadDepth, in: 1...15, step: 0.5) {
                        Text("Use stepper: \(initialTreadDepth, specifier: "%.1f")/32\"")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section("Optional Information") {
                    HStack {
                        Text("Purchase Price")
                        Spacer()
                        Text("$")
                        TextField("0.00", text: $purchasePrice)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                    
                    HStack {
                        Text("Mileage at Install")
                        Spacer()
                        TextField("0", text: $mileageAtInstall)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                        Text("mi")
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Add Tire")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addTire()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }
    
    private var canSave: Bool {
        !brand.isEmpty && 
        !modelName.isEmpty && 
        !size.isEmpty &&
        selectedCar != nil
    }
    
    private func addTire() {
        guard let car = selectedCar else { return }
        
        let price = Double(purchasePrice)
        let mileage = Int(mileageAtInstall)
        
        let tire = Tire(
            brand: brand,
            modelName: modelName,
            size: size,
            dotNumber: dotNumber,
            purchaseDate: purchaseDate,
            installDate: installDate,
            initialTreadDepth: initialTreadDepth,
            purchasePrice: price,
            currentPosition: currentPosition,
            mileageAtInstall: mileage,
            notes: notes
        )
        
        tire.car = car
        modelContext.insert(tire)
        
        dismiss()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Car.self, Tire.self, configurations: config)
    
    // Add some sample cars
    let car1 = Car(name: "My Tesla", make: "Tesla", model: "Model 3", year: 2023)
    container.mainContext.insert(car1)
    
    let car2 = Car(name: "Family SUV", make: "Honda", model: "CR-V", year: 2020)
    container.mainContext.insert(car2)
    
    return AddTireView()
        .modelContainer(container)
}

#Preview("No Cars") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Car.self, Tire.self, configurations: config)
    
    return AddTireView()
        .modelContainer(container)
}
