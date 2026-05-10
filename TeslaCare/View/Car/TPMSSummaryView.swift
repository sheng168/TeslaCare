//
//  TPMSSummaryView.swift
//  TeslaCare
//

import SwiftUI
import SwiftData

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

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Car.self, TPMSReading.self, configurations: config)
    let car = Car(name: "My Tesla", make: "Tesla", model: "Model 3", year: 2023)
    container.mainContext.insert(car)
    let reading = TPMSReading(date: Date(), frontLeft: 2.93, frontRight: 2.89, rearLeft: 2.48, rearRight: 2.55)
    reading.car = car
    container.mainContext.insert(reading)
    return TPMSSummaryView(car: car)
        .padding()
        .modelContainer(container)
}
