//
//  TireImageProcessor.swift
//  TeslaCare
//

import Vision
import UIKit
import OSLog

private let logger = Logger(subsystem: "com.teslacare", category: "ImageProcessing")

enum TireImageProcessor {

    /// Detects the tire/rim in the image and returns a cropped, centered version.
    /// Falls back to attention saliency, then the original if detection fails.
    @MainActor
    static func process(_ image: UIImage) async -> UIImage {
        logger.info("Processing tire image: \(Int(image.size.width))x\(Int(image.size.height))")
        let normalized = normalize(image)
        let result = await Task.detached(priority: .userInitiated) {
            rimCrop(normalized) ?? saliencyCrop(normalized) ?? normalized
        }.value
        logger.info("Image processing complete")
        return result
    }

    // MARK: - Image normalization

    private static func normalize(_ image: UIImage) -> UIImage {
        guard image.imageOrientation != .up else { return image }
        let renderer = UIGraphicsImageRenderer(size: image.size)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
    }

    // MARK: - Rim detection via contour bounding circles

    private nonisolated static func rimCrop(_ image: UIImage) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }

        let request = VNDetectContoursRequest()
        request.contrastAdjustment = 3.0
        request.maximumImageDimension = 512

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        guard (try? handler.perform([request])) != nil,
              let observation = request.results?.first as? VNContoursObservation else { return nil }

        var bestCircle: VNCircle?
        var bestScore: Double = 0

        for i in 0..<observation.topLevelContourCount {
            guard let contour = try? observation.contour(at: i),
                  contour.pointCount > 20 else { continue }

            let ar = Double(contour.aspectRatio)
            // Rims appear as circles or slight ellipses due to perspective
            guard ar > 0.5 && ar < 2.0 else { continue }

            guard let circle = try? VNGeometryUtils.boundingCircle(for: contour),
                  circle.radius > 0.08 else { continue }

            // Prefer large, circular contours
            let circularityBonus = 1.0 - abs(ar - 1.0)
            let score = circle.radius * (0.5 + 0.5 * circularityBonus)
            if score > bestScore {
                bestScore = score
                bestCircle = circle
            }
        }

        guard let circle = bestCircle else { return nil }
        return crop(to: circle, in: image)
    }

    private nonisolated static func crop(to circle: VNCircle, in image: UIImage) -> UIImage? {
        let size = image.size
        let scale = image.scale

        // Vision: Y=0 at bottom → flip for UIKit Y=0 at top
        let cx = circle.center.x * size.width
        let cy = (1.0 - circle.center.y) * size.height
        let r  = circle.radius * min(size.width, size.height)
        let half = r * 1.3 // 30% padding around rim

        let cropRect = CGRect(x: cx - half, y: cy - half, width: half * 2, height: half * 2)
            .intersection(CGRect(origin: .zero, size: size))
        guard !cropRect.isNull, cropRect.width > 10 else { return nil }

        let pixelRect = cropRect.applying(CGAffineTransform(scaleX: scale, y: scale))
        guard let cropped = image.cgImage?.cropping(to: pixelRect) else { return nil }
        return UIImage(cgImage: cropped, scale: scale, orientation: .up)
    }

    // MARK: - Fallback: attention saliency crop

    private nonisolated static func saliencyCrop(_ image: UIImage) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }

        let request = VNGenerateAttentionBasedSaliencyImageRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        guard (try? handler.perform([request])) != nil,
              let obs = request.results?.first as? VNSaliencyImageObservation,
              let objects = obs.salientObjects,
              let bb = objects.first?.boundingBox else { return nil }

        let size = image.size
        let scale = image.scale

        // Convert Vision normalized rect (Y=0 at bottom) to UIKit space
        let uiRect = CGRect(
            x: bb.origin.x * size.width,
            y: (1.0 - bb.origin.y - bb.height) * size.height,
            width: bb.width * size.width,
            height: bb.height * size.height
        )

        // Add padding and make square so the crop looks centred
        let squareSize = max(uiRect.width, uiRect.height) * 1.25
        let cropRect = CGRect(
            x: uiRect.midX - squareSize / 2,
            y: uiRect.midY - squareSize / 2,
            width: squareSize,
            height: squareSize
        ).intersection(CGRect(origin: .zero, size: size))
        guard !cropRect.isNull, cropRect.width > 10 else { return nil }

        let pixelRect = cropRect.applying(CGAffineTransform(scaleX: scale, y: scale))
        guard let cropped = image.cgImage?.cropping(to: pixelRect) else { return nil }
        return UIImage(cgImage: cropped, scale: scale, orientation: .up)
    }
}
