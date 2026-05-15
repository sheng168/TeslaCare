//
//  TireDetailView.swift
//  TeslaCare
//
//  Created by Jin on 5/8/26.
//

import SwiftUI
import SwiftData
import Charts
import OSLog

private let logger = AppLogger(subsystem: "com.teslacare", category: "TireDetail")

struct TireDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let tire: Tire
    
    @State private var showingAddMeasurement = false
    @State private var showingEditTire = false
    
    var sortedMeasurements: [TireMeasurement] {
        (tire.measurements ?? []).sorted { $0.date > $1.date }
    }

    private struct PressurePoint: Identifiable {
        let id = UUID()
        let date: Date
        let psi: Double
        let outsideTemperatureC: Double?
    }

    private var tpmsDataPoints: [PressurePoint] {
        (tire.car?.tpmsReadings ?? [])
            .sorted { $0.date < $1.date }
            .compactMap { reading in
                guard let bar = reading.pressure(for: tire.position) else { return nil }
                return PressurePoint(date: reading.date, psi: bar * 14.504, outsideTemperatureC: reading.outsideTemperature)
            }
    }

    private var currentPSI: Double? {
        tire.car?.latestTPMSReading?.pressure(for: tire.position).map { $0 * 14.504 }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header Card
                tireHeaderCard
                
                // Status and Alerts
                if tire.needsReplacement {
                    replacementAlert
                }
                
                // Key Metrics
                metricsGrid
                
                // Tread Depth Chart
                if sortedMeasurements.count > 1 {
                    treadDepthChart
                }
                
                // TPMS Pressure Chart
                if !tpmsDataPoints.isEmpty {
                    tpmsPressureChart
                }
                
                // Latest Measurement
                if let latest = tire.latestMeasurement {
                    latestMeasurementCard(latest)
                }
                
                // Tire Information
                tireInfoSection
                
                // Measurement History
                if !sortedMeasurements.isEmpty {
                    measurementHistorySection
                }
            }
            .padding()
        }
        .navigationTitle(tire.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        showingAddMeasurement = true
                    } label: {
                        Label("Add Measurement", systemImage: "ruler")
                    }
                    
                    Button {
                        showingEditTire = true
                    } label: {
                        Label("Edit Tire Info", systemImage: "pencil")
                    }
                    
                    Divider()
                    
                    Button(role: .destructive) {
                        deleteTire()
                    } label: {
                        Label("Delete Tire", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingAddMeasurement) {
            if let car = tire.car {
                AddMeasurementView(car: car, preselectedPosition: tire.position)
            }
        }
        .sheet(isPresented: $showingEditTire) {
            EditTireView(tire: tire)
        }
    }
    
    // MARK: - Header Card
    
    private var tireHeaderCard: some View {
        VStack(spacing: 12) {
            // Position Badge
            HStack {
                Label(tire.position.rawValue, systemImage: tire.position.systemImage)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue)
                    .clipShape(Capsule())
                
                Spacer()
                
                if let car = tire.car {
                    NavigationLink {
                        CarDetailView(car: car)
                    } label: {
                        Label(car.displayName, systemImage: "car.fill")
                            .font(.caption)
                    }
                }
            }
            
            // Brand and Model
            VStack(spacing: 4) {
                Text("\(tire.brand) \(tire.modelName)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(tire.size)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            // Current Status
            if let remaining = tire.remainingLifePercentage {
                VStack(spacing: 8) {
                    Text("Remaining Life")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    ProgressView(value: remaining, total: 100)
                        .tint(lifeColor(for: remaining))
                    
                    Text("\(Int(remaining))%")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(lifeColor(for: remaining))
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Replacement Alert
    
    private var replacementAlert: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title2)
                .foregroundStyle(.red)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Replacement Needed")
                    .font(.headline)
                    .foregroundStyle(.red)
                
                Text("This tire has reached the minimum safe tread depth")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Metrics Grid
    
    private var metricsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            MetricCard(
                title: "Current Tread",
                value: tire.latestMeasurement?.treadDepthFormatted ?? "N/A",
                icon: "ruler",
                color: tire.latestMeasurement.map { treadColor(for: $0) } ?? .gray
            )
            
            MetricCard(
                title: "Wear",
                value: tire.wearPercentage.map { "\(Int($0))%" } ?? "N/A",
                icon: "chart.line.downtrend.xyaxis",
                color: .orange
            )
            
            MetricCard(
                title: "Age",
                value: "\(tire.ageInMonths) mo",
                icon: "calendar",
                color: .blue
            )
            
            MetricCard(
                title: "Measurements",
                value: "\(sortedMeasurements.count)",
                icon: "list.number",
                color: .purple
            )
        }
    }
    
    // MARK: - Tread Depth Chart
    
    private var treadDepthChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tread Depth History")
                .font(.headline)
            
            Chart {
                ForEach(sortedMeasurements.reversed()) { measurement in
                    LineMark(
                        x: .value("Date", measurement.date),
                        y: .value("Depth", measurement.treadDepth)
                    )
                    .foregroundStyle(Color.blue)
                    .interpolationMethod(.catmullRom)
                    
                    PointMark(
                        x: .value("Date", measurement.date),
                        y: .value("Depth", measurement.treadDepth)
                    )
                    .foregroundStyle(Color.blue)
                }
                
                // Warning threshold
                RuleMark(y: .value("Warning", 4.0))
                    .foregroundStyle(.orange.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                
                // Danger threshold
                RuleMark(y: .value("Danger", 2.0))
                    .foregroundStyle(.red.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
            }
            .frame(height: 200)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let depth = value.as(Double.self) {
                            Text("\(Int(depth))/32\"")
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel(format: .dateTime.month().day())
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - TPMS Pressure Chart

    private var tpmsYDomain: ClosedRange<Double> {
        let values = tpmsDataPoints.map(\.psi)
        let minVal = (values.min() ?? 30) - 5
        let maxVal = (values.max() ?? 45) + 5
        return minVal...maxVal
    }

    @ViewBuilder private var tpmsPressureChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Pressure History")
                    .font(.headline)
                Spacer()
                if let psi = currentPSI {
                    Text(String(format: "%.1f psi", psi))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(psiColor(for: psi))
                }
            }

            Chart {
                ForEach(tpmsDataPoints) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("PSI", point.psi)
                    )
                    .foregroundStyle(Color.blue)
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Date", point.date),
                        y: .value("PSI", point.psi)
                    )
                    .foregroundStyle(psiColor(for: point.psi))
                    .symbolSize(50)
                }
            }
            .frame(height: 200)
            .chartYScale(domain: tpmsYDomain)
            .chartYAxis {
                AxisMarks(position: .leading, values: .stride(by: 5)) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let psi = value.as(Double.self) {
                            Text(String(format: "%.0f", psi))
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                    AxisValueLabel(format: .dateTime.month().day())
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Latest Measurement Card
    
    private func latestMeasurementCard(_ measurement: TireMeasurement) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Latest Measurement")
                    .font(.headline)
                
                Spacer()
                
                Text(measurement.date, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Divider()
            
            VStack(spacing: 8) {
                HStack {
                    Text("Tread Depth:")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(measurement.treadDepthFormatted)
                        .fontWeight(.semibold)
                        .foregroundStyle(treadColor(for: measurement))
                }
                
                if let mileage = measurement.mileage {
                    HStack {
                        Text("Mileage:")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(mileage, format: .number) mi")
                            .fontWeight(.medium)
                    }
                }
                
                if !measurement.notes.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Notes:")
                            .foregroundStyle(.secondary)
                        Text(measurement.notes)
                            .font(.body)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Tire Information Section
    
    private var tireInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tire Information")
                .font(.headline)
            
            Divider()
            
            VStack(spacing: 12) {
                InfoRow(label: "Brand", value: tire.brand)
                InfoRow(label: "Model", value: tire.modelName)
                InfoRow(label: "Size", value: tire.size)
                InfoRow(label: "DOT Number", value: tire.dotNumber)
                InfoRow(label: "Purchase Date", value: tire.purchaseDate.formatted(date: .abbreviated, time: .omitted))
                InfoRow(label: "Install Date", value: tire.installDate.formatted(date: .abbreviated, time: .omitted))
                InfoRow(label: "Initial Tread", value: String(format: "%.1f/32\"", tire.initialTreadDepth))
                
                if let price = tire.purchasePrice {
                    InfoRow(label: "Purchase Price", value: price.formatted(.currency(code: "USD")))
                }
                
                if let mileage = tire.mileageAtInstall {
                    InfoRow(label: "Mileage at Install", value: "\(mileage.formatted(.number)) mi")
                }
                
                if !tire.notes.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Notes:")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(tire.notes)
                            .font(.body)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Measurement History Section
    
    private var measurementHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Measurement History")
                .font(.headline)
            
            Divider()
            
            ForEach(sortedMeasurements) { measurement in
                MeasurementHistoryRow(measurement: measurement)
                
                if measurement.id != sortedMeasurements.last?.id {
                    Divider()
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Helper Functions
    
    private func treadColor(for measurement: TireMeasurement) -> Color {
        if measurement.isDanger {
            return .red
        } else if measurement.isWarning {
            return .orange
        } else {
            return .green
        }
    }
    
    private func psiColor(for psi: Double) -> Color {
        switch psi {
        case ..<28: return .red
        case 28..<34: return .orange
        case 34..<48: return .green
        default: return .orange
        }
    }

    private func lifeColor(for percentage: Double) -> Color {
        switch percentage {
        case 50...100: return .green
        case 25..<50: return .orange
        default: return .red
        }
    }
    
    private func deleteTire() {
        logger.info("Deleting tire: \(tire.displayName)")
        modelContext.delete(tire)
    }
}

// MARK: - Supporting Views

struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

struct MeasurementHistoryRow: View {
    let measurement: TireMeasurement
    
    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(measurement.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if let mileage = measurement.mileage {
                    Text("\(mileage, format: .number) mi")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(measurement.treadDepthFormatted)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(treadColor(for: measurement))
                
                if measurement.isDanger {
                    Label("Danger", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption2)
                        .foregroundStyle(.red)
                } else if measurement.isWarning {
                    Label("Warning", systemImage: "exclamationmark.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            }
        }
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
}

// MARK: - Edit Tire View (Placeholder)

struct EditTireView: View {
    @Environment(\.dismiss) private var dismiss
    let tire: Tire
    
    @State private var brand: String
    @State private var modelName: String
    @State private var size: String
    @State private var dotNumber: String
    @State private var notes: String
    
    init(tire: Tire) {
        self.tire = tire
        _brand = State(initialValue: tire.brand)
        _modelName = State(initialValue: tire.modelName)
        _size = State(initialValue: tire.size)
        _dotNumber = State(initialValue: tire.dotNumber)
        _notes = State(initialValue: tire.notes)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Tire Details") {
                    TextField("Brand", text: $brand)
                    TextField("Model", text: $modelName)
                    TextField("Size", text: $size)
                    TextField("DOT Number", text: $dotNumber)
                }
                
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Edit Tire")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveTire()
                        dismiss()
                    }
                    .disabled(brand.isEmpty || modelName.isEmpty || size.isEmpty)
                }
            }
        }
    }
    
    private func saveTire() {
        logger.info("Saving tire edits: \(brand) \(modelName) \(size)")
        tire.brand = brand
        tire.modelName = modelName
        tire.size = size
        tire.dotNumber = dotNumber
        tire.notes = notes
    }
}

// MARK: - Previews

#Preview("Tire Detail - Good Condition") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Tire.self, TireMeasurement.self, Car.self, TPMSReading.self, MileageReading.self, configurations: config)

    let car = Car(name: "My Tesla", make: "Tesla", model: "Model 3", year: 2023)
    container.mainContext.insert(car)

    let tire = Tire(
        brand: "Michelin",
        modelName: "Pilot Sport 4S",
        size: "235/45R18",
        dotNumber: "DOT1234AB5678",
        purchaseDate: Date().addingTimeInterval(-180 * 24 * 60 * 60),
        installDate: Date().addingTimeInterval(-150 * 24 * 60 * 60),
        initialTreadDepth: 10.0,
        purchasePrice: 250.0,
        currentPosition: .frontLeft,
        mileageAtInstall: 25000,
        notes: "High performance summer tire"
    )
    tire.car = car
    container.mainContext.insert(tire)

    // Tread depth measurements
    let dates = [
        Date().addingTimeInterval(-150 * 24 * 60 * 60),
        Date().addingTimeInterval(-120 * 24 * 60 * 60),
        Date().addingTimeInterval(-90 * 24 * 60 * 60),
        Date().addingTimeInterval(-60 * 24 * 60 * 60),
        Date().addingTimeInterval(-30 * 24 * 60 * 60),
        Date()
    ]
    let depths = [10.0, 9.5, 9.0, 8.7, 8.5, 8.2]
    let mileages = [25000, 26500, 28000, 29500, 31000, 32500]

    for (index, date) in dates.enumerated() {
        let measurement = TireMeasurement(
            date: date,
            treadDepth: depths[index],
            position: .frontLeft,
            tire: tire,
            notes: index == dates.count - 1 ? "Regular check" : "",
            mileage: mileages[index]
        )
        container.mainContext.insert(measurement)
    }

    // TPMS readings — front-left PSI around 42–44 with a dip mid-winter
    let tpmsDates = [
        Date().addingTimeInterval(-140 * 24 * 60 * 60),
        Date().addingTimeInterval(-110 * 24 * 60 * 60),
        Date().addingTimeInterval(-80 * 24 * 60 * 60),
        Date().addingTimeInterval(-50 * 24 * 60 * 60),
        Date().addingTimeInterval(-20 * 24 * 60 * 60),
        Date()
    ]
    let flPsi: [Double] = [42.5, 40.8, 38.2, 41.0, 43.1, 43.8]
    let outsideTemps: [Double] = [18.0, 8.0, -3.0, 5.0, 14.0, 21.0]

    for (i, date) in tpmsDates.enumerated() {
        let reading = TPMSReading(
            date: date,
            frontLeft: flPsi[i] / 14.504,
            frontRight: (flPsi[i] + 0.3) / 14.504,
            rearLeft: (flPsi[i] - 1.0) / 14.504,
            rearRight: (flPsi[i] - 0.8) / 14.504,
            outsideTemperature: outsideTemps[i]
        )
        reading.car = car
        container.mainContext.insert(reading)
    }

    return NavigationStack {
        TireDetailView(tire: tire)
    }
    .modelContainer(container)
}

#Preview("Tire Detail - Needs Replacement") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Tire.self, TireMeasurement.self, Car.self, TPMSReading.self, MileageReading.self, configurations: config)
    
    let car = Car(name: "Work Truck", make: "Ford", model: "F-150", year: 2020)
    container.mainContext.insert(car)
    
    let tire = Tire(
        brand: "Bridgestone",
        modelName: "Turanza",
        size: "225/50R17",
        dotNumber: "DOT9012CD3456",
        purchaseDate: Date().addingTimeInterval(-1095 * 24 * 60 * 60),
        installDate: Date().addingTimeInterval(-1065 * 24 * 60 * 60),
        initialTreadDepth: 10.0,
        purchasePrice: 180.0,
        currentPosition: .rearLeft,
        mileageAtInstall: 10000,
        notes: "Showing signs of uneven wear on inner edge"
    )
    tire.car = car
    container.mainContext.insert(tire)
    
    let measurement = TireMeasurement(
        date: Date(),
        treadDepth: 1.8,
        position: .rearLeft,
        tire: tire,
        notes: "Critical - schedule replacement immediately",
        mileage: 45000
    )
    container.mainContext.insert(measurement)

    // TPMS readings showing slow pressure loss
    let tpmsData: [(daysAgo: Double, psi: Double, temp: Double)] = [
        (90, 35.5, 15.0),
        (60, 33.2, 6.0),
        (30, 31.0, -1.0),
        (0,  29.4, 4.0)
    ]
    for item in tpmsData {
        let reading = TPMSReading(
            date: Date().addingTimeInterval(-item.daysAgo * 24 * 60 * 60),
            frontLeft: item.psi / 14.504,
            frontRight: (item.psi + 1.2) / 14.504,
            rearLeft: item.psi / 14.504,
            rearRight: (item.psi + 0.5) / 14.504,
            outsideTemperature: item.temp
        )
        reading.car = car
        container.mainContext.insert(reading)
    }

    return NavigationStack {
        TireDetailView(tire: tire)
    }
    .modelContainer(container)
}
