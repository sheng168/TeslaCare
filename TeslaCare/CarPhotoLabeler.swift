//
//  CarPhotoLabeler.swift
//  TeslaCare
//

import Foundation
import UIKit
import OSLog

/// A part/side label produced for a car photo.
struct CarPartLabel: Equatable {
    var part: String
    var side: String

    /// Combined display string, e.g. "Front Bumper • Front Left".
    var caption: String {
        if side.isEmpty || side == "Unknown" { return part }
        return "\(part) • \(side)"
    }
}

#if canImport(FoundationModels)
import FoundationModels

/// Identifies the part and side of a car shown in a photo using the on-device
/// FoundationModels system model. Image input requires iOS 27+.
@available(iOS 27, *)
enum CarPhotoLabeler {
    private static let logger = Logger(subsystem: "com.teslacare", category: "CarPhotoLabeler")

    /// Structured result the model is guided to produce for each photo.
    @Generable
    struct Label {
        @Guide(description: "The specific exterior or interior part or area of the car shown, in one to three words. Examples: Front Bumper, Hood, Driver Door, Front Wheel, Headlight, Tail Light, Trunk, Side Mirror, Windshield, Charging Port, Dashboard, Seats. Use Unknown if it is not a car.")
        var part: String

        @Guide(description: "Which side of the car the photo shows or is taken from.")
        var side: CarSide
    }

    @Generable
    enum CarSide {
        case front
        case rear
        case left
        case right
        case frontLeft
        case frontRight
        case rearLeft
        case rearRight
        case interior
        case unknown

        var displayName: String {
            switch self {
            case .front: "Front"
            case .rear: "Rear"
            case .left: "Left"
            case .right: "Right"
            case .frontLeft: "Front Left"
            case .frontRight: "Front Right"
            case .rearLeft: "Rear Left"
            case .rearRight: "Rear Right"
            case .interior: "Interior"
            case .unknown: "Unknown"
            }
        }
    }

    /// Whether on-device labeling is currently possible.
    static var isAvailable: Bool {
        if case .available = SystemLanguageModel.default.availability { return true }
        return false
    }

    /// Runs the on-device model to identify the part and side shown in a car photo.
    /// Returns `nil` when the model is unavailable or generation fails.
    static func label(_ image: UIImage) async -> CarPartLabel? {
        guard isAvailable else {
            logger.info("System language model unavailable; skipping photo labeling")
            return nil
        }
        let session = LanguageModelSession(model: PrivateCloudComputeLanguageModel(),
            instructions: """
            You identify cars in photos. Given a photo of a car, name the specific part \
            or area of the car shown and which side of the car the photo represents. \
            Keep the part name to one to three words. If you cannot tell, use Unknown.
            """
        )
        do {
            let response = try await session.respond(generating: Label.self) {
                "Identify the car part and the side of the car shown in this photo."
                Attachment(image)
            }
            let part = response.content.part.trimmingCharacters(in: .whitespacesAndNewlines)
            let label = CarPartLabel(part: part, side: response.content.side.displayName)
            logger.info("Labeled car photo: \(label.caption, privacy: .public)")
            return label
        } catch {
            logger.error("Car photo labeling failed: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    /// Labels a persisted photo in place, writing the result back to the model.
    @MainActor
    static func applyLabel(to photo: CarPhoto) async {
        guard photo.part == nil, let image = UIImage(data: photo.data) else { return }
        guard let result = await label(image) else { return }
        photo.part = result.part
        photo.side = result.side
    }
}
#endif
