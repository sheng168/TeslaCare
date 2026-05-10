//
//  CarDetailView.swift
//  TeslaCare
//
//  Created by Jin on 5/7/26.
//

import SwiftUI
import SwiftData
import Charts

struct CarDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let car: Car
    
    @State private var showingAddMeasurement = false
    @State private var showingRotateTires = false
    @State private var showingReplaceTires = false
    @State private var showingLogAirFilter = false
    @State private var selectedPosition: TirePosition?
    
    var sortedMeasurements: [TireMeasurement] {
        (car.measurements ?? []).sorted { $0.date > $1.date }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                carHeaderSection

                if car.latestTPMSReading != nil {
                    TPMSSummaryView(car: car)
                        .padding(.horizontal)
                    TPMSHistoryChartView(car: car)
                        .padding(.horizontal)
                }

                TireGridView(car: car, selectedPosition: $selectedPosition)
                    .padding(.horizontal)

                actionButtons
                rotationHistorySection
                replacementHistorySection
                airFilterHistorySection
                measurementHistorySection
            }
            .padding(.vertical)
        }
        .navigationTitle("Tire Tracking")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingAddMeasurement = true }) {
                    Label("Add Measurement", systemImage: "plus")
                }
            }
            
            ToolbarItem(placement: .secondaryAction) {
                Button(action: { showingLogAirFilter = true }) {
                    Label("Log Air Filter", systemImage: "air.purifier.fill")
                }
            }
        }
        .sheet(isPresented: $showingAddMeasurement) {
            AddMeasurementView(car: car, preselectedPosition: selectedPosition)
        }
        .sheet(isPresented: $showingRotateTires) {
            RotateTiresView(car: car)
        }
        .sheet(isPresented: $showingReplaceTires) {
            ReplaceTiresView(car: car)
        }
        .sheet(isPresented: $showingLogAirFilter) {
            LogAirFilterChangeView(car: car)
        }
        .onChange(of: selectedPosition) { _, newValue in
            if newValue != nil {
                showingAddMeasurement = true
            }
        }
        .onChange(of: showingAddMeasurement) { _, newValue in
            if !newValue {
                selectedPosition = nil
            }
        }
    }
    
    // MARK: - Sections

    @ViewBuilder
    private var carHeaderSection: some View {
        VStack(spacing: 8) {
            Text(car.displayName)
                .font(.title2)
                .fontWeight(.bold)

            Text("\(car.year, format: .number.grouping(.never)) \(car.make) \(car.model)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let mileage = car.mileage {
                Text("\(mileage.formatted()) mi")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if let health = car.tireHealthPercentage {
                tireHealthCard(health)
            }
        }
        .padding()
    }

    @ViewBuilder
    private func tireHealthCard(_ health: Double) -> some View {
        VStack(spacing: 8) {
            Text("Overall Tire Health")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                ProgressView(value: health, total: 100)
                    .tint(healthColor(for: health))
                    .frame(maxWidth: 200)

                Text("\(Int(health))%")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(healthColor(for: health))
            }

            if let avg = car.averageTreadDepth {
                Text(String(format: "Average: %.1f/32\"", avg))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 5)
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            actionButton("Rotate", icon: "arrow.triangle.2.circlepath", color: .blue) {
                showingRotateTires = true
            }
            actionButton("Replace", icon: "plus.circle.fill", color: .green) {
                showingReplaceTires = true
            }
        }
        .padding(.horizontal)
    }

    private func actionButton(_ title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.subheadline)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(color)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    @ViewBuilder
    private var rotationHistorySection: some View {
        if let rotations = car.rotationEvents?.sorted(by: { $0.date > $1.date }), !rotations.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Rotation History")
                    .font(.headline)
                    .padding(.horizontal)
                ForEach(rotations) { rotation in
                    RotationEventRow(rotation: rotation)
                }
                .padding(.horizontal)
            }
            .padding(.top)
        }
    }

    @ViewBuilder
    private var replacementHistorySection: some View {
        if let replacements = car.replacementEvents?.sorted(by: { $0.date > $1.date }), !replacements.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Replacement History")
                    .font(.headline)
                    .padding(.horizontal)
                ForEach(replacements) { replacement in
                    ReplacementEventRow(replacement: replacement)
                }
                .padding(.horizontal)
            }
            .padding(.top)
        }
    }

    @ViewBuilder
    private var airFilterHistorySection: some View {
        if let airFilters = car.airFilterChanges?.sorted(by: { $0.date > $1.date }), !airFilters.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Air Filter Changes")
                    .font(.headline)
                    .padding(.horizontal)
                ForEach(airFilters) { filterChange in
                    AirFilterChangeRow(filterChange: filterChange)
                }
                .padding(.horizontal)
            }
            .padding(.top)
        }
    }

    @ViewBuilder
    private var measurementHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Measurement History")
                .font(.headline)
                .padding(.horizontal)

            if sortedMeasurements.isEmpty {
                ContentUnavailableView(
                    "No Measurements",
                    systemImage: "gauge.with.dots.needle.0percent",
                    description: Text("Add tire measurements to track tread depth over time")
                )
                .frame(height: 200)
            } else {
                ForEach(sortedMeasurements) { measurement in
                    MeasurementRowView(measurement: measurement)
                }
                .padding(.horizontal)
            }
        }
        .padding(.top)
    }

    // MARK: - Helpers

    private func healthColor(for percentage: Double) -> Color {
        switch percentage {
        case 50...100: return .green
        case 25..<50: return .orange
        default: return .red
        }
    }
}

