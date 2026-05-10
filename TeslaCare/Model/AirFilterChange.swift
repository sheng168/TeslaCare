//
//  AirFilterChange.swift
//  TeslaCare
//
//  Created by Jin on 5/7/26.
//

import Foundation
import SwiftData

// MARK: - Air Filter Type
enum AirFilterType: String, Codable, CaseIterable {
    case engine = "Engine Air Filter"
    case cabin = "Cabin Air Filter"
    case both = "Both Filters"
    
    var systemImage: String {
        switch self {
        case .engine: return "fanblades.fill"
        case .cabin: return "air.purifier.fill"
        case .both: return "arrow.triangle.2.circlepath"
        }
    }
    
    var description: String {
        switch self {
        case .engine:
            return "Filters air entering the engine for combustion"
        case .cabin:
            return "Filters air entering the vehicle cabin for passengers"
        case .both:
            return "Both engine and cabin air filters"
        }
    }
}

// MARK: - Air Filter Change Event Model
@Model
final class AirFilterChangeEvent {
    var date: Date = Date()
    var filterTypeRaw: String = "Cabin Air Filter"
    var mileage: Int?
    var brand: String = ""
    var partNumber: String = ""
    var cost: Double?
    var notes: String = ""
    
    var car: Car?
    
    init(date: Date, filterType: AirFilterType, mileage: Int? = nil, brand: String = "", partNumber: String = "", cost: Double? = nil, notes: String = "") {
        self.date = date
        self.filterTypeRaw = filterType.rawValue
        self.mileage = mileage
        self.brand = brand
        self.partNumber = partNumber
        self.cost = cost
        self.notes = notes
    }
    
    var filterType: AirFilterType {
        get { AirFilterType(rawValue: filterTypeRaw) ?? .cabin }
        set { filterTypeRaw = newValue.rawValue }
    }
    
    var changeDescription: String {
        if !brand.isEmpty {
            return "\(filterType.rawValue) - \(brand)"
        }
        return filterType.rawValue
    }
}
