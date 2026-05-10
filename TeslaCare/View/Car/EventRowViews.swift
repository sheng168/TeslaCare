//
//  EventRowViews.swift
//  TeslaCare
//

import SwiftUI
import SwiftData

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

#Preview("Rotation") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: TireRotationEvent.self, configurations: config)
    let rotation = TireRotationEvent(date: Date(), pattern: .xPattern, mileage: 15000, notes: "Done at Discount Tire")
    container.mainContext.insert(rotation)
    return List { RotationEventRow(rotation: rotation) }
        .modelContainer(container)
}

#Preview("Replacement") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: TireReplacementEvent.self, configurations: config)
    let replacement = TireReplacementEvent(date: Date(), positions: [.frontLeft, .frontRight],
                                           brand: "Michelin", modelName: "Pilot Sport 4S",
                                           mileage: 40000, cost: 620.00, notes: "")
    container.mainContext.insert(replacement)
    return List { ReplacementEventRow(replacement: replacement) }
        .modelContainer(container)
}

#Preview("Air Filter") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: AirFilterChangeEvent.self, configurations: config)
    let change = AirFilterChangeEvent(date: Date(), filterType: .cabin, mileage: 18000,
                                      brand: "Bosch", partNumber: "5058WS", cost: 24.99)
    container.mainContext.insert(change)
    return List { AirFilterChangeRow(filterChange: change) }
        .modelContainer(container)
}