// MARK: - TPMS Summary
struct TPMSSummaryView: View {
    let car: Car

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Tire Pressure", systemImage: "gauge.with.needle")
                    .font(.headline)
                Spacer()
                if let updated = car.tpmsUpdatedAt {
                    Text(updated, style: .relative)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 0) {
                let r = car.latestTPMSReading
                pressureCell("Front Left",  bar: r?.frontLeft)
                Divider()
                pressureCell("Front Right", bar: r?.frontRight)
                Divider()
                pressureCell("Rear Left",   bar: r?.rearLeft)
                Divider()
                pressureCell("Rear Right",  bar: r?.rearRight)
            }
            .fixedSize(horizontal: false, vertical: true)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.08), radius: 4)
    }

    @ViewBuilder
    private func pressureCell(_ label: String, bar: Double?) -> some View {
        let psi = bar.map { $0 * 14.504 }
        let color: Color = {
            guard let psi else { return .secondary }
            if psi < 28 { return .red }
            if psi < 36 { return .orange }
            return .primary
        }()
        VStack(spacing: 4) {
            Text(psi.map { String(format: "%.0f", $0) } ?? "--")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(color)
            Text("PSI")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
    }
}

// MARK: - TPMS History Chart

struct TPMSHistoryChartView: View {
    let car: Car

    private struct DataPoint: Identifiable {
        let id = UUID()
        let date: Date
        let psi: Double
        let label: String
    }

    private var dataPoints: [DataPoint] {
        let readings = (car.tpmsReadings ?? []).sorted { $0.date < $1.date }
        return readings.flatMap { reading in
            TirePosition.allCases.compactMap { position in
                guard let bar = reading.pressure(for: position) else { return nil }
                return DataPoint(date: reading.date, psi: bar * 14.504, label: position.abbreviation)
            }
        }
    }

    private var yDomain: ClosedRange<Double> {
        let values = dataPoints.map(\.psi)
        let lo = (values.min() ?? 30) - 3
        let hi = (values.max() ?? 50) + 3
        return lo...hi
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Pressure History")
                .font(.headline)

            if dataPoints.isEmpty {
                Text("Sync your Tesla to build pressure history")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 80)
                    .multilineTextAlignment(.center)
            } else {
                Chart(dataPoints) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("PSI", point.psi)
                    )
                    .foregroundStyle(by: .value("Tire", point.label))
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Date", point.date),
                        y: .value("PSI", point.psi)
                    )
                    .foregroundStyle(by: .value("Tire", point.label))
                    .symbolSize(25)
                }
                .chartYScale(domain: yDomain)
                .chartYAxis {
                    AxisMarks(values: .stride(by: 5)) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let psi = value.as(Double.self) {
                                Text("\(Int(psi))")
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    }
                }
                .chartLegend(position: .bottom, alignment: .leading)
                .frame(height: 200)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.08), radius: 4)
    }
}

