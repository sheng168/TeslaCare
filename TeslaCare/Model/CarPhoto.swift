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

    var car: Car?

    init(data: Data, sortIndex: Int = 0) {
        self.data = data
        self.sortIndex = sortIndex
        self.createdAt = Date()
    }
}
