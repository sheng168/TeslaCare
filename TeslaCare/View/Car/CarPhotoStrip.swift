//
//  CarPhotoStrip.swift
//  TeslaCare
//

import SwiftUI
import PhotosUI
import CoreLocation

/// A car photo plus its optional on-device-generated part/side caption and capture metadata.
struct CarPhotoItem {
    let image: UIImage
    var caption: String?
    /// When the photo was taken (EXIF) or added — used to group photos into time clusters.
    var date: Date?
    /// Where the photo was taken, if known.
    var coordinate: CLLocationCoordinate2D?
}

/// Photos grouped into time clusters, each shown as a horizontal strip. Mirrors the photo
/// capture flow used for tire measurements; each thumbnail shows the FoundationModels
/// part/side label beneath it once available. In DEBUG builds, each thumbnail also shows
/// its distance from the average location of its group. Operates on plain values so it can
/// back both an in-memory list (adding a new car) and persisted `CarPhoto` models.
struct CarPhotoStrip: View {
    let items: [CarPhotoItem]
    let onAdd: (UIImage, PhotoCaptureMetadata) -> Void
    let onDelete: (Int) -> Void

    /// Photos taken more than this far apart start a new time group.
    private let groupingInterval: TimeInterval = 3600

    @Environment(LocationManager.self) private var locationManager

    @State private var photoPickerItems: [PhotosPickerItem] = []
    @State private var cameraCapture: UIImage?
    /// EXIF/TIFF metadata from the most recent camera capture (no GPS — filled from location).
    @State private var cameraMetadata: [String: Any] = [:]
    @State private var showingCamera = false
    @State private var showingPhotoSource = false
    @State private var showingPhotoPicker = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(timeGroups, id: \.self) { group in
                let center = averageCoordinate(of: group)
                VStack(alignment: .leading, spacing: 4) {
                    if let header = groupHeader(for: group) {
                        Text(header)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                    }
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(alignment: .top, spacing: 12) {
                            ForEach(group, id: \.self) { index in
                                thumbnail(index: index, groupCenter: center)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }

            addButton
        }
        .padding(.vertical, 4)
        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        .onChange(of: photoPickerItems) { _, newItems in
            Task {
                for item in newItems {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        // Library photos retain their original embedded EXIF/GPS; fall back to
                        // the current device location only when the file carries none.
                        var metadata = PhotoCaptureMetadata(imageData: data) ?? PhotoCaptureMetadata()
                        metadata.fillOrientation(from: image)
                        if !metadata.hasLocation {
                            metadata.fillLocation(from: locationManager.userLocation,
                                                  heading: locationManager.headingDegrees)
                        }
                        onAdd(image, metadata)
                    }
                }
                photoPickerItems = []
            }
        }
        .onChange(of: cameraCapture) { _, image in
            if let image {
                // Camera captures carry EXIF/TIFF but no GPS — source location from the device.
                var metadata = PhotoCaptureMetadata(imageProperties: cameraMetadata)
                metadata.fillOrientation(from: image)
                metadata.fillLocation(from: locationManager.userLocation,
                                      heading: locationManager.headingDegrees)
                onAdd(image, metadata)
                cameraCapture = nil
                cameraMetadata = [:]
            }
        }
        .onChange(of: showingCamera) { _, isShowing in
            // Warm up location/compass so a fresh fix is ready when the shutter fires.
            if isShowing {
                locationManager.refresh()
                locationManager.startUpdatingHeading()
            } else {
                locationManager.stopUpdatingHeading()
            }
        }
        .sheet(isPresented: $showingCamera) {
            ImagePickerView(sourceType: .camera,
                            selectedImage: $cameraCapture,
                            showTireOverlay: false,
                            onCaptureMetadata: { cameraMetadata = $0 })
                .ignoresSafeArea()
        }
        .confirmationDialog("Add Photo", isPresented: $showingPhotoSource) {
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button("Take Photo") { showingCamera = true }
            }
            Button("Choose from Library") { showingPhotoPicker = true }
            Button("Cancel", role: .cancel) {}
        }
        .photosPicker(isPresented: $showingPhotoPicker, selection: $photoPickerItems,
                      maxSelectionCount: 10, matching: .images)
    }

    // MARK: - Thumbnails

    @ViewBuilder
    private func thumbnail(index: Int, groupCenter: CLLocationCoordinate2D?) -> some View {
        VStack(spacing: 4) {
            Image(uiImage: items[index].image)
                .resizable()
                .scaledToFill()
                .frame(width: 100, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(alignment: .topTrailing) {
                    Button {
                        onDelete(index)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.white)
                            .background(Color.black.opacity(0.5), in: Circle())
                    }
                    .offset(x: 6, y: -6)
                }

            Text(items[index].caption ?? " ")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2, reservesSpace: true)
                .frame(width: 100)

            #if DEBUG
            if let distance = debugDistanceText(index: index, center: groupCenter) {
                Text(distance)
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.orange)
                    .frame(width: 100)
            }
            #endif
        }
    }

    private var addButton: some View {
        Button {
            showingPhotoSource = true
        } label: {
            VStack(spacing: 6) {
                Image(systemName: "plus")
                    .font(.title2)
                Text("Add")
                    .font(.caption)
            }
            .frame(width: 100, height: 100)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .foregroundStyle(.secondary)
        }
    }

    // MARK: - Grouping

    /// Item indices grouped into chronological time clusters. A gap larger than
    /// `groupingInterval` between consecutive photos starts a new group.
    private var timeGroups: [[Int]] {
        let order = items.indices.sorted {
            (items[$0].date ?? .distantPast) < (items[$1].date ?? .distantPast)
        }
        var groups: [[Int]] = []
        var current: [Int] = []
        var lastDate: Date?
        for index in order {
            let date = items[index].date
            if let lastDate, let date, date.timeIntervalSince(lastDate) > groupingInterval {
                groups.append(current)
                current = []
            }
            current.append(index)
            if let date { lastDate = date }
        }
        if !current.isEmpty { groups.append(current) }
        return groups
    }

    private func groupHeader(for group: [Int]) -> String? {
        guard let earliest = group.compactMap({ items[$0].date }).min() else { return nil }
        return earliest.formatted(date: .abbreviated, time: .shortened)
    }

    /// The mean of the recorded coordinates in a group, or `nil` if none have one.
    private func averageCoordinate(of group: [Int]) -> CLLocationCoordinate2D? {
        let coordinates = group.compactMap { items[$0].coordinate }
        guard !coordinates.isEmpty else { return nil }
        let latitude = coordinates.map(\.latitude).reduce(0, +) / Double(coordinates.count)
        let longitude = coordinates.map(\.longitude).reduce(0, +) / Double(coordinates.count)
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    #if DEBUG
    private func debugDistanceText(index: Int, center: CLLocationCoordinate2D?) -> String? {
        guard let center, let coordinate = items[index].coordinate else { return nil }
        let from = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let to = CLLocation(latitude: center.latitude, longitude: center.longitude)
        return String(format: "Δ %.0f m", from.distance(from: to))
    }
    #endif
}

#Preview {
    @Previewable @State var items: [CarPhotoItem] = []
    return Form {
        Section("Photos") {
            CarPhotoStrip(
                items: items,
                onAdd: { image, _ in items.append(CarPhotoItem(image: image, caption: "Front Bumper • Front Left")) },
                onDelete: { items.remove(at: $0) }
            )
        }
    }
    .environment(LocationManager())
}
