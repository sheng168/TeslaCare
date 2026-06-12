//
//  CarDetailView.swift
//  TeslaCare
//
//  Created by Jin on 5/7/26.
//

import SwiftUI
import SwiftData
import CoreLocation

struct CarDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(LocationManager.self) private var locationManager
    @Environment(CloudKitPublicService.self) private var cloudKitService
    let car: Car

    @State private var showingAddMeasurement = false
    @State private var showingRotateTires = false
    @State private var showingReplaceTires = false
    @State private var showingLogAirFilter = false
    @State private var showingUpdateMileage = false
    @State private var showingEditCar = false
    @State private var showingQuickEntry = false
    @State private var selectedPosition: TirePosition?
    @State private var showingPublishSheet = false
    @State private var showingUnpublishConfirm = false
    @State private var isUnpublishing = false
    @State private var unpublishAlertMessage: String?

    @AppStorage("detail.headerExpanded") private var headerExpanded = true
    @AppStorage("detail.pressureExpanded") private var pressureExpanded = true
    @AppStorage("detail.tireGridExpanded") private var tireGridExpanded = true
    @AppStorage("detail.actionsExpanded") private var actionsExpanded = true
    @AppStorage("detail.chartsExpanded") private var chartsExpanded = true
    @AppStorage("detail.mileageChartExpanded") private var mileageChartExpanded = true
    @AppStorage("detail.rotationExpanded") private var rotationExpanded = true
    @AppStorage("detail.replacementExpanded") private var replacementExpanded = true
    @AppStorage("detail.airFilterExpanded") private var airFilterExpanded = true
    @AppStorage("detail.repairExpanded") private var repairExpanded = true
    @AppStorage("detail.measurementsExpanded") private var measurementsExpanded = true
    @AppStorage("detail.photosExpanded") private var photosExpanded = true

    var sortedMeasurements: [TireMeasurement] {
        (car.measurements ?? []).sorted { $0.date > $1.date }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                carHeaderSection

                carPhotosSection

                tireGridSection
                actionButtonsSection

                historyChartsSection
                mileageChartSection
                pressureSection

                rotationHistorySection
                replacementHistorySection
                repairHistorySection
                airFilterHistorySection
                measurementHistorySection
            }
            .padding(.vertical)
        }
        .navigationTitle(car.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingAddMeasurement = true }) {
                    Label("Add Measurement", systemImage: "plus")
                }
            }

            ToolbarItem(placement: .secondaryAction) {
                Button(action: { showingEditCar = true }) {
                    Label("Edit Car", systemImage: "pencil")
                }
            }

            ToolbarItem(placement: .secondaryAction) {
                Button(action: { showingLogAirFilter = true }) {
                    Label("Log Air Filter", systemImage: "air.purifier.fill")
                }
            }

            ToolbarItem(placement: .secondaryAction) {
                Button(action: { showingUpdateMileage = true }) {
                    Label("Update Mileage", systemImage: "gauge.with.needle")
                }
            }

            ToolbarItem(placement: .secondaryAction) {
                Button(action: { showingQuickEntry = true }) {
                    Label("Quick Entry", systemImage: "keyboard")
                }
            }

            ToolbarItem(placement: .primaryAction) {
                if car.cloudKitRecordName != nil {
                    Button(action: { showingUnpublishConfirm = true }) {
                        Label("Unpublish", systemImage: "xmark.circle")
                    }
                    .disabled(isUnpublishing)
                } else {
                    Button(action: { showingPublishSheet = true }) {
                        Label("Publish to Rental/Used", systemImage: "globe")
                    }
                }
            }
        }
        .alert("Unpublish from Rental/Used?", isPresented: $showingUnpublishConfirm) {
            Button("Unpublish", role: .destructive) {
                isUnpublishing = true
                Task {
                    do {
                        try await cloudKitService.unpublishCar(car)
                    } catch {
                        unpublishAlertMessage = error.localizedDescription
                    }
                    isUnpublishing = false
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("\(car.displayName) will no longer be visible to other users.")
        }
        .alert("Unpublish Failed", isPresented: Binding(
            get: { unpublishAlertMessage != nil },
            set: { if !$0 { unpublishAlertMessage = nil } }
        )) {
            Button("OK") { unpublishAlertMessage = nil }
        } message: {
            Text(unpublishAlertMessage ?? "")
        }
        .sheet(isPresented: $showingPublishSheet) {
            PublishListingView(car: car)
        }
        .sheet(isPresented: $showingEditCar) {
            EditCarView(car: car)
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
        .sheet(isPresented: $showingUpdateMileage) {
            LogMileageView(car: car)
        }
        .sheet(isPresented: $showingQuickEntry) {
            BluetoothEntryView(car: car)
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
    private var carPhotosSection: some View {
        VStack(spacing: 0) {
            DisclosureGroup(isExpanded: $photosExpanded) {
                CarPhotoStrip(
                    images: sortedPhotos.compactMap { UIImage(data: $0.data) },
                    onAdd: addPhoto,
                    onDelete: deletePhoto
                )
                .padding(.top, 4)
            } label: {
                Text("Photos")
                    .font(.headline)
                    .foregroundStyle(.primary)
            }
        }
        .padding(.horizontal)
    }

    private var sortedPhotos: [CarPhoto] {
        (car.photos ?? []).sorted { $0.sortIndex < $1.sortIndex }
    }

    private func addPhoto(_ image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 0.7) else { return }
        let nextIndex = (sortedPhotos.last?.sortIndex ?? -1) + 1
        let photo = CarPhoto(data: data, sortIndex: nextIndex)
        photo.car = car
        modelContext.insert(photo)
    }

    private func deletePhoto(at index: Int) {
        let photos = sortedPhotos
        guard photos.indices.contains(index) else { return }
        modelContext.delete(photos[index])
    }

    @ViewBuilder
    private var mileageChartSection: some View {
        let readings = car.mileageReadings ?? []
        if !readings.isEmpty {
            VStack(spacing: 0) {
                DisclosureGroup(isExpanded: $mileageChartExpanded) {
                    MileageHistoryChartView(car: car, chartHeight: 160)
                        .padding(.top, 4)
                } label: {
                    Text("Mileage History")
                        .font(.headline)
                        .foregroundStyle(.primary)
                }
            }
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    private var pressureSection: some View {
        if car.latestTPMSReading != nil {
            VStack(spacing: 0) {
                DisclosureGroup(isExpanded: $pressureExpanded) {
                    TPMSSummaryView(car: car)
                        .padding(.top, 4)
                } label: {
                    Text("Tire Pressure")
                        .font(.headline)
                        .foregroundStyle(.primary)
                }
            }
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    private var tireGridSection: some View {
        VStack(spacing: 0) {
            DisclosureGroup(isExpanded: $tireGridExpanded) {
                TireGridView(car: car, selectedPosition: $selectedPosition)
                    .padding(.top, 4)
            } label: {
                Text("Tires")
                    .font(.headline)
                    .foregroundStyle(.primary)
            }
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private var actionButtonsSection: some View {
        VStack(spacing: 0) {
            DisclosureGroup(isExpanded: $actionsExpanded) {
                HStack(spacing: 12) {
                    actionButton("Rotate", icon: "arrow.triangle.2.circlepath", color: .blue) {
                        showingRotateTires = true
                    }
                    actionButton("Replace", icon: "plus.circle.fill", color: .green) {
                        showingReplaceTires = true
                    }
                    actionButton("Mileage", icon: "gauge.with.needle", color: .orange) {
                        showingUpdateMileage = true
                    }
                }
                .padding(.top, 4)
            } label: {
                Text("Actions")
                    .font(.headline)
                    .foregroundStyle(.primary)
            }
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private var historyChartsSection: some View {
        let hasTpms = car.latestTPMSReading != nil
        let hasMeasurements = !(car.measurements?.isEmpty ?? true)
        if hasTpms || hasMeasurements {
            VStack(spacing: 0) {
                DisclosureGroup(isExpanded: $chartsExpanded) {
                    VStack(spacing: 8) {
                        TPMSHistoryChartView(car: car, chartHeight: 160)
                        TreadDepthHistoryChartView(car: car, chartHeight: 160)
                    }
                    .padding(.top, 4)
                } label: {
                    Text("History Charts")
                        .font(.headline)
                        .foregroundStyle(.primary)
                }
            }
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    private var carHeaderSection: some View {
        VStack(spacing: 0) {
            DisclosureGroup(isExpanded: $headerExpanded) {
                VStack(spacing: 8) {
                    HStack(spacing: 6) {
                        if let summary = car.drivetrainSummary {
                            Text(summary)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.blue.opacity(0.8))
                                .clipShape(Capsule())
                        }
                        if car.hasFSD == true {
                            Text("FSD")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.purple.opacity(0.85))
                                .clipShape(Capsule())
                        }
                        if car.freeSupercharging == true {
                            Text("Free SC")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.orange.opacity(0.85))
                                .clipShape(Capsule())
                        }
                    }

                    HStack(spacing: 12) {
                        if let price = car.purchasePrice {
                            Text(price, format: .currency(code: "USD").precision(.fractionLength(0)))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        if let urlString = car.listingURL, let url = URL(string: urlString) {
                            Link(destination: url) {
                                Label("Listing", systemImage: "link")
                                    .font(.subheadline)
                            }
                        }
                    }

                    HStack(spacing: 12) {
                        Button {
                            showingUpdateMileage = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "gauge.with.needle")
                                    .font(.caption)
                                Text(car.mileage.map { "\($0.formatted()) mi" } ?? "Add Mileage")
                                    .font(.subheadline)
                            }
                            .foregroundStyle(car.mileage != nil ? Color.secondary : Color.blue)
                        }
                        .buttonStyle(.plain)
                        if let level = car.batteryLevel {
                            batteryView(level: level, chargingState: car.chargingState)
                        }
                    }

                    carLocationRow

                    if let health = car.tireHealthPercentage {
                        tireHealthCard(health)
                    }
                }
                .padding(.top, 8)
            } label: {
                Text("\(car.year, format: .number.grouping(.never)) \(car.make) \(car.model)")
                    .font(.headline)
                    .foregroundStyle(.primary)
            }
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private var carLocationRow: some View {
        if let carLat = car.latitude, let carLon = car.longitude {
            let carLocation = CLLocation(latitude: carLat, longitude: carLon)
            HStack(spacing: 6) {
                if let heading = car.heading {
                    Image(systemName: "location.north.fill")
                        .rotationEffect(.degrees(heading))
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
                if let userLocation = locationManager.userLocation {
                    let distance = userLocation.distance(from: carLocation)
                    let measurement = Measurement(value: distance, unit: UnitLength.meters)
                    let formatted = measurement.converted(to: distance < 1000 ? .meters : .kilometers)
                    Text(formatted, format: .measurement(width: .abbreviated, usage: .road))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("away")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                } else {
                    Text("Locating…")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                }
            }
            .onAppear { locationManager.refresh() }
        }
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

    @ViewBuilder
    private func batteryView(level: Int, chargingState: String?) -> some View {
        let isCharging = chargingState == "Charging" || chargingState == "Starting"
        let color: Color = isCharging ? .blue : (level >= 50 ? .green : level >= 20 ? .orange : .red)
        let icon: String = {
            let bolt = isCharging ? ".bolt" : ""
            if level >= 88 { return "battery.100\(bolt)" }
            if level >= 63 { return "battery.75\(bolt)" }
            if level >= 38 { return "battery.50\(bolt)" }
            if level >= 13 { return "battery.25\(bolt)" }
            return "battery.0\(bolt)"
        }()
        HStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text("\(level)%")
                .font(.subheadline)
                .foregroundStyle(color)
            if isCharging {
                Text("Charging")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
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
            VStack(spacing: 0) {
                DisclosureGroup(isExpanded: $rotationExpanded) {
                    VStack(spacing: 8) {
                        ForEach(rotations) { rotation in
                            RotationEventRow(rotation: rotation)
                        }
                    }
                    .padding(.top, 4)
                } label: {
                    Text("Rotation History")
                        .font(.headline)
                        .foregroundStyle(.primary)
                }
            }
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    private var replacementHistorySection: some View {
        if let replacements = car.replacementEvents?.sorted(by: { $0.date > $1.date }), !replacements.isEmpty {
            VStack(spacing: 0) {
                DisclosureGroup(isExpanded: $replacementExpanded) {
                    VStack(spacing: 8) {
                        ForEach(replacements) { replacement in
                            ReplacementEventRow(replacement: replacement)
                        }
                    }
                    .padding(.top, 4)
                } label: {
                    Text("Replacement History")
                        .font(.headline)
                        .foregroundStyle(.primary)
                }
            }
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    private var repairHistorySection: some View {
        if let repairs = car.repairEvents?.sorted(by: { $0.date > $1.date }), !repairs.isEmpty {
            VStack(spacing: 0) {
                DisclosureGroup(isExpanded: $repairExpanded) {
                    VStack(spacing: 8) {
                        ForEach(repairs) { repair in
                            TireRepairEventRow(repair: repair)
                        }
                    }
                    .padding(.top, 4)
                } label: {
                    Text("Repair History")
                        .font(.headline)
                        .foregroundStyle(.primary)
                }
            }
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    private var airFilterHistorySection: some View {
        if let airFilters = car.airFilterChanges?.sorted(by: { $0.date > $1.date }), !airFilters.isEmpty {
            VStack(spacing: 0) {
                DisclosureGroup(isExpanded: $airFilterExpanded) {
                    VStack(spacing: 8) {
                        ForEach(airFilters) { filterChange in
                            AirFilterChangeRow(filterChange: filterChange)
                        }
                    }
                    .padding(.top, 4)
                } label: {
                    Text("Air Filter Changes")
                        .font(.headline)
                        .foregroundStyle(.primary)
                }
            }
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    private var measurementHistorySection: some View {
        VStack(spacing: 0) {
            DisclosureGroup(isExpanded: $measurementsExpanded) {
                Group {
                    if sortedMeasurements.isEmpty {
                        ContentUnavailableView(
                            "No Measurements",
                            systemImage: "gauge.with.dots.needle.0percent",
                            description: Text("Add tire measurements to track tread depth over time")
                        )
                        .frame(height: 200)
                    } else {
                        VStack(spacing: 8) {
                            ForEach(sortedMeasurements) { measurement in
                                MeasurementRowView(measurement: measurement)
                            }
                        }
                    }
                }
                .padding(.top, 4)
            } label: {
                Text("Measurement History")
                    .font(.headline)
                    .foregroundStyle(.primary)
            }
        }
        .padding(.horizontal)
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

// MARK: - Edit Car Sheet

private struct EditCarView: View {
    @Environment(\.dismiss) private var dismiss
    let car: Car

    @State private var name: String
    @State private var make: String
    @State private var model: String
    @State private var year: Int
    @State private var vin: String
    @State private var trimBadging: String
    @State private var perfConfig: String
    @State private var priceText: String
    @State private var urlText: String
    @State private var hasFSD: Bool
    @State private var freeSupercharging: Bool

    private static let currentYear = Calendar.current.component(.year, from: Date())

    init(car: Car) {
        self.car = car
        _name = State(initialValue: car.name)
        _make = State(initialValue: car.make)
        _model = State(initialValue: car.model)
        _year = State(initialValue: car.year)
        _vin = State(initialValue: car.vin ?? "")
        _trimBadging = State(initialValue: car.trimBadging ?? "")
        _perfConfig = State(initialValue: car.perfConfig ?? "")
        _priceText = State(initialValue: car.purchasePrice.map { String(format: "%.0f", $0) } ?? "")
        _urlText = State(initialValue: car.listingURL ?? "")
        _hasFSD = State(initialValue: car.hasFSD ?? false)
        _freeSupercharging = State(initialValue: car.freeSupercharging ?? false)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Car Info") {
                    TextField("Name (optional)", text: $name)
                    TextField("Make", text: $make)
                        .autocorrectionDisabled()
                    TextField("Model", text: $model)
                        .autocorrectionDisabled()
                    Picker("Year", selection: $year) {
                        ForEach((1990...(Self.currentYear + 1)).reversed(), id: \.self) { y in
                            Text(String(y)).tag(y)
                        }
                    }
                }

                Section("Details") {
                    TextField("VIN (optional)", text: $vin)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                    TextField("Trim Badge (e.g. P100D, LR AWD)", text: $trimBadging)
                        .autocorrectionDisabled()
                    TextField("Perf Config (e.g. sport)", text: $perfConfig)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }

                Section("Purchase") {
                    HStack {
                        Text("$")
                            .foregroundStyle(.secondary)
                        TextField("Price", text: $priceText)
                            .keyboardType(.numberPad)
                    }
                    TextField("Listing URL", text: $urlText)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }

                Section("Features") {
                    Toggle("Full Self-Driving (FSD)", isOn: $hasFSD)
                    Toggle("Free Supercharging", isOn: $freeSupercharging)
                }
            }
            .navigationTitle("Edit Car")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        car.name = name
                        car.make = make
                        car.model = model
                        car.year = year
                        car.vin = vin.isEmpty ? nil : vin
                        car.trimBadging = trimBadging.isEmpty ? nil : trimBadging
                        car.perfConfig = perfConfig.isEmpty ? nil : perfConfig
                        car.purchasePrice = Double(priceText)
                        car.listingURL = urlText.isEmpty ? nil : urlText
                        car.hasFSD = hasFSD
                        car.freeSupercharging = freeSupercharging
                        dismiss()
                    }
                    .disabled(make.isEmpty || model.isEmpty)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: Car.self, TireMeasurement.self, Tire.self, TireRotationEvent.self, TireReplacementEvent.self, AirFilterChangeEvent.self, TPMSReading.self, MileageReading.self, NearbyCharger.self, configurations: config)

        let car = Car(name: "My Tesla", make: "Tesla", model: "Model 3", year: 2023)
        container.mainContext.insert(car)

        let tire1 = Tire(brand: "Michelin", modelName: "Pilot Sport", size: "235/45R18", currentPosition: .frontLeft)
        tire1.car = car
        container.mainContext.insert(tire1)

        let tire2 = Tire(brand: "Michelin", modelName: "Pilot Sport", size: "235/45R18", currentPosition: .frontRight)
        tire2.car = car
        container.mainContext.insert(tire2)

        let measurement1 = TireMeasurement(date: Date(), treadDepth: 7.5, position: .frontLeft, tire: tire1, notes: "", mileage: nil)
        measurement1.car = car
        container.mainContext.insert(measurement1)

        let measurement2 = TireMeasurement(date: Date().addingTimeInterval(-86400), treadDepth: 3.2, position: .frontRight, tire: tire2, notes: "", mileage: nil)
        measurement2.car = car
        container.mainContext.insert(measurement2)

        let chargers: [(String, String, Double, Int, Int)] = [
            ("Tesla Supercharger - Downtown", "supercharger_v3", 1.2, 6, 12),
            ("Tesla Supercharger - Mall", "supercharger_v2", 3.5, 2, 8),
            ("Tesla Supercharger - Highway", "supercharger_v4", 8.1, 10, 16),
        ]
        for (name, rawType, dist, avail, total) in chargers {
            let c = NearbyCharger(name: name, chargerType: "supercharger", rawType: rawType,
                                  latitude: nil, longitude: nil, distanceMiles: dist,
                                  availableStalls: avail, totalStalls: total, siteClosed: false)
            c.car = car
            container.mainContext.insert(c)
        }

        return CarDetailView(car: car)
            .modelContainer(container)
            .environment(LocationManager())
            .environment(CloudKitPublicService())
            .environmentObject(TeslaAuthManager())
    }
}
