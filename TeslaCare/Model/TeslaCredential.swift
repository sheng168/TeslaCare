//
//  TeslaCredential.swift
//  TeslaCare
//
//  Created by Jin on 5/10/26.
//

import Foundation
import SwiftData

@Model
final class TeslaCredential {
    var accessToken: String?
    var refreshToken: String?
    var tokenExpiry: Double?

    init() {}
}
