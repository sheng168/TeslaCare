//
//  NearbyCharger.swift
//  TeslaCare
//
//  Created by Jin on 5/10/26.
//

import Foundation
import SwiftData

@Model
final class NearbyCharger {
    var name: String = ""
    var chargerType: String = ""   // "supercharger" or "destination"
    var rawType: String?           // raw type string from Tesla API (e.g. "supercharger_v3")
    var latitude: Double?           // decimal degrees
    var longitude: Double?          // decimal degrees
    var distanceMiles: Double = 0   // miles
    var availableStalls: Int?
    var totalStalls: Int?
    var siteClosed: Bool = false
    var updatedAt: Date = Date()

    var car: Car?

    init(name: String, chargerType: String, rawType: String? = nil, latitude: Double?, longitude: Double?,
         distanceMiles: Double, availableStalls: Int?, totalStalls: Int?, siteClosed: Bool) {
        self.name = name
        self.chargerType = chargerType
        self.rawType = rawType
        self.latitude = latitude
        self.longitude = longitude
        self.distanceMiles = distanceMiles
        self.availableStalls = availableStalls
        self.totalStalls = totalStalls
        self.siteClosed = siteClosed
    }

    /// Inferred max power based on the raw type string returned by the Tesla API.
    var estimatedMaxPowerKW: Int? {
        guard let t = rawType?.lowercased() else { return nil }
        if t.contains("v4") { return 500 }
        if t.contains("v3") { return 250 }
        if t.contains("urban") { return 72 }
        if t.contains("v2") || t.contains("v1") { return 150 }
        return nil
    }
}
