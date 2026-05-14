//
//  PublicCarRecord.swift
//  TeslaCare
//
//  Created by Jin on 5/14/26.
//

import Foundation
import CloudKit

enum ListingType: String, CaseIterable {
    case forSale = "For Sale"
    case rental  = "Rental"
}

struct PublicCarRecord: Identifiable {
    let id: String
    let name: String
    let make: String
    let model: String
    let year: Int
    let trimSummary: String?
    let vin: String?
    let mileage: Int?
    let tireHealthPercentage: Double?
    let averageTreadDepth: Double?
    let locationCity: String?
    let listingType: ListingType?
    let listingURL: URL?
    let publishedAt: Date

    var displayName: String {
        name.isEmpty ? "\(year) \(make) \(model)" : name
    }

    init(id: String, name: String, make: String, model: String, year: Int,
         trimSummary: String?, vin: String?, mileage: Int?,
         tireHealthPercentage: Double?, averageTreadDepth: Double?,
         locationCity: String?, listingType: ListingType?, listingURL: URL?,
         publishedAt: Date) {
        self.id = id
        self.name = name
        self.make = make
        self.model = model
        self.year = year
        self.trimSummary = trimSummary
        self.vin = vin
        self.mileage = mileage
        self.tireHealthPercentage = tireHealthPercentage
        self.averageTreadDepth = averageTreadDepth
        self.locationCity = locationCity
        self.listingType = listingType
        self.listingURL = listingURL
        self.publishedAt = publishedAt
    }

    init(from record: CKRecord) {
        id = record.recordID.recordName
        name = record["name"] as? String ?? ""
        make = record["make"] as? String ?? ""
        model = record["model"] as? String ?? ""
        year = (record["year"] as? NSNumber)?.intValue ?? 0
        trimSummary = record["trimSummary"] as? String
        vin = record["vin"] as? String
        mileage = (record["mileage"] as? NSNumber)?.intValue
        tireHealthPercentage = record["tireHealthPercentage"] as? Double
        averageTreadDepth = record["averageTreadDepth"] as? Double
        locationCity = record["locationCity"] as? String
        listingType = (record["listingType"] as? String).flatMap { ListingType(rawValue: $0) }
        listingURL = (record["listingURL"] as? String).flatMap { URL(string: $0) }
        publishedAt = record.creationDate ?? Date()
    }
}
