//
//  ChargersView.swift
//  TeslaCare
//
//  Created by Jin on 5/9/26.
//

import SwiftUI
import MapKit
import CoreLocation

@Observable
class ChargersViewModel: NSObject, CLLocationManagerDelegate {
    var chargers: [MKMapItem] = []
    var position: MapCameraPosition = .automatic
    var isLoading = false
    var errorMessage: String?

    private let locationManager = CLLocationManager()

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func requestLocationAndSearch() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation()
        default:
            errorMessage = "Location access denied. Enable it in Settings to find nearby Superchargers."
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            manager.requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        position = .region(MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 60000, longitudinalMeters: 60000))
        Task { await searchForChargers(near: location) }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        errorMessage = "Could not determine your location."
    }

    @MainActor
    private func searchForChargers(near location: CLLocation) async {
        isLoading = true
        errorMessage = nil
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "Tesla Supercharger"
        request.resultTypes = .pointOfInterest
        request.region = MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: 80000,
            longitudinalMeters: 80000
        )
        do {
            let response = try await MKLocalSearch(request: request).start()
            chargers = response.mapItems
        } catch {
            errorMessage = "Could not find nearby Superchargers."
        }
        isLoading = false
    }
}

struct ChargersView: View {
    @State private var viewModel = ChargersViewModel()
    @State private var selectedCharger: MKMapItem?

    var body: some View {
        NavigationStack {
            Map(position: $viewModel.position, selection: $selectedCharger) {
                UserAnnotation()
                ForEach(viewModel.chargers, id: \.self) { charger in
                    Marker(charger.name ?? "Supercharger", systemImage: "bolt.fill", coordinate: charger.location.coordinate)
                        .tint(.red)
                }
            }
            .mapControls {
                MapUserLocationButton()
                MapCompass()
                MapScaleView()
            }
            .navigationTitle("Superchargers")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                bottomPanel
            }
            .onAppear {
                viewModel.requestLocationAndSearch()
            }
        }
    }

    @ViewBuilder
    private var bottomPanel: some View {
        if let error = viewModel.errorMessage {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text(error)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial)
        } else if viewModel.isLoading {
            HStack(spacing: 10) {
                ProgressView()
                Text("Finding Superchargers…")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial)
        } else if !viewModel.chargers.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.chargers, id: \.self) { charger in
                        ChargerCard(charger: charger, isSelected: selectedCharger == charger)
                            .onTapGesture {
                                selectedCharger = charger
                                withAnimation {
                                    viewModel.position = .item(charger)
                                }
                            }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(.ultraThinMaterial)
        }
    }
}

struct ChargerCard: View {
    let charger: MKMapItem
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: "bolt.fill")
                    .foregroundStyle(.red)
                    .font(.caption)
                Text(charger.name ?? "Supercharger")
                    .font(.subheadline.bold())
                    .lineLimit(1)
            }
            Text(charger.address?.shortAddress ?? charger.addressRepresentations?.cityName ?? "")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(isSelected ? Color.red.opacity(0.12) : Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.red : Color.clear, lineWidth: 2)
        )
    }
}

#Preview {
    ChargersView()
}
