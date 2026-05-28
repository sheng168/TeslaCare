import SwiftUI
import SwiftData

// MARK: - Car List

struct CarListView: View {
    @Query(sort: \Car.dateAdded, order: .reverse) private var cars: [Car]

    var body: some View {
        NavigationStack {
            Group {
                if cars.isEmpty {
                    emptyState
                } else {
                    List(cars) { car in
                        NavigationLink(destination: CarTireView(car: car)) {
                            CarRowView(car: car)
                        }
                    }
                }
            }
            .navigationTitle("TezCare")
        }
    }

    private var emptyState: some View {
        VStack(spacing: 6) {
            Image(systemName: "car.2")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("No Cars")
                .font(.headline)
            Text("Add cars in the iOS app")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

// MARK: - Car Row

struct CarRowView: View {
    let car: Car

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(car.displayName)
                .font(.system(.body, weight: .semibold))
                .lineLimit(1)
            HStack(spacing: 6) {
                tireDepthsRow
                if let level = car.batteryLevel {
                    Spacer()
                    batteryLabel(level)
                }
            }
        }
        .padding(.vertical, 2)
    }

    private func batteryLabel(_ level: Int) -> some View {
        HStack(spacing: 2) {
            Image(systemName: batteryIcon(for: level))
                .font(.caption2)
            Text("\(level)%")
                .font(.caption2)
        }
        .foregroundStyle(level < 20 ? .red : level < 40 ? .yellow : .green)
    }

    private var tireDepthsRow: some View {
        let depths = TirePosition.allCases.compactMap { pos -> (String, Color)? in
            guard let depth = car.latestMeasurement(for: pos)?.treadDepth else { return nil }
            let color: Color = depth <= 2 ? .red : depth <= 4 ? .yellow : .green
            return (String(format: "%.0f", depth), color)
        }
        return Group {
            if !depths.isEmpty {
                HStack(spacing: 3) {
                    ForEach(depths.indices, id: \.self) { i in
                        Text(depths[i].0)
                            .font(.caption2)
                            .foregroundStyle(depths[i].1)
                        if i < depths.count - 1 {
//                            Text("")
//                                .font(.caption2)
//                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }
        }
    }

    private func batteryIcon(for level: Int) -> String {
        switch level {
        case 0..<10:  return "battery.0percent"
        case 10..<35: return "battery.25percent"
        case 35..<60: return "battery.50percent"
        case 60..<85: return "battery.75percent"
        default:      return "battery.100percent"
        }
    }
}

// MARK: - Car Tire Detail

struct CarTireView: View {
    let car: Car

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                tireGrid
                if let avg = car.averageTreadDepth {
                    Divider()
                    HStack {
                        Text("Average")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(String(format: "%.1f/32\"", avg))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(avg <= 2 ? .red : avg <= 4 ? .yellow : .green)
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical, 4)
        }
        .navigationTitle(car.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var tireGrid: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                TireDepthCell(car: car, position: .frontLeft)
                TireDepthCell(car: car, position: .frontRight)
            }
            HStack(spacing: 4) {
                TireDepthCell(car: car, position: .rearLeft)
                TireDepthCell(car: car, position: .rearRight)
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Tire Depth Cell

struct TireDepthCell: View {
    let car: Car
    let position: TirePosition

    private var measurement: TireMeasurement? {
        car.latestMeasurement(for: position)
    }

    private var statusColor: Color {
        guard let m = measurement else { return .secondary }
        return m.isDanger ? .red : m.isWarning ? .yellow : .green
    }

    var body: some View {
        VStack(spacing: 2) {
            Text(position.abbreviation)
                .font(.caption2)
                .foregroundStyle(.secondary)
            if let m = measurement {
                Text(String(format: "%.1f", m.treadDepth))
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(statusColor)
                Text("/32\"")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                Text("—")
                    .font(.title3)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(statusColor.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Preview

@MainActor
private func makePreviewContainer() -> ModelContainer {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Car.self, Tire.self, TireMeasurement.self, configurations: config)
    let ctx = container.mainContext

    let car1 = Car(name: "My Tesla", make: "Tesla", model: "Model 3", year: 2023)
    car1.batteryLevel = 82; car1.chargingState = "Charging"; ctx.insert(car1)
    for pos in TirePosition.allCases {
        let tire = Tire(brand: "Michelin", modelName: "Pilot Sport 4S", size: "235/45R18", currentPosition: pos.rawValue)
        tire.car = car1; ctx.insert(tire)
        ctx.insert(TireMeasurement(date: Date(), treadDepth: 7.5, positionRaw: pos.rawValue, car: car1, tire: tire))
    }

    let car2 = Car(name: "Family Car", make: "Tesla", model: "Model Y", year: 2022)
    car2.batteryLevel = 41; ctx.insert(car2)
    for (pos, depth) in zip(TirePosition.allCases, [3.5, 3.2, 2.8, 3.0] as [Double]) {
        let tire = Tire(brand: "Goodyear", modelName: "Eagle F1", size: "255/45R19", currentPosition: pos.rawValue)
        tire.car = car2; ctx.insert(tire)
        ctx.insert(TireMeasurement(date: Date(), treadDepth: depth, positionRaw: pos.rawValue, car: car2, tire: tire))
    }

    let car3 = Car(name: "", make: "Tesla", model: "Cybertruck", year: 2024)
    car3.batteryLevel = 15; ctx.insert(car3)
    for pos in TirePosition.allCases {
        let tire = Tire(brand: "Goodyear", modelName: "Wrangler", size: "285/65R20", currentPosition: pos.rawValue)
        tire.car = car3; ctx.insert(tire)
        ctx.insert(TireMeasurement(date: Date(), treadDepth: 1.5, positionRaw: pos.rawValue, car: car3, tire: tire))
    }

    return container
}

#Preview("Empty") {
    CarListView()
        .modelContainer(for: [Car.self, Tire.self, TireMeasurement.self], inMemory: true)
}

#Preview("With Cars") {
    CarListView()
        .modelContainer(makePreviewContainer())
}
