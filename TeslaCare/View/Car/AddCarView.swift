//
//  AddCarView.swift
//  TeslaCare
//
//  Created by Jin on 5/7/26.
//

import SwiftUI
import SwiftData
import OSLog

private let logger = Logger(subsystem: "com.teslacare", category: "AddCar")

struct AddCarView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var make = "Tesla"
    @State private var model = ""
    @State private var year = Calendar.current.component(.year, from: Date())
    @State private var mileageText = ""
    @State private var vin = ""
    @State private var showingVINScanner = false

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

                Section("VIN") {
                    HStack {
                        TextField("VIN (optional)", text: $vin)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                            .font(.system(.body, design: .monospaced))
                            .onChange(of: vin) { _, newValue in
                                let clean = newValue.uppercased()
                                if clean != newValue { vin = clean }
                                autofill(from: clean)
                            }

                        if !vin.isEmpty {
                            Button { vin = "" } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }

                        Button {
                            showingVINScanner = true
                        } label: {
                            Image(systemName: "camera.viewfinder")
                                .foregroundStyle(.blue)
                        }
                        .buttonStyle(.plain)
                    }

                    if !vin.isEmpty && vin.count != 17 {
                        Text("VIN must be 17 characters (\(vin.count)/17)")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
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
            .sheet(isPresented: $showingVINScanner) {
                VINScannerView { detected in
                    vin = detected
                    autofill(from: detected)
                }
            }
        }
    }
    
    private func autofill(from vin: String) {
        guard vin.count == 17 else { return }
        if let detectedModel = vinModel(vin), model.isEmpty { model = detectedModel }
        if let detectedYear = vinYear(vin) { year = detectedYear }
        if isTeslaVIN(vin) { make = "Tesla" }
    }

    private func isTeslaVIN(_ vin: String) -> Bool {
        vin.hasPrefix("5YJ") || vin.hasPrefix("7SA") || vin.hasPrefix("SFZ")
    }

    private func vinModel(_ vin: String) -> String? {
        guard vin.count >= 4 else { return nil }
        switch vin[vin.index(vin.startIndex, offsetBy: 3)] {
        case "S": return "Model S"
        case "X": return "Model X"
        case "3": return "Model 3"
        case "Y": return "Model Y"
        case "C": return "Cybertruck"
        default:  return nil
        }
    }

    private func vinYear(_ vin: String) -> Int? {
        guard vin.count >= 10 else { return nil }
        let yearMap: [Character: Int] = [
            "A": 2010, "B": 2011, "C": 2012, "D": 2013, "E": 2014,
            "F": 2015, "G": 2016, "H": 2017, "J": 2018, "K": 2019,
            "L": 2020, "M": 2021, "N": 2022, "P": 2023, "R": 2024,
            "S": 2025, "T": 2026
        ]
        return yearMap[vin[vin.index(vin.startIndex, offsetBy: 9)]]
    }

    private func addCar() {
        logger.info("Adding car: \(year) \(make) \(model)")
        let newCar = Car(name: name, make: make, model: model, year: year)
        if !vin.isEmpty && vin.count == 17 { newCar.vin = vin }
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
