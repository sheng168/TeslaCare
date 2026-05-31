//
//  BluetoothEntryView.swift
//  TeslaCare
//

import SwiftUI
import SwiftData

// Rapid keyboard / Bluetooth-gauge entry: all 4 tires visible at once.
// Tab advances through every field in reading order; the system handles
// within-row and cross-row navigation automatically.
struct BluetoothEntryView: View {
    let car: Car
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var pointCount = 3
    // values[tireIndex][pointIndex], up to 5 points
    @State private var values: [[String]] = Array(repeating: Array(repeating: "", count: 5), count: 4)
    @FocusState private var focusedField: FieldID?

    private let positions = TirePosition.allCases

    struct FieldID: Hashable {
        let tire: Int
        let point: Int
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                settingsBar
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                    .background(.bar)

                ScrollView {
                    VStack(spacing: 8) {
                        columnHeaders
                        ForEach(0..<4, id: \.self) { tire in
                            tireRow(tire)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }

                saveBar
            }
            .navigationTitle("Quick Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    // MARK: - Settings Bar

    private var settingsBar: some View {
        HStack(spacing: 12) {
            Text("Points per tire")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Stepper(value: $pointCount, in: 1...5) {
                Text("\(pointCount)")
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
                    .frame(width: 18)
            }
            .onChange(of: pointCount) { _, _ in
                values = Array(repeating: Array(repeating: "", count: 5), count: 4)
            }
        }
    }

    // MARK: - Column Headers

    private var columnHeaders: some View {
        HStack(spacing: 6) {
            Text("")
                .frame(width: 36)

            ForEach(0..<pointCount, id: \.self) { point in
                Text(pointLabel(point, total: pointCount))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }

            Text("Avg")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(width: 44)
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Tire Row

    private func tireRow(_ tire: Int) -> some View {
        let isActive = focusedField?.tire == tire
        let avg = rowAverage(tire)

        return HStack(spacing: 6) {
            Text(positions[tire].abbreviation)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isActive ? .blue : .primary)
                .frame(width: 36)

            ForEach(0..<pointCount, id: \.self) { point in
                let id = FieldID(tire: tire, point: point)
                TextField("—", text: $values[tire][point])
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .foregroundStyle(depthColor(values[tire][point]))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(focusedField == id
                                  ? Color.blue.opacity(0.1)
                                  : Color(.secondarySystemBackground))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(focusedField == id ? Color.blue : Color.clear, lineWidth: 1.5)
                    )
                    .focused($focusedField, equals: id)
                    .onSubmit { advanceFrom(tire: tire, point: point) }
            }

            // Running average for this tire
            Group {
                if let avg {
                    Text(String(format: "%.1f", avg))
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(avgColor(avg))
                } else {
                    Text("—")
                        .foregroundStyle(.tertiary)
                }
            }
            .font(.subheadline)
            .frame(width: 44)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isActive ? Color.blue.opacity(0.05) : Color.clear)
        )
        .animation(.easeInOut(duration: 0.15), value: isActive)
    }

    // MARK: - Save Bar

    private var saveBar: some View {
        Button(action: saveMeasurements) {
            Label("Save Measurements", systemImage: "checkmark.circle.fill")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(.blue, in: RoundedRectangle(cornerRadius: 14))
                .foregroundStyle(.white)
        }
        .padding()
        .background(.bar)
        .disabled(!hasAnyValues)
    }

    // MARK: - Logic

    private func advanceFrom(tire: Int, point: Int) {
        let nextPoint = point + 1
        if nextPoint < pointCount {
            focusedField = FieldID(tire: tire, point: nextPoint)
        } else if tire < 3 {
            focusedField = FieldID(tire: tire + 1, point: 0)
        }
        // last field of last tire: let user tap Save
    }

    private func rowAverage(_ tire: Int) -> Double? {
        let readings = values[tire].prefix(pointCount).compactMap { Double($0) }
        guard !readings.isEmpty else { return nil }
        return readings.reduce(0, +) / Double(readings.count)
    }

    private var hasAnyValues: Bool {
        (0..<4).contains { rowAverage($0) != nil }
    }

    private func saveMeasurements() {
        let date = Date()
        for (i, position) in positions.enumerated() {
            let readings = values[i].prefix(pointCount).compactMap { Double($0) }
            guard !readings.isEmpty else { continue }
            let avg = readings.reduce(0, +) / Double(readings.count)

            let tire: Tire
            if let existing = car.tires?.first(where: { $0.position == position }) {
                tire = existing
            } else {
                tire = Tire(brand: "", modelName: "", size: "", currentPosition: position)
                tire.car = car
                modelContext.insert(tire)
            }

            let inner:  Double? = pointCount >= 2 ? readings.first : nil
            let center: Double? = pointCount == 3 ? readings[1] : (pointCount == 5 ? readings[2] : nil)
            let outer:  Double? = pointCount >= 2 ? readings.last : nil

            let notes = pointCount > 1
                ? (0..<readings.count).map { "\(pointLabel($0, total: pointCount)): \(String(format: "%.1f", readings[$0]))" }.joined(separator: ", ")
                : ""

            let m = TireMeasurement(
                date: date,
                treadDepth: avg,
                position: position,
                tire: tire,
                notes: notes,
                innerDepth: inner,
                centerDepth: center,
                outerDepth: outer
            )
            m.car = car
            modelContext.insert(m)
        }
        dismiss()
    }

    // MARK: - Helpers

    private func pointLabel(_ point: Int, total: Int) -> String {
        switch total {
        case 1: return "Depth"
        case 2: return point == 0 ? "Inner" : "Outer"
        case 3: return ["Inner", "Center", "Outer"][point]
        case 4: return ["Inner", "Mid-In", "Mid-Out", "Outer"][point]
        case 5: return ["Inner", "Mid-In", "Center", "Mid-Out", "Outer"][point]
        default: return "\(point + 1)"
        }
    }

    private func depthColor(_ text: String) -> Color {
        guard let d = Double(text) else { return .primary }
        return avgColor(d)
    }

    private func avgColor(_ depth: Double) -> Color {
        if depth <= 2.0 { return .red }
        if depth <= 4.0 { return .orange }
        return .green
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Car.self, Tire.self, TireMeasurement.self, configurations: config)
    let car = Car(name: "Preview Car", make: "Tesla", model: "Model 3", year: 2023)
    container.mainContext.insert(car)
    return BluetoothEntryView(car: car)
        .modelContainer(container)
}
