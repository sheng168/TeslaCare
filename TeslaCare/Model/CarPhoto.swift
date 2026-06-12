//
//  CarPhoto.swift
//  TeslaCare
//

import Foundation
import SwiftData

@Model
final class CarPhoto {
    var data: Data = Data()
    var sortIndex: Int = 0
    var createdAt: Date = Date()

    /// The car part/area shown, identified on-device by FoundationModels (e.g. "Front Bumper").
    var part: String?
    /// The side of the car the photo represents (e.g. "Front Left").
    var side: String?

    var car: Car?

    init(data: Data, sortIndex: Int = 0) {
        self.data = data
        self.sortIndex = sortIndex
        self.createdAt = Date()
    }

    /// A short label combining part and side for display, or `nil` if not yet labeled.
    var label: String? {
        guard let part, !part.isEmpty else { return nil }
        if let side, !side.isEmpty, side != "Unknown" {
            return "\(part) • \(side)"
        }
        return part
    }
}
