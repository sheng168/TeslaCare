//
//  PublicCarsView.swift
//  TeslaCare
//
//  Created by Jin on 5/14/26.
//

import SwiftUI

enum CarSortOption: String, CaseIterable {
    case newestFirst  = "Newest First"
    case oldestFirst  = "Oldest First"
    case mileageLow   = "Mileage: Low to High"
    case mileageHigh  = "Mileage: High to Low"
    case yearNew      = "Year: Newest"
    case yearOld      = "Year: Oldest"
    case priceLow     = "Price: Low to High"
    case priceHigh    = "Price: High to Low"
}

struct CarFilterState: Equatable {
    var listingType: ListingType? = nil
    var requireFSD: Bool = false
    var requireFreeSC: Bool = false

    var isActive: Bool {
        listingType != nil || requireFSD || requireFreeSC
    }
}

struct PublicCarsView: View {
    @Environment(CloudKitPublicService.self) private var service

    @State private var sortOption: CarSortOption = .newestFirst
    @State private var filters = CarFilterState()
    @State private var showingFilterSheet = false

    private var displayedCars: [PublicCarRecord] {
        var cars = service.publicCars

        if let type = filters.listingType {
            cars = cars.filter { $0.listingType == type }
        }
        if filters.requireFSD {
            cars = cars.filter { $0.hasFSD == true }
        }
        if filters.requireFreeSC {
            cars = cars.filter { $0.freeSupercharging == true }
        }

        switch sortOption {
        case .newestFirst:
            cars.sort { $0.publishedAt > $1.publishedAt }
        case .oldestFirst:
            cars.sort { $0.publishedAt < $1.publishedAt }
        case .mileageLow:
            cars.sort { ($0.mileage ?? Int.max) < ($1.mileage ?? Int.max) }
        case .mileageHigh:
            cars.sort { ($0.mileage ?? -1) > ($1.mileage ?? -1) }
        case .yearNew:
            cars.sort { $0.year > $1.year }
        case .yearOld:
            cars.sort { $0.year < $1.year }
        case .priceLow:
            cars.sort { ($0.askingPrice ?? Double.greatestFiniteMagnitude) < ($1.askingPrice ?? Double.greatestFiniteMagnitude) }
        case .priceHigh:
            cars.sort { ($0.askingPrice ?? -1) > ($1.askingPrice ?? -1) }
        }

        return cars
    }

    var body: some View {
        NavigationStack {
            Group {
                if service.isLoading {
                    ProgressView("Loading community cars…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if displayedCars.isEmpty {
                    ContentUnavailableView(
                        filters.isActive ? "No Matching Cars" : "No Community Cars",
                        systemImage: "globe",
                        description: Text(filters.isActive ? "Try adjusting your filters." : "Be the first to publish your car.")
                    )
                } else {
                    List(displayedCars) { car in
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
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingFilterSheet = true
                    } label: {
                        Label("Filter & Sort", systemImage: filters.isActive ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .sheet(isPresented: $showingFilterSheet) {
                FilterSortSheet(sortOption: $sortOption, filters: $filters)
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

struct FilterSortSheet: View {
    @Binding var sortOption: CarSortOption
    @Binding var filters: CarFilterState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Sort By") {
                    Picker("Sort", selection: $sortOption) {
                        ForEach(CarSortOption.allCases, id: \.self) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }

                Section("Filter by Listing Type") {
                    Picker("Listing Type", selection: $filters.listingType) {
                        Text("All").tag(Optional<ListingType>.none)
                        ForEach(ListingType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(Optional(type))
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Features") {
                    Toggle("Full Self-Driving (FSD)", isOn: $filters.requireFSD)
                    Toggle("Free Supercharging", isOn: $filters.requireFreeSC)
                }

                if filters.isActive {
                    Section {
                        Button("Clear All Filters", role: .destructive) {
                            filters = CarFilterState()
                        }
                    }
                }
            }
            .navigationTitle("Filter & Sort")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
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
                if car.hasFSD == true {
                    Text("FSD")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.purple.opacity(0.85))
                        .clipShape(Capsule())
                }
                if car.freeSupercharging == true {
                    Text("Free SC")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.orange.opacity(0.85))
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
