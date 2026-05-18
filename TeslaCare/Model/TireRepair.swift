//
//  TireRepair.swift
//  TeslaCare
//

import Foundation
import SwiftData

enum TireRepairType: String, CaseIterable, Codable {
    case plug = "Plug"
    case patch = "Patch"
    case patchPlug = "Patch + Plug"

    var systemImage: String {
        switch self {
        case .plug: return "wrench.fill"
        case .patch: return "bandage.fill"
        case .patchPlug: return "wrench.and.screwdriver.fill"
        }
    }
}

@Model
final class TireRepairEvent {
    var date: Date = Date()
    var repairTypeRaw: String = TireRepairType.plug.rawValue
    var positionRaw: String = TirePosition.frontLeft.rawValue
    var shopName: String = ""
    var cost: Double?
    var mileage: Int?
    var notes: String = ""

    var car: Car?
    var tire: Tire?

    @Relationship(deleteRule: .cascade, inverse: \TireRepairPhoto.repairEvent)
    var photos: [TireRepairPhoto]?

    init(date: Date, repairType: TireRepairType, position: TirePosition,
         shopName: String = "", cost: Double? = nil, mileage: Int? = nil, notes: String = "") {
        self.date = date
        self.repairTypeRaw = repairType.rawValue
        self.positionRaw = position.rawValue
        self.shopName = shopName
        self.cost = cost
        self.mileage = mileage
        self.notes = notes
    }

    var repairType: TireRepairType {
        get { TireRepairType(rawValue: repairTypeRaw) ?? .plug }
        set { repairTypeRaw = newValue.rawValue }
    }

    var position: TirePosition {
        get { TirePosition(rawValue: positionRaw) ?? .frontLeft }
        set { positionRaw = newValue.rawValue }
    }

    var repairDescription: String {
        "\(repairType.rawValue) – \(position.rawValue)"
    }
}

@Model
final class TireRepairPhoto {
    var data: Data = Data()
    var sortIndex: Int = 0
    var createdAt: Date = Date()

    var repairEvent: TireRepairEvent?

    init(data: Data, sortIndex: Int = 0) {
        self.data = data
        self.sortIndex = sortIndex
        self.createdAt = Date()
    }
}
