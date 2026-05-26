//
//  LogMileageView.swift
//  TeslaCare
//

import SwiftUI
import SwiftData

struct LogMileageView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let car: Car

    @State private var mileageText: String
    @State private var date: Date = Date()

    init(car: Car) {
        self.car = car
        _mileageText = State(initialValue: car.mileage.map { String($0) } ?? "")
    }

    private var mileageValue: Int? {
        Int(mileageText.filter(\.isNumber))
    }

    private var isValid: Bool {
        guard let value = mileageValue else { return false }
        return value > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Odometer Reading") {
                    HStack {
                        TextField("Miles", text: $mileageText)
                            .keyboardType(.numberPad)
                        Text("mi")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Date") {
                    DatePicker("Date", selection: $date, in: ...Date(), displayedComponents: .date)
                        .labelsHidden()
                }

                if let current = car.mileage, let entered = mileageValue, entered < current {
                    Section {
                        Label("Lower than current reading of \(current.formatted()) mi", systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Update Mileage")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!isValid)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func save() {
        guard let value = mileageValue else { return }
        let reading = MileageReading(date: date, mileage: value, source: "manual")
        reading.car = car
        modelContext.insert(reading)
        dismiss()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Car.self, configurations: config)
    let car = Car(name: "My Tesla", make: "Tesla", model: "Model 3", year: 2022)
    container.mainContext.insert(car)
    return LogMileageView(car: car)
        .modelContainer(container)
}
