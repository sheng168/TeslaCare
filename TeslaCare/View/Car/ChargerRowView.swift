//
//  ChargerRowView.swift
//  TeslaCare
//

import SwiftUI
import SwiftData

struct ChargerRowView: View {
    let charger: NearbyCharger

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: charger.chargerType == "supercharger" ? "bolt.fill" : "ev.plug.dc.ccs1.fill")
                .font(.caption)
                .foregroundStyle(charger.siteClosed ? Color.secondary : Color.green)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(charger.name)
                    .font(.subheadline)
                    .lineLimit(1)
                if charger.siteClosed {
                    Text("Closed")
                        .font(.caption)
                        .foregroundStyle(.red)
                } else if let avail = charger.availableStalls, let total = charger.totalStalls {
                    Text("\(avail)/\(total) stalls available")
                        .font(.caption)
                        .foregroundStyle(avail > 0 ? Color.green : Color.orange)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                if let kw = charger.estimatedMaxPowerKW {
                    Text("\(kw) kW")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.85))
                        .clipShape(Capsule())
                }
                Text(String(format: "%.1f mi", charger.distanceMiles))
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: NearbyCharger.self, configurations: config)

    let v3 = NearbyCharger(name: "Tesla Supercharger – Downtown", chargerType: "supercharger",
                            rawType: "supercharger_v3", latitude: nil, longitude: nil,
                            distanceMiles: 1.2, availableStalls: 6, totalStalls: 12, siteClosed: false)
    let v2 = NearbyCharger(name: "Tesla Supercharger – Mall", chargerType: "supercharger",
                            rawType: "supercharger_v2", latitude: nil, longitude: nil,
                            distanceMiles: 3.5, availableStalls: 0, totalStalls: 8, siteClosed: false)
    let closed = NearbyCharger(name: "Tesla Supercharger – Airport", chargerType: "supercharger",
                               rawType: "supercharger_v4", latitude: nil, longitude: nil,
                               distanceMiles: 8.1, availableStalls: nil, totalStalls: nil, siteClosed: true)
    let dest = NearbyCharger(name: "Marriott Hotel Charger", chargerType: "destination",
                             rawType: nil, latitude: nil, longitude: nil,
                             distanceMiles: 2.0, availableStalls: nil, totalStalls: nil, siteClosed: false)

    return List {
        ChargerRowView(charger: v3)
        ChargerRowView(charger: v2)
        ChargerRowView(charger: closed)
        ChargerRowView(charger: dest)
    }
    .modelContainer(container)
}
