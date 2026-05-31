//
//  BluetoothEntryView.swift
//  TeslaCare
//

import SwiftUI
import SwiftData

// Input unit for Bluetooth/gauge entry — stored persistently via @AppStorage.
// All values are converted to 32nds of an inch before saving (app-wide convention).
private enum TreadUnit: String, CaseIterable {
    case thirtySeconds = "32\""
    case inches = "in"
    case mm = "mm"

    // Convert a user-entered value to 32nds of an inch for storage.
    func toThirtySeconds(_ value: Double) -> Double {
        switch self {
        case .thirtySeconds: return value
        case .inches:        return value * 32
        case .mm:            return value * (32 / 25.4)
        }
    }

    // Thresholds mirror the app convention: replace at 2/32", warn at 4/32".
    var redThreshold: Double {
        switch self {
        case .thirtySeconds: return 2.0
        case .inches:        return 2.0 / 32
        case .mm:            return 2.0 * 25.4 / 32
        }
    }

    var orangeThreshold: Double {
        switch self {
        case .thirtySeconds: return 4.0
        case .inches:        return 4.0 / 32
        case .mm:            return 4.0 * 25.4 / 32
        }
    }

    func format(_ value: Double) -> String {
        switch self {
        case .thirtySeconds: return String(format: "%.1f", value)
        case .inches:        return String(format: "%.3f", value)
        case .mm:            return String(format: "%.2f", value)
        }
    }
}

// Rapid keyboard / Bluetooth-gauge entry: all 4 tires visible at once.
// Tab advances through every field in reading order; the system handles
// within-row and cross-row navigation automatically.
struct BluetoothEntryView: View {
    let car: Car
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @AppStorage("treadPointCount") private var pointCount = 3
    // values[tireIndex][pointIndex], up to 5 points
    @State private var values: [[String]] = Array(repeating: Array(repeating: "", count: 5), count: 4)
    @FocusState private var focusedField: FieldID?

    @AppStorage("treadInputUnit") private var unitRaw: String = TreadUnit.thirtySeconds.rawValue
    private var unit: TreadUnit { TreadUnit(rawValue: unitRaw) ?? .thirtySeconds }

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

            Spacer()

            Picker("Unit", selection: $unitRaw) {
                ForEach(TreadUnit.allCases, id: \.rawValue) { u in
                    Text(u.rawValue).tag(u.rawValue)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 140)
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

            VStack(spacing: 1) {
                Text("Avg")
                Text(unit.rawValue)
            }
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

            Group {
                if let avg {
                    Text(unit.format(avg))
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(thresholdColor(avg))
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
            let rawReadings = values[i].prefix(pointCount).compactMap { Double($0) }
            guard !rawReadings.isEmpty else { continue }
            // Convert from the selected input unit to 32nds of an inch for storage
            let readings = rawReadings.map { unit.toThirtySeconds($0) }
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
                ? (0..<rawReadings.count).map {
                    "\(pointLabel($0, total: pointCount)): \(unit.format(rawReadings[$0])) \(unit.rawValue)"
                }.joined(separator: ", ")
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
        return thresholdColor(d)
    }

    private func thresholdColor(_ value: Double) -> Color {
        if value <= unit.redThreshold { return .red }
        if value <= unit.orangeThreshold { return .orange }
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
