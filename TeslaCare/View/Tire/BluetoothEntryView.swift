//
//  BluetoothEntryView.swift
//  TeslaCare
//

import SwiftUI
import SwiftData

// Rapid keyboard/Bluetooth-gauge entry: cycles all 4 tires,
// auto-advancing focus on Return after each reading.
struct BluetoothEntryView: View {
    let car: Car
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var pointCount = 3
    @State private var currentTire = 0
    // values[tireIndex][pointIndex], up to 5 points
    @State private var values: [[String]] = Array(repeating: Array(repeating: "", count: 5), count: 4)
    @State private var showSummary = false
    @FocusState private var focusedPoint: Int?

    private let positions = TirePosition.allCases

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                settingsBar
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                    .background(.bar)

                if showSummary {
                    summaryView
                } else {
                    entryView
                        .id(currentTire)
                }
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
            .onChange(of: pointCount) { _, _ in resetSession() }

            Spacer()

            if !showSummary {
                HStack(spacing: 4) {
                    ForEach(0..<4, id: \.self) { i in
                        Circle()
                            .fill(i == currentTire ? Color.blue : Color(.tertiarySystemFill))
                            .frame(width: 7, height: 7)
                    }
                }
            }
        }
    }

    // MARK: - Entry View (one tire at a time)

    private var entryView: some View {
        VStack(spacing: 28) {
            Spacer(minLength: 0)

            carSchematic

            VStack(spacing: 6) {
                Text(positions[currentTire].rawValue)
                    .font(.system(.title, weight: .bold))

                if let prev = car.latestMeasurement(for: positions[currentTire]) {
                    Text("Previous: \(String(format: "%.1f/32\"", prev.treadDepth))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            // Input fields
            HStack(spacing: 10) {
                ForEach(0..<pointCount, id: \.self) { point in
                    VStack(spacing: 6) {
                        TextField("—", text: $values[currentTire][point])
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.center)
                            .font(.system(.title2, design: .rounded, weight: .semibold))
                            .foregroundStyle(fieldColor(values[currentTire][point]))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(focusedPoint == point
                                          ? Color.blue.opacity(0.1)
                                          : Color(.secondarySystemBackground))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(focusedPoint == point ? Color.blue : Color.clear, lineWidth: 2)
                            )
                            .focused($focusedPoint, equals: point)
                            .onSubmit { advance(from: point) }

                        Text(pointLabel(point, total: pointCount))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 24)

            // Back / Skip navigation
            HStack {
                Button {
                    withAnimation(.spring(duration: 0.3)) { currentTire -= 1 }
                } label: {
                    Label("Back", systemImage: "chevron.left")
                        .font(.subheadline)
                }
                .disabled(currentTire == 0)
                .foregroundStyle(currentTire == 0 ? Color.secondary : Color.blue)

                Spacer()

                Button {
                    advance(from: pointCount - 1)
                } label: {
                    Label(currentTire < 3 ? "Skip" : "Done",
                          systemImage: currentTire < 3 ? "chevron.right" : "checkmark")
                        .labelStyle(.titleAndIcon)
                        .font(.subheadline)
                }
                .foregroundStyle(.blue)
            }
            .padding(.horizontal, 32)

            Spacer(minLength: 0)
        }
        .onAppear { focusedPoint = 0 }
    }

    // MARK: - Car Schematic (mini 2×2 grid)

    private var carSchematic: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                schematicCell(.frontLeft)
                schematicCell(.frontRight)
            }
            HStack(spacing: 4) {
                schematicCell(.rearLeft)
                schematicCell(.rearRight)
            }
        }
    }

    private func schematicCell(_ pos: TirePosition) -> some View {
        let isCurrent = positions[currentTire] == pos
        let hasValues = values[positions.firstIndex(of: pos)!].prefix(pointCount).contains { !$0.isEmpty }
        return Text(pos.abbreviation)
            .font(.caption2.weight(isCurrent ? .bold : .regular))
            .foregroundStyle(isCurrent ? .white : (hasValues ? .green : .secondary))
            .frame(width: 36, height: 22)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(isCurrent ? Color.blue : (hasValues ? Color.green.opacity(0.15) : Color(.tertiarySystemFill)))
            )
    }

    // MARK: - Summary View

    private var summaryView: some View {
        List {
            Section {
                ForEach(positions.indices, id: \.self) { i in
                    let readings = pointReadings(tire: i)
                    let avg = readings.isEmpty ? nil : readings.reduce(0, +) / Double(readings.count)

                    HStack(spacing: 12) {
                        Text(positions[i].abbreviation)
                            .font(.subheadline.weight(.semibold))
                            .frame(width: 28)

                        Text(positions[i].rawValue)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Spacer()

                        if readings.isEmpty {
                            Text("Skipped")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        } else {
                            HStack(spacing: 6) {
                                if readings.count > 1 {
                                    Text(readings.map { String(format: "%.1f", $0) }.joined(separator: " · "))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text("→")
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }
                                if let avg {
                                    Text(String(format: "%.1f/32\"", avg))
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(depthColor(avg))
                                }
                            }
                        }
                    }
                }
            } header: {
                Text("Review")
            }

            Section {
                Button(action: saveMeasurements) {
                    Label("Save All Measurements", systemImage: "checkmark.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .tint(.blue)

                Button("Go Back & Edit") {
                    withAnimation { showSummary = false; currentTire = 3 }
                }
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Logic

    private func advance(from point: Int) {
        let next = point + 1
        if next < pointCount {
            focusedPoint = next
        } else if currentTire < 3 {
            withAnimation(.spring(duration: 0.3)) { currentTire += 1 }
        } else {
            focusedPoint = nil
            withAnimation { showSummary = true }
        }
    }

    private func resetSession() {
        values = Array(repeating: Array(repeating: "", count: 5), count: 4)
        currentTire = 0
        showSummary = false
    }

    private func pointReadings(tire: Int) -> [Double] {
        values[tire].prefix(pointCount).compactMap { Double($0) }
    }

    private func saveMeasurements() {
        let date = Date()
        for (i, position) in positions.enumerated() {
            let readings = pointReadings(tire: i)
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

            // Map to inner/center/outer for 3-point measurements
            let inner:  Double? = pointCount >= 2 ? readings.first : nil
            let center: Double? = pointCount == 3 ? readings[1] : (pointCount == 5 ? readings[2] : nil)
            let outer:  Double? = pointCount >= 2 ? readings.last : nil

            let notes: String = pointCount > 1
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

    private func fieldColor(_ text: String) -> Color {
        guard let d = Double(text) else { return .primary }
        return depthColor(d)
    }

    private func depthColor(_ depth: Double) -> Color {
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
