//
//  TireReplacement.swift
//  TeslaCare
//
//  Created by Jin on 5/7/26.
//

import Foundation
import SwiftData

// MARK: - Tire Replacement Event Model
@Model
final class TireReplacementEvent {
    var date: Date = Date()
    var mileage: Int?       // miles
    var notes: String = ""
    var brand: String = ""
    var modelName: String = ""
    var cost: Double?       // USD

    // Which tires were replaced
    var replacedFrontLeft: Bool = false
    var replacedFrontRight: Bool = false
    var replacedRearLeft: Bool = false
    var replacedRearRight: Bool = false
    
    var car: Car?
    
    init(date: Date, positions: [TirePosition], brand: String = "", modelName: String = "", mileage: Int? = nil, cost: Double? = nil, notes: String = "") {
        self.date = date
        self.mileage = mileage
        self.notes = notes
        self.brand = brand
        self.modelName = modelName
        self.cost = cost
        
        self.replacedFrontLeft = positions.contains(.frontLeft)
        self.replacedFrontRight = positions.contains(.frontRight)
        self.replacedRearLeft = positions.contains(.rearLeft)
        self.replacedRearRight = positions.contains(.rearRight)
    }
    
    var replacedPositions: [TirePosition] {
        var positions: [TirePosition] = []
        if replacedFrontLeft { positions.append(.frontLeft) }
        if replacedFrontRight { positions.append(.frontRight) }
        if replacedRearLeft { positions.append(.rearLeft) }
        if replacedRearRight { positions.append(.rearRight) }
        return positions
    }
    
    var replacedCount: Int {
        replacedPositions.count
    }
    
    var replacementDescription: String {
        switch replacedCount {
        case 1:
            return "Replaced 1 tire"
        case 2:
            let isFrontPair = replacedFrontLeft && replacedFrontRight
            let isRearPair = replacedRearLeft && replacedRearRight
            if isFrontPair {
                return "Replaced front tires"
            } else if isRearPair {
                return "Replaced rear tires"
            } else {
                return "Replaced 2 tires"
            }
        case 3:
            return "Replaced 3 tires"
        case 4:
            return "Replaced all 4 tires"
        default:
            return "No tires replaced"
        }
    }
}
