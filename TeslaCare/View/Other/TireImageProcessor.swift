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

// MARK: - Coin tread analysis types

enum CoinType: String, CaseIterable {
    case quarter = "Quarter"
    case penny = "Penny"

    var diameterMM: Double {
        switch self {
        case .quarter: return 24.26
        case .penny:   return 19.05
        }
    }
}

struct CoinTreadResult {
    let estimatedDepth: Double  // 32nds of an inch
    let confidence: Double      // 0.0 to 1.0
    let coinType: CoinType

    var confidenceLabel: String {
        if confidence >= 0.75 { return "High confidence" }
        if confidence >= 0.5  { return "Medium confidence" }
        return "Low confidence — please verify"
    }

    var depthCategory: String {
        if estimatedDepth <= 2.0 { return "Replace Now" }
        if estimatedDepth <= 4.0 { return "Monitor Closely" }
        return "Good"
    }

    var depthFormatted: String {
        String(format: "~%.1f/32\"", estimatedDepth)
    }
}

// MARK: - Coin tread analysis

extension TireImageProcessor {

    /// Analyzes a side-on photo of a coin inserted in a tread groove.
    /// The hidden portion of the coin (below the tread surface) equals the tread depth.
    @MainActor
    static func analyzeCoinTread(_ image: UIImage, coinType: CoinType) async -> CoinTreadResult? {
        let normalized = normalize(image)
        let diameterMM = coinType.diameterMM  // Read on main actor before detached task
        return await Task.detached(priority: .userInitiated) {
            coinTreadAnalysis(normalized, coinType: coinType, diameterMM: diameterMM)
        }.value
    }

    private nonisolated static func coinTreadAnalysis(_ image: UIImage, coinType: CoinType, diameterMM: Double) -> CoinTreadResult? {
        guard let cgImage = image.cgImage else { return nil }
        guard let coinCircle = detectCoin(in: cgImage) else { return nil }

        let imgW = Double(cgImage.width)
        let imgH = Double(cgImage.height)
        let minDim = min(imgW, imgH)
        let coinRadiusPx = coinCircle.radius * minDim
        let centerX = coinCircle.center.x * imgW
        let centerY = (1.0 - coinCircle.center.y) * imgH  // Flip Vision Y→image Y

        let cropRect = CGRect(
            x: centerX - coinRadiusPx,
            y: centerY - coinRadiusPx,
            width: coinRadiusPx * 2,
            height: coinRadiusPx * 2
        ).intersection(CGRect(x: 0, y: 0, width: imgW, height: imgH))

        guard !cropRect.isNull, cropRect.height > 20 else { return nil }
        guard let rows = grayscaleRows(of: cgImage, in: cropRect), rows.count > 6 else { return nil }

        // Boundary is where coin transitions from visible face → hidden in groove (dark rubber)
        let (boundaryRow, confidence) = findTreadBoundary(in: rows)

        // Hidden fraction = rows below boundary / total rows (coin goes into groove at bottom)
        let hiddenFraction = max(0, min(0.5, Double(rows.count - boundaryRow) / Double(rows.count)))
        let treadDepthMM = hiddenFraction * diameterMM
        let depth32nds = (treadDepthMM / 0.79375 * 2).rounded() / 2  // Round to nearest 0.5
        let clampedDepth = max(0, min(12, depth32nds))

        return CoinTreadResult(estimatedDepth: clampedDepth, confidence: confidence, coinType: coinType)
    }

    private nonisolated static func detectCoin(in cgImage: CGImage) -> VNCircle? {
        let request = VNDetectContoursRequest()
        request.contrastAdjustment = 2.5
        request.maximumImageDimension = 512

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        guard (try? handler.perform([request])) != nil,
              let observation = request.results?.first as? VNContoursObservation else { return nil }

        var bestCircle: VNCircle?
        var bestScore: Double = 0

        for i in 0..<observation.topLevelContourCount {
            guard let contour = try? observation.contour(at: i),
                  contour.pointCount > 12 else { continue }
            let ar = Double(contour.aspectRatio)
            guard ar > 0.5 && ar < 2.0 else { continue }
            guard let circle = try? VNGeometryUtils.boundingCircle(for: contour),
                  circle.radius > 0.04 && circle.radius < 0.48 else { continue }
            let score = max(0, 1.0 - abs(ar - 1.0)) * 0.6 + circle.radius * 0.4
            if score > bestScore { bestScore = score; bestCircle = circle }
        }

        return bestScore > 0.04 ? bestCircle : nil
    }

    // Renders a crop of cgImage into a grayscale bitmap and returns per-row average luminance.
    private nonisolated static func grayscaleRows(of cgImage: CGImage, in cropRect: CGRect) -> [Double]? {
        guard let cropped = cgImage.cropping(to: cropRect) else { return nil }
        let w = cropped.width, h = cropped.height
        guard w > 0, h > 0 else { return nil }

        var pixels = [UInt8](repeating: 0, count: w * h)
        guard let ctx = CGContext(
            data: &pixels, width: w, height: h,
            bitsPerComponent: 8, bytesPerRow: w,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else { return nil }

        ctx.draw(cropped, in: CGRect(x: 0, y: 0, width: w, height: h))

        return (0..<h).map { y in
            (0..<w).reduce(0.0) { $0 + Double(pixels[y * w + $1]) } / Double(w)
        }
    }

    // Finds the row with the largest bright→dark transition in the lower half of the coin region.
    private nonisolated static func findTreadBoundary(in rows: [Double]) -> (index: Int, confidence: Double) {
        guard rows.count > 6 else { return (rows.count - 1, 0.2) }
        let searchStart = rows.count / 2
        let smoothing = max(2, rows.count / 10)
        var maxDrop = 0.0
        var boundaryIndex = rows.count - 1

        for i in searchStart..<(rows.count - smoothing) {
            let above = rows[max(0, i - smoothing)..<i].reduce(0, +) / Double(smoothing)
            let below = rows[i..<min(rows.count, i + smoothing)].reduce(0, +) / Double(smoothing)
            let drop = above - below  // Positive when transitioning from bright coin to dark groove
            if drop > maxDrop { maxDrop = drop; boundaryIndex = i }
        }

        let confidence: Double
        switch maxDrop {
        case ..<10:   confidence = 0.25
        case 10..<25: confidence = 0.5
        case 25..<45: confidence = 0.75
        default:      confidence = 0.9
        }
        return (boundaryIndex, confidence)
    }
}