// MARK: - Measurement Row View
struct MeasurementRowView: View {
    let measurement: TireMeasurement
    
    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: measurement.position.systemImage)
                .font(.title3)
                .foregroundStyle(.secondary)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(measurement.position.rawValue)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    if measurement.isDanger {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                            .font(.caption)
                    } else if measurement.isWarning {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundStyle(.orange)
                            .font(.caption)
                    }
                }
                
                Text(measurement.date, format: .dateTime.month().day().year())
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                // Show detailed measurements if available
                if measurement.hasMultiplePoints,
                   let inner = measurement.innerTreadDepth,
                   let center = measurement.centerTreadDepth,
                   let outer = measurement.outerTreadDepth {
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Divider()
                            .padding(.vertical, 2)
                        
                        Text("Detailed Measurements")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                        
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 1) {
                                Text("Inner")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Text(String(format: "%.1f/32\"", inner))
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundStyle(treadColorForValue(inner))
                            }
                            
                            VStack(alignment: .leading, spacing: 1) {
                                Text("Center")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Text(String(format: "%.1f/32\"", center))
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundStyle(treadColorForValue(center))
                            }
                            
                            VStack(alignment: .leading, spacing: 1) {
                                Text("Outer")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Text(String(format: "%.1f/32\"", outer))
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundStyle(treadColorForValue(outer))
                            }
                        }
                        
                        // Show wear pattern description
                        if let wearPattern = measurement.wearPatternDescription {
                            HStack(spacing: 4) {
                                if measurement.hasUnevenWear {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundStyle(.orange)
                                        .font(.caption2)
                                }
                                Text(wearPattern)
                                    .font(.caption2)
                                    .foregroundStyle(measurement.hasUnevenWear ? .orange : .secondary)
                            }
                            .padding(.top, 2)
                        }
                    }
                }
                
                if !measurement.notes.isEmpty {
                    Text(measurement.notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .padding(.top, 2)
                }
                
                if let mileage = measurement.mileage {
                    Text("\(mileage.formatted()) miles")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(measurement.treadDepthFormatted)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(treadColor(for: measurement))
                
                if measurement.hasMultiplePoints {
                    Text("avg")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func treadColor(for measurement: TireMeasurement) -> Color {
        if measurement.isDanger {
            return .red
        } else if measurement.isWarning {
            return .orange
        } else {
            return .green
        }
    }
    
    private func treadColorForValue(_ value: Double) -> Color {
        if value <= 2.0 {
            return .red
        } else if value <= 4.0 {
            return .orange
        } else {
            return .green
        }
    }
}

// MARK: - Rotation Event Row
struct RotationEventRow: View {
    let rotation: TireRotationEvent
    
    var body: some View {
        HStack {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(rotation.pattern.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(rotation.date, format: .dateTime.month().day().year())
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if !rotation.notes.isEmpty {
                    Text(rotation.notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                
                if let mileage = rotation.mileage {
                    Text("\(mileage.formatted()) miles")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: rotation.pattern.systemImage)
                .font(.title2)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Replacement Event Row
struct ReplacementEventRow: View {
    let replacement: TireReplacementEvent
    
    var body: some View {
        HStack {
            Image(systemName: "plus.circle.fill")
                .font(.title3)
                .foregroundStyle(.green)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(replacement.replacementDescription)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if !replacement.brand.isEmpty || !replacement.modelName.isEmpty {
                    Text("\(replacement.brand) \(replacement.modelName)".trimmingCharacters(in: .whitespaces))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Text(replacement.date, format: .dateTime.month().day().year())
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 8) {
                    if let mileage = replacement.mileage {
                        Text("\(mileage.formatted()) miles")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    
                    if let cost = replacement.cost {
                        Text("$\(cost, format: .number.precision(.fractionLength(2)))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                
                if !replacement.notes.isEmpty {
                    Text(replacement.notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            VStack(spacing: 2) {
                ForEach(replacement.replacedPositions.prefix(2), id: \.self) { position in
                    Image(systemName: position.systemImage)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                if replacement.replacedCount > 2 {
                    Text("+\(replacement.replacedCount - 2)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Air Filter Change Row
struct AirFilterChangeRow: View {
    let filterChange: AirFilterChangeEvent
    
    var body: some View {
        HStack {
            Image(systemName: filterChange.filterType.systemImage)
                .font(.title3)
                .foregroundStyle(.purple)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(filterChange.filterType.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if !filterChange.brand.isEmpty {
                    Text(filterChange.brand)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Text(filterChange.date, format: .dateTime.month().day().year())
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 8) {
                    if let mileage = filterChange.mileage {
                        Text("\(mileage.formatted()) miles")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    
                    if let cost = filterChange.cost {
                        Text("$\(cost, format: .number.precision(.fractionLength(2)))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                
                if !filterChange.partNumber.isEmpty {
                    Text("Part #: \(filterChange.partNumber)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                if !filterChange.notes.isEmpty {
                    Text(filterChange.notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview("TPMS History Chart — With Data") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Car.self, TPMSReading.self, configurations: config)

    let car = Car(name: "My Tesla", make: "Tesla", model: "Model 3", year: 2023)
    container.mainContext.insert(car)

    // Simulate 6 syncs over 6 weeks with realistic pressure variation (values in bar)
    let syncDates: [TimeInterval] = [-42, -35, -28, -21, -14, -7, 0].map { $0 * 86400 }
    let flPsi: [Double] = [42, 41, 40, 38, 39, 41, 42]
    let frPsi: [Double] = [42, 41, 41, 39, 40, 41, 42]
    let rlPsi: [Double] = [40, 40, 39, 37, 38, 39, 40]
    let rrPsi: [Double] = [40, 39, 38, 36, 37, 39, 40]

    for i in syncDates.indices {
        let reading = TPMSReading(
            date: Date(timeIntervalSinceNow: syncDates[i]),
            frontLeft:  flPsi[i] / 14.504,
            frontRight: frPsi[i] / 14.504,
            rearLeft:   rlPsi[i] / 14.504,
            rearRight:  rrPsi[i] / 14.504
        )
        reading.car = car
        container.mainContext.insert(reading)
    }

    return TPMSHistoryChartView(car: car)
        .padding()
        .modelContainer(container)
}

#Preview("TPMS History Chart — Empty") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Car.self, TPMSReading.self, configurations: config)
    let car = Car(name: "New Car", make: "Tesla", model: "Model Y", year: 2024)
    container.mainContext.insert(car)
    return TPMSHistoryChartView(car: car)
        .padding()
        .modelContainer(container)
}

#Preview {
    NavigationStack {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: Car.self, TireMeasurement.self, Tire.self, TireRotationEvent.self, TireReplacementEvent.self, AirFilterChangeEvent.self, TPMSReading.self, MileageReading.self, configurations: config)
        
        let car = Car(name: "My Tesla", make: "Tesla", model: "Model 3", year: 2023)
        container.mainContext.insert(car)
        
        // Create tires
        let tire1 = Tire(brand: "Michelin", modelName: "Pilot Sport", size: "235/45R18", currentPosition: .frontLeft)
        tire1.car = car
        container.mainContext.insert(tire1)
        
        let tire2 = Tire(brand: "Michelin", modelName: "Pilot Sport", size: "235/45R18", currentPosition: .frontRight)
        tire2.car = car
        container.mainContext.insert(tire2)
        
        // Create measurements with required tire parameter
        let measurement1 = TireMeasurement(date: Date(), treadDepth: 7.5, position: .frontLeft, tire: tire1, notes: "", mileage: nil)
        measurement1.car = car
        container.mainContext.insert(measurement1)
        
        let measurement2 = TireMeasurement(date: Date().addingTimeInterval(-86400), treadDepth: 3.2, position: .frontRight, tire: tire2, notes: "", mileage: nil)
        measurement2.car = car
        container.mainContext.insert(measurement2)
        
        return CarDetailView(car: car)
            .modelContainer(container)
    }
}
