//
//  PublicCarDetailView.swift
//  TeslaCare
//
//  Created by Jin on 5/14/26.
//

import SwiftUI

struct PublicCarDetailView: View {
    let car: PublicCarRecord

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                heroCard
                if let url = car.listingURL {
                    Link(destination: url) {
                        Label("View Listing", systemImage: "arrow.up.right.square.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(listingTypeColor)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                statsRow
                conditionCard
                listingCard
            }
            .padding()
        }
        .navigationTitle(car.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var listingTypeColor: Color {
        switch car.listingType {
        case .forSale: return .blue
        case .rental:  return .purple
        case .none:    return .blue
        }
    }

    // MARK: - Hero

    private var heroCard: some View {
        ZStack(alignment: .bottomLeading) {
            Color(.secondarySystemBackground)

            Image(systemName: "car.side.fill")
                .font(.system(size: 110))
                .foregroundStyle(Color(.systemGray4))
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.trailing, 20)
                .padding(.bottom, 12)

            VStack(alignment: .leading, spacing: 4) {
                Text(String(car.year))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("\(car.make) \(car.model)")
                    .font(.largeTitle.bold())
                HStack(spacing: 6) {
                    if let type = car.listingType {
                        Text(type.rawValue)
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(listingTypeColor)
                            .clipShape(Capsule())
                    }
                    if let trim = car.trimSummary {
                        Text(trim)
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.85))
                            .clipShape(Capsule())
                    }
                }
                .padding(.top, 2)
            }
            .padding(20)
        }
        .frame(height: 180)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Stats

    private var statsRow: some View {
        HStack(spacing: 12) {
            statCard(icon: "speedometer", label: "Mileage") {
                if let mileage = car.mileage {
                    HStack(alignment: .lastTextBaseline, spacing: 3) {
                        Text(mileage.formatted())
                            .font(.title2.bold())
                        Text("mi")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("—").font(.title2.bold()).foregroundStyle(Color.secondary)
                }
            }
            statCard(icon: "calendar", label: "Listed") {
                Text(car.publishedAt, format: .relative(presentation: .named))
                    .font(.title3.bold())
            }
        }
    }

    private func statCard<Content: View>(icon: String, label: String, @ViewBuilder value: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(label, systemImage: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            value()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Condition

    private var conditionCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Tire Condition", systemImage: "circle.circle.fill")
                .font(.headline)

            if let health = car.tireHealthPercentage {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(conditionLabel(for: health))
                            .font(.title2.bold())
                            .foregroundStyle(healthColor(for: health))
                        Text("\(Int(health))% overall health")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    gradeBadge(for: health)
                }

                ProgressView(value: health, total: 100)
                    .tint(healthColor(for: health))
                    .scaleEffect(x: 1, y: 1.6)
                    .padding(.vertical, 4)

                if let depth = car.averageTreadDepth {
                    HStack {
                        Text("Average tread depth")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(String(format: "%.1f/32\"", depth))
                            .font(.subheadline.bold())
                    }
                    .padding(.top, 4)
                }
            } else {
                Text("No tire data shared for this listing.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func gradeBadge(for health: Double) -> some View {
        Text(conditionGrade(for: health))
            .font(.system(size: 28, weight: .bold, design: .rounded))
            .frame(width: 54, height: 54)
            .background(healthColor(for: health).opacity(0.15))
            .foregroundStyle(healthColor(for: health))
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Listing Info

    private var listingCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Listing Details")
                .font(.headline)
                .padding(.bottom, 12)

            listingRow(icon: "checkmark.seal.fill", iconColor: .green,
                       label: "Source", value: "TeslaCare user")

            if let vin = car.vin {
                Divider().padding(.vertical, 10)
                listingRow(icon: "number", iconColor: .secondary,
                           label: "VIN", value: vin)
            }

            if let city = car.locationCity {
                Divider().padding(.vertical, 10)
                listingRow(icon: "location.fill", iconColor: .secondary,
                           label: "Location", value: city)
            }

            if let url = car.listingURL {
                Divider().padding(.vertical, 10)
                HStack(alignment: .top) {
                    Image(systemName: "link")
                        .foregroundStyle(.secondary)
                        .frame(width: 18)
                    Text("Link")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Link(destination: url) {
                        Text(url.host() ?? url.absoluteString)
                            .font(.subheadline)
                            .foregroundStyle(.blue)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
            }

            Divider().padding(.vertical, 10)
            listingRow(icon: "clock", iconColor: .secondary,
                       label: "Published", value: car.publishedAt.formatted(date: .abbreviated, time: .omitted))
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func listingRow(icon: String, iconColor: Color, label: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(iconColor)
                .frame(width: 18)
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
        }
    }

    // MARK: - Helpers

    private func conditionLabel(for health: Double) -> String {
        switch health {
        case 80...100: return "Excellent"
        case 60..<80:  return "Good"
        case 40..<60:  return "Fair"
        default:       return "Poor"
        }
    }

    private func conditionGrade(for health: Double) -> String {
        switch health {
        case 80...100: return "A"
        case 60..<80:  return "B"
        case 40..<60:  return "C"
        default:       return "D"
        }
    }

    private func healthColor(for health: Double) -> Color {
        switch health {
        case 50...100: return .green
        case 25..<50:  return .orange
        default:       return .red
        }
    }
}

#Preview {
    NavigationStack {
        PublicCarDetailView(car: PublicCarRecord(
            id: "preview-1",
            name: "My Model 3",
            make: "Tesla", model: "Model 3", year: 2022,
            trimSummary: "Long Range AWD",
            vin: "5YJ3E1EA1NF012345",
            mileage: 28_450,
            tireHealthPercentage: 74,
            averageTreadDepth: 6.8,
            locationCity: "San Francisco, CA",
            listingType: .forSale,
            listingURL: URL(string: "https://craigslist.org/example"),
            publishedAt: Date().addingTimeInterval(-86400 * 3)
        ))
    }
}
