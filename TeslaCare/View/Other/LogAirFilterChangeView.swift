//
//  LogAirFilterChangeView.swift
//  TeslaCare
//
//  Created by Jin on 5/7/26.
//

import SwiftUI
import SwiftData
import OSLog

private let logger = AppLogger(subsystem: "com.teslacare", category: "AirFilter")

struct LogAirFilterChangeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let car: Car
    
    @State private var filterType: AirFilterType = .cabin
    @State private var changeDate = Date()
    @State private var mileage: String = ""
    @State private var brand: String = ""
    @State private var partNumber: String = ""
    @State private var cost: String = ""
    @State private var notes: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Change Date", selection: $changeDate, displayedComponents: .date)
                    
                    HStack {
                        Text("Mileage")
                        TextField("Optional", text: $mileage)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                } header: {
                    Text("Details")
                }
                
                Section {
                    Picker("Filter Type", selection: $filterType) {
                        ForEach(AirFilterType.allCases, id: \.self) { type in
                            HStack {
                                Image(systemName: type.systemImage)
                                Text(type.rawValue)
                            }
                            .tag(type)
                        }
                    }
                    
                    HStack(spacing: 8) {
                        Image(systemName: filterType.systemImage)
                            .foregroundStyle(.secondary)
                        Text(filterType.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Filter Information")
                }
                
                Section {
                    TextField("Brand", text: $brand)
                        .textContentType(.organizationName)
                    
                    TextField("Part Number (optional)", text: $partNumber)
                    
                    HStack {
                        Text("Cost")
                        TextField("Optional", text: $cost)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                } header: {
                    Text("Part Details")
                }
                
                Section {
                    TextField("Add notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("Notes")
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recommended Intervals")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        HStack {
                            Image(systemName: "fanblades.fill")
                                .foregroundStyle(.secondary)
                            Text("Engine: Every 15,000-30,000 miles")
                                .font(.caption)
                        }
                        
                        HStack {
                            Image(systemName: "air.purifier.fill")
                                .foregroundStyle(.secondary)
                            Text("Cabin: Every 15,000-25,000 miles")
                                .font(.caption)
                        }
                        
                        Text("Check your owner's manual for specific recommendations")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .padding(.top, 4)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Maintenance Guide")
                }
            }
            .navigationTitle("Log Air Filter Change")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveAirFilterChange()
                    }
                }
            }
        }
    }
    
    private func saveAirFilterChange() {
        logger.info("Saving air filter change: type=\(filterType.rawValue), car=\(car.displayName)")
        let filterChange = AirFilterChangeEvent(
            date: changeDate,
            filterType: filterType,
            mileage: Int(mileage),
            brand: brand,
            partNumber: partNumber,
            cost: Double(cost),
            notes: notes
        )
        filterChange.car = car
        modelContext.insert(filterChange)

        try? modelContext.save()
        logger.info("Air filter change saved successfully")
        dismiss()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Car.self, AirFilterChangeEvent.self, configurations: config)
    
    let car = Car(name: "My Tesla", make: "Tesla", model: "Model 3", year: 2023)
    container.mainContext.insert(car)
    
    return LogAirFilterChangeView(car: car)
        .modelContainer(container)
}
