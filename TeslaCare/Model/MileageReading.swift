//
//  MileageReading.swift
//  TeslaCare
//

import Foundation
import SwiftData

@Model
final class MileageReading {
    var date: Date
    var mileage: Int
    var source: String  // "manual" or "tesla_api"

    var car: Car?

    init(date: Date, mileage: Int, source: String = "manual") {
        self.date = date
        self.mileage = mileage
        self.source = source
    }
}
