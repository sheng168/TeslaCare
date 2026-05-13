//
//  TireSpecsLoader.swift
//  TeslaCare
//

import Foundation
import OSLog

private let logger = Logger(subsystem: "com.teslacare", category: "Model")

// MARK: - Decodable models for TireSpecs.json

struct TireSpecs: Decodable {
    let version: String
    let globalThresholds: GlobalThresholds
    let models: [TireModelSpec]
}

struct GlobalThresholds: Decodable {
    let treadWarningDepth: Double
    let treadReplacementDepth: Double
    let psiLowWarningOffset: Double
    let psiHighWarningOffset: Double
    let psiCriticalLowOffset: Double
}

struct TireModelSpec: Decodable {
    let make: String
    let model: String
    let variants: [TireVariant]
}

struct TireVariant: Decodable, Identifiable {
    let id: String
    let name: String
    let wheelSizes: [String]
    let tireSizes: [String]
    let staggered: Bool
    let staggeredNote: String?
    let recommendedColdPsi: TirePsi
    let psiWarning: TirePsiWarning
    let defaultNewTreadDepth: Double
    let notes: String?
    let commonOemTires: [String]
}

struct TirePsi: Decodable {
    let front: Double
    let rear: Double
}

struct TirePsiWarning: Decodable {
    let low: Double
    let high: Double
    let criticalLow: Double
}

// MARK: - Loader

enum TireSpecsLoader {
    static let shared: TireSpecs? = {
        guard let url = Bundle.main.url(forResource: "TireSpecs", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            logger.error("TireSpecs.json not found in bundle")
            return nil
        }
        guard let specs = try? JSONDecoder().decode(TireSpecs.self, from: data) else {
            logger.error("Failed to decode TireSpecs.json")
            return nil
        }
        logger.info("TireSpecs loaded: \(specs.models.count) model(s), version=\(specs.version)")
        return specs
    }()

    static func variants(for car: Car) -> [TireVariant] {
        let result = shared?.models
            .first {
                $0.make.lowercased() == car.make.lowercased() &&
                $0.model.lowercased() == car.model.lowercased()
            }?
            .variants ?? []
        logger.info("variants(for:) car=\(car.displayName), found \(result.count) variant(s)")
        return result
    }
}
