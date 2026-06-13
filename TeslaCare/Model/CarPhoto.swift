//
//  CarPhoto.swift
//  TeslaCare
//

import Foundation
import SwiftData
import CoreLocation

@Model
final class CarPhoto {
    var data: Data = Data()
    var sortIndex: Int = 0
    var createdAt: Date = Date()

    /// The car part/area shown, identified on-device by FoundationModels (e.g. "Front Bumper").
    var part: String?
    /// The side of the car the photo represents (e.g. "Front Left").
    var side: String?

    // MARK: - Capture metadata
    /// Location where the photo was taken (embedded GPS, or the device's location for camera shots).
    var latitude: Double?
    var longitude: Double?
    /// Altitude in meters; negative below sea level.
    var altitude: Double?
    /// Compass direction the camera faced, in degrees (0 = true north).
    var heading: Double?
    /// EXIF orientation tag (1–8) describing how the image should be rotated for display.
    var orientation: Int?
    /// Whether the capture is portrait (taller than wide).
    var isPortrait: Bool?
    /// Original capture date from EXIF, when available.
    var captureDate: Date?
    var cameraMake: String?
    var cameraModel: String?
    var lensModel: String?

    var car: Car?

    init(data: Data, sortIndex: Int = 0) {
        self.data = data
        self.sortIndex = sortIndex
        self.createdAt = Date()
    }

    /// The capture location, if recorded.
    var coordinate: CLLocationCoordinate2D? {
        guard let latitude, let longitude else { return nil }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    /// Copies capture metadata extracted at add-time onto this photo.
    func apply(_ metadata: PhotoCaptureMetadata) {
        latitude = metadata.latitude
        longitude = metadata.longitude
        altitude = metadata.altitude
        heading = metadata.heading
        orientation = metadata.orientation
        isPortrait = metadata.isPortrait
        captureDate = metadata.captureDate
        cameraMake = metadata.cameraMake
        cameraModel = metadata.cameraModel
        lensModel = metadata.lensModel
    }

    /// A short label combining part and side for display, or `nil` if not yet labeled.
    var label: String? {
        guard let part, !part.isEmpty else { return nil }
        if let side, !side.isEmpty, side != "Unknown" {
            return "\(part) • \(side)"
        }
        return part
    }
}
