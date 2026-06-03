//
//  PublicCarsMapView.swift
//  TeslaCare
//
//  Created by Jin on 6/2/26.
//

import SwiftUI
import MapKit
import CoreLocation
import OSLog

private let logger = Logger(subsystem: "com.teslacare", category: "CommunityMap")

struct PublicCarsMapView: View {
    let cars: [PublicCarRecord]

    @State private var position: MapCameraPosition = .automatic
    @State private var selectedCarID: String?
    @State private var geocoded: [String: CLLocationCoordinate2D] = [:]

    private var pinnableCars: [PinnedCar] {
        cars.compactMap { car in
            if let lat = car.latitude, let lon = car.longitude {
                return PinnedCar(car: car, coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon))
            }
            if let city = car.locationCity, let coord = geocoded[city] {
                return PinnedCar(car: car, coordinate: coord)
            }
            return nil
        }
    }

    private var selectedCar: PublicCarRecord? {
        guard let id = selectedCarID else { return nil }
        return cars.first { $0.id == id }
    }

    var body: some View {
        Map(position: $position, selection: $selectedCarID) {
            ForEach(pinnableCars) { pinned in
                Marker(pinned.car.displayName, systemImage: markerSymbol(for: pinned.car), coordinate: pinned.coordinate)
                    .tint(markerTint(for: pinned.car))
                    .tag(pinned.car.id)
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .overlay(alignment: .top) {
            if pinnableCars.isEmpty {
                noLocationOverlay
            }
        }
        .sheet(item: Binding(
            get: { selectedCar.map { SelectedCarBox(car: $0) } },
            set: { selectedCarID = $0?.car.id }
        )) { box in
            NavigationStack {
                PublicCarDetailView(car: box.car)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") { selectedCarID = nil }
                        }
                    }
            }
            .presentationDetents([.medium, .large])
        }
        .task(id: carsCacheKey) {
            await geocodeMissingCities()
        }
    }

    private var carsCacheKey: String {
        cars.compactMap(\.locationCity).joined(separator: "|")
    }

    private var noLocationOverlay: some View {
        Text("No cars with location data")
            .font(.footnote)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.regularMaterial, in: Capsule())
            .padding(.top, 12)
    }

    private func markerSymbol(for car: PublicCarRecord) -> String {
        switch car.listingType {
        case .forSale: return "tag.fill"
        case .rental:  return "key.fill"
        case .none:    return "car.fill"
        }
    }

    private func markerTint(for car: PublicCarRecord) -> Color {
        switch car.listingType {
        case .forSale: return .blue
        case .rental:  return .purple
        case .none:    return .gray
        }
    }

    private func geocodeMissingCities() async {
        let cities = Set(cars.compactMap { car -> String? in
            guard car.latitude == nil, let city = car.locationCity else { return nil }
            return geocoded[city] == nil ? city : nil
        })
        guard !cities.isEmpty else { return }

        for city in cities {
            guard let request = MKGeocodingRequest(addressString: city) else { continue }
            if let coordinate = await coordinate(for: request) {
                geocoded[city] = coordinate
            }
        }
    }

    private func coordinate(for request: MKGeocodingRequest) async -> CLLocationCoordinate2D? {
        await withCheckedContinuation { continuation in
            request.getMapItems { mapItems, error in
                if let error {
                    logger.error("Geocode failed: \(error.localizedDescription)")
                }
                continuation.resume(returning: mapItems?.first?.location.coordinate)
            }
        }
    }
}

private struct PinnedCar: Identifiable {
    let car: PublicCarRecord
    let coordinate: CLLocationCoordinate2D
    var id: String { car.id }
}

private struct SelectedCarBox: Identifiable {
    let car: PublicCarRecord
    var id: String { car.id }
}

#Preview {
    PublicCarsMapView(cars: [
        PublicCarRecord(
            id: "p1", name: "My Model 3", make: "Tesla", model: "Model 3", year: 2022,
            trimSummary: "LR AWD", vin: nil, mileage: 28_000,
            tireHealthPercentage: 80, averageTreadDepth: 7.2,
            locationCity: "San Francisco, CA",
            latitude: 37.7749, longitude: -122.4194,
            listingType: .forSale, listingURL: nil,
            askingPrice: 32_000, hasFSD: true, freeSupercharging: false,
            publishedAt: Date()
        ),
        PublicCarRecord(
            id: "p2", name: "Loaner Y", make: "Tesla", model: "Model Y", year: 2024,
            trimSummary: nil, vin: nil, mileage: 5_000,
            tireHealthPercentage: 95, averageTreadDepth: 9.0,
            locationCity: "Los Angeles, CA",
            latitude: 34.0522, longitude: -118.2437,
            listingType: .rental, listingURL: nil,
            askingPrice: nil, hasFSD: false, freeSupercharging: true,
            publishedAt: Date()
        )
    ])
}
