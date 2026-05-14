//
//  PublicCarsView.swift
//  TeslaCare
//
//  Created by Jin on 5/14/26.
//

import SwiftUI

struct PublicCarsView: View {
    @Environment(CloudKitPublicService.self) private var service

    var body: some View {
        NavigationStack {
            Group {
                if service.isLoading {
                    ProgressView("Loading community cars…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if service.publicCars.isEmpty {
                    ContentUnavailableView(
                        "No Community Cars",
                        systemImage: "globe",
                        description: Text("Be the first to publish your car.")
                    )
                } else {
                    List(service.publicCars) { car in
                        NavigationLink(destination: PublicCarDetailView(car: car)) {
                            PublicCarRowView(car: car)
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Community")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        Task { await service.fetchPublicCars() }
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    .disabled(service.isLoading)
                }
            }
            .task {
                await service.fetchPublicCars()
            }
            .refreshable {
                await service.fetchPublicCars()
            }
        }
    }
}

struct PublicCarRowView: View {
    let car: PublicCarRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(car.displayName)
                .font(.headline)

            HStack(spacing: 6) {
                if let type = car.listingType {
                    Text(type.rawValue)
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(type == .forSale ? Color.blue : Color.purple)
                        .clipShape(Capsule())
                }
                if let trim = car.trimSummary {
                    Text(trim)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let mileage = car.mileage {
                    Text("· \(mileage.formatted()) mi")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if let health = car.tireHealthPercentage {
                HStack(spacing: 4) {
                    Image(systemName: "circle.fill")
                        .font(.caption2)
                        .foregroundStyle(healthColor(for: health))
                    Text("Tire Health: \(Int(health))%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let depth = car.averageTreadDepth {
                        Text("· Avg \(String(format: "%.1f", depth))/32\"")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            Text(car.publishedAt, format: .relative(presentation: .named))
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }

    private func healthColor(for percentage: Double) -> Color {
        switch percentage {
        case 50...100: return .green
        case 25..<50: return .orange
        default: return .red
        }
    }
}

#Preview {
    PublicCarsView()
        .environment(CloudKitPublicService())
}
