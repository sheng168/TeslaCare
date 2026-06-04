//
//  MeasurementRowView.swift
//  TeslaCare
//

import SwiftUI
import SwiftData

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

                if measurement.hasMultiplePoints {
                    let depths = measurement.effectiveTreadDepths

                    VStack(alignment: .leading, spacing: 2) {
                        Divider()
                            .padding(.vertical, 2)

                        Text("Detailed Measurements")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)

                        HStack(spacing: 12) {
                            ForEach(depths.indices, id: \.self) { index in
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(pointLabel(index: index, total: depths.count))
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                    Text(String(format: "%.1f/32\"", depths[index]))
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundStyle(treadColorForValue(depths[index]))
                                }
                            }
                        }

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

                if let photos = measurement.photos?.sorted(by: { $0.sortIndex < $1.sortIndex }),
                   !photos.isEmpty {
                    ForEach(photos, id: \.persistentModelID) { photo in
                        if let uiImage = UIImage(data: photo.data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 56, height: 56)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func treadColor(for measurement: TireMeasurement) -> Color {
        if measurement.isDanger { return .red }
        if measurement.isWarning { return .orange }
        return .green
    }

    private func treadColorForValue(_ value: Double) -> Color {
        if value <= 2.0 { return .red }
        if value <= 4.0 { return .orange }
        return .green
    }

    /// Label for a measurement point given its index and the total point count.
    /// Index 0 is innermost; the last index is outermost.
    private func pointLabel(index: Int, total: Int) -> String {
        switch total {
        case 2: return index == 0 ? "Inner" : "Outer"
        case 3: return ["Inner", "Center", "Outer"][index]
        case 4: return ["Inner", "Mid-In", "Mid-Out", "Outer"][index]
        case 5: return ["Inner", "Mid-In", "Center", "Mid-Out", "Outer"][index]
        default:
            if index == 0 { return "Inner" }
            if index == total - 1 { return "Outer" }
            return "\(index + 1)"
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Car.self, Tire.self, TireMeasurement.self, configurations: config)
    let car = Car(name: "My Tesla", make: "Tesla", model: "Model 3", year: 2023)
    container.mainContext.insert(car)
    let tire = Tire(brand: "Michelin", modelName: "Pilot Sport 4S", size: "235/45R18", currentPosition: .frontLeft)
    tire.car = car
    container.mainContext.insert(tire)

    let good = TireMeasurement(date: Date(), treadDepth: 8.0, position: .frontLeft, tire: tire, notes: "", mileage: 12000)
    good.car = car
    container.mainContext.insert(good)

    let threePoint = TireMeasurement(
        date: Date().addingTimeInterval(-86400 * 14),
        treadDepth: 6.2,
        position: .frontRight,
        tire: tire,
        notes: "",
        mileage: 11500,
        treadDepths: [5.5, 6.5, 6.5]
    )
    threePoint.car = car
    container.mainContext.insert(threePoint)

    let unevenWarning = TireMeasurement(
        date: Date().addingTimeInterval(-86400 * 30),
        treadDepth: 3.5,
        position: .rearLeft,
        tire: tire,
        notes: "Uneven wear noted",
        mileage: 10500,
        treadDepths: [2.0, 3.5, 5.0]
    )
    unevenWarning.car = car
    container.mainContext.insert(unevenWarning)

    let fivePoint = TireMeasurement(
        date: Date().addingTimeInterval(-86400 * 60),
        treadDepth: 4.6,
        position: .rearRight,
        tire: tire,
        notes: "",
        mileage: 9800,
        treadDepths: [3.5, 4.2, 5.0, 5.2, 5.1]
    )
    fivePoint.car = car
    container.mainContext.insert(fivePoint)

    let danger = TireMeasurement(date: Date().addingTimeInterval(-86400 * 90), treadDepth: 1.5, position: .rearRight, tire: tire, notes: "", mileage: 9000)
    danger.car = car
    container.mainContext.insert(danger)

    return List {
        MeasurementRowView(measurement: good)
        MeasurementRowView(measurement: threePoint)
        MeasurementRowView(measurement: unevenWarning)
        MeasurementRowView(measurement: fivePoint)
        MeasurementRowView(measurement: danger)
    }
    .modelContainer(container)
}
