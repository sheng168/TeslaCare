//
//  TireRotation.swift
//  TeslaCare
//
//  Created by Jin on 5/7/26.
//

import Foundation
import SwiftData

// MARK: - Tire Rotation Pattern
enum TireRotationPattern: String, Codable, CaseIterable {
    case frontToBack = "Front to Back"
    case xPattern = "X-Pattern"
    case rearward = "Rearward Cross"
    case forward = "Forward Cross"
    
    var description: String {
        switch self {
        case .frontToBack:
            return "Front tires move straight back, rear tires move straight forward"
        case .xPattern:
            return "Front left → Rear right, Front right → Rear left, Rear left → Front right, Rear right → Front left"
        case .rearward:
            return "Front tires cross to rear, rear tires move straight forward"
        case .forward:
            return "Rear tires cross to front, front tires move straight back"
        }
    }
    
    var systemImage: String {
        switch self {
        case .frontToBack: return "arrow.up.arrow.down"
        case .xPattern: return "xmark"
        case .rearward: return "arrow.down.backward.and.arrow.up.forward"
        case .forward: return "arrow.up.backward.and.arrow.down.forward"
        }
    }
    
    /// Returns a dictionary mapping old position to new position
    func rotationMapping() -> [TirePosition: TirePosition] {
        switch self {
        case .frontToBack:
            return [
                .frontLeft: .rearLeft,
                .frontRight: .rearRight,
                .rearLeft: .frontLeft,
                .rearRight: .frontRight
            ]
        case .xPattern:
            return [
                .frontLeft: .rearRight,
                .frontRight: .rearLeft,
                .rearLeft: .frontRight,
                .rearRight: .frontLeft
            ]
        case .rearward:
            return [
                .frontLeft: .rearRight,
                .frontRight: .rearLeft,
                .rearLeft: .frontLeft,
                .rearRight: .frontRight
            ]
        case .forward:
            return [
                .frontLeft: .rearLeft,
                .frontRight: .rearRight,
                .rearLeft: .frontRight,
                .rearRight: .frontLeft
            ]
        }
    }
}

// MARK: - Tire Rotation Event Model
@Model
final class TireRotationEvent {
    var date: Date = Date()
    var patternRaw: String = "Front to Back"
    var mileage: Int?
    var notes: String = ""
    
    var car: Car?
    
    init(date: Date, pattern: TireRotationPattern, mileage: Int? = nil, notes: String = "") {
        self.date = date
        self.patternRaw = pattern.rawValue
        self.mileage = mileage
        self.notes = notes
    }
    
    var pattern: TireRotationPattern {
        get { TireRotationPattern(rawValue: patternRaw) ?? .frontToBack }
        set { patternRaw = newValue.rawValue }
    }
}
