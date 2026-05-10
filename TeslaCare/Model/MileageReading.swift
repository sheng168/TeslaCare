//
//  MileageReading.swift
//  TeslaCare
//

import Foundation
import SwiftData

@Model
final class MileageReading {
    var date: Date = Date()
    var mileage: Int = 0
    var source: String = "manual"  // "manual" or "tesla_api"

    var car: Car?

    init(date: Date, mileage: Int, source: String = "manual") {
        self.date = date
        self.mileage = mileage
        self.source = source
    }
}
