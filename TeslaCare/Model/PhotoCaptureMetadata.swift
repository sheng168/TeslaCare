//
//  PhotoCaptureMetadata.swift
//  TeslaCare
//

import Foundation
import ImageIO
import CoreLocation
import UIKit

/// Capture metadata for a photo, parsed from a file's embedded EXIF/TIFF/GPS dictionaries
/// or supplied from live device sensors. iOS strips GPS from `UIImagePickerController`
/// camera captures, so for those the location/heading are filled from `LocationManager`.
struct PhotoCaptureMetadata: Equatable {
    var latitude: Double?
    var longitude: Double?
    var altitude: Double?
    /// Compass direction the camera faced, in degrees (0 = true north).
    var heading: Double?
    /// EXIF orientation tag (1–8) describing how the image should be rotated for display.
    var orientation: Int?
    /// Whether the capture is portrait (taller than wide) once orientation is applied.
    var isPortrait: Bool?
    var captureDate: Date?
    var cameraMake: String?
    var cameraModel: String?
    var lensModel: String?

    var hasLocation: Bool { latitude != nil && longitude != nil }

    var coordinate: CLLocationCoordinate2D? {
        guard let latitude, let longitude else { return nil }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

extension PhotoCaptureMetadata {
    /// Parses an image-properties dictionary as produced by `CGImageSourceCopyPropertiesAtIndex`
    /// or `UIImagePickerController`'s `.mediaMetadata`. GPS data is absent from camera captures.
    init(imageProperties properties: [String: Any]) {
        if let o = properties[kCGImagePropertyOrientation as String] as? Int {
            orientation = o
        }

        let pixelWidth = properties[kCGImagePropertyPixelWidth as String] as? Double
        let pixelHeight = properties[kCGImagePropertyPixelHeight as String] as? Double
        if let pixelWidth, let pixelHeight {
            // EXIF orientations 5–8 rotate by 90°, swapping the displayed aspect ratio.
            let rotated = (orientation ?? 1) >= 5
            let displayWidth = rotated ? pixelHeight : pixelWidth
            let displayHeight = rotated ? pixelWidth : pixelHeight
            isPortrait = displayHeight >= displayWidth
        }

        if let gps = properties[kCGImagePropertyGPSDictionary as String] as? [String: Any] {
            if let lat = gps[kCGImagePropertyGPSLatitude as String] as? Double {
                let ref = gps[kCGImagePropertyGPSLatitudeRef as String] as? String
                latitude = (ref == "S") ? -lat : lat
            }
            if let lon = gps[kCGImagePropertyGPSLongitude as String] as? Double {
                let ref = gps[kCGImagePropertyGPSLongitudeRef as String] as? String
                longitude = (ref == "W") ? -lon : lon
            }
            if let alt = gps[kCGImagePropertyGPSAltitude as String] as? Double {
                // AltitudeRef 1 means below sea level.
                let ref = gps[kCGImagePropertyGPSAltitudeRef as String] as? Int
                altitude = (ref == 1) ? -alt : alt
            }
            if let direction = gps[kCGImagePropertyGPSImgDirection as String] as? Double {
                heading = direction
            }
        }

        if let exif = properties[kCGImagePropertyExifDictionary as String] as? [String: Any] {
            if let dateString = exif[kCGImagePropertyExifDateTimeOriginal as String] as? String {
                captureDate = Self.exifDateFormatter.date(from: dateString)
            }
            lensModel = exif[kCGImagePropertyExifLensModel as String] as? String
        }

        if let tiff = properties[kCGImagePropertyTIFFDictionary as String] as? [String: Any] {
            cameraMake = tiff[kCGImagePropertyTIFFMake as String] as? String
            cameraModel = tiff[kCGImagePropertyTIFFModel as String] as? String
            if orientation == nil, let o = tiff[kCGImagePropertyTIFFOrientation as String] as? Int {
                orientation = o
            }
        }
    }

    /// Reads metadata directly from encoded image data, preserving any embedded EXIF/GPS.
    init?(imageData data: Data) {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any]
        else { return nil }
        self.init(imageProperties: properties)
    }

    /// Fills orientation/aspect from a decoded image when the source carried none (e.g. camera).
    mutating func fillOrientation(from image: UIImage) {
        if orientation == nil {
            orientation = Self.exifOrientation(from: image.imageOrientation)
        }
        if isPortrait == nil {
            isPortrait = image.size.height >= image.size.width
        }
    }

    /// Overlays live device location/heading, used for camera captures that lack embedded GPS.
    mutating func fillLocation(from location: CLLocation?, heading deviceHeading: Double?) {
        guard let location else {
            if heading == nil { heading = deviceHeading }
            return
        }
        if latitude == nil { latitude = location.coordinate.latitude }
        if longitude == nil { longitude = location.coordinate.longitude }
        if altitude == nil { altitude = location.altitude }
        if heading == nil { heading = deviceHeading }
    }

    private static func exifOrientation(from orientation: UIImage.Orientation) -> Int {
        switch orientation {
        case .up: return 1
        case .upMirrored: return 2
        case .down: return 3
        case .downMirrored: return 4
        case .leftMirrored: return 5
        case .right: return 6
        case .rightMirrored: return 7
        case .left: return 8
        @unknown default: return 1
        }
    }

    private static let exifDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
}
