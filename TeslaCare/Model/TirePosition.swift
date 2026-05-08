//
//  TirePosition.swift
//  TeslaCare
//
//  Created by Jin on 5/7/26.
//

import Foundation

// MARK: - Tire Position Enum
enum TirePosition: String, Codable, CaseIterable {
    case frontLeft = "Front Left"
    case frontRight = "Front Right"
    case rearLeft = "Rear Left"
    case rearRight = "Rear Right"
    
    var systemImage: String {
        switch self {
        case .frontLeft: return "arrow.up.left"
        case .frontRight: return "arrow.up.right"
        case .rearLeft: return "arrow.down.left"
        case .rearRight: return "arrow.down.right"
        }
    }
}
