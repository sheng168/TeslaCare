//
//  CloudKitPublicService.swift
//  TeslaCare
//
//  Created by Jin on 5/14/26.
//

import Foundation
import CloudKit
import CoreLocation
import MapKit
import OSLog

private let logger = Logger(subsystem: "com.teslacare", category: "CloudKit")

@Observable
final class CloudKitPublicService {
    var publicCars: [PublicCarRecord] = []
    var isLoading = false

    private let container = CKContainer(identifier: "iCloud.us.jsy.TeslaCare")
    private var publicDB: CKDatabase { container.publicCloudDatabase }

    /// Publishes car info to the public CloudKit database. Uses VIN as a stable record ID when available
    /// so re-publishing updates the existing record instead of creating a duplicate.
    @MainActor
    func publishCar(_ car: Car, listingType: ListingType, listingURL: URL?, hasFSD: Bool, freeSupercharging: Bool) async throws {
        let recordName: String
        if let vin = car.vin, !vin.isEmpty {
            recordName = "car-\(vin)"
        } else if let existing = car.cloudKitRecordName {
            recordName = existing
        } else {
            recordName = "car-\(UUID().uuidString)"
        }

        let recordID = CKRecord.ID(recordName: recordName)
        let record = CKRecord(recordType: "PublicCar", recordID: recordID)
        applyFields(of: car, listingType: listingType, listingURL: listingURL, hasFSD: hasFSD, freeSupercharging: freeSupercharging, to: record)
        if let city = await approximateCity(for: car) { record["locationCity"] = city as CKRecordValue }

        do {
            _ = try await publicDB.save(record)
        } catch let ckError as CKError where ckError.code == .serverRecordChanged {
            // Record already exists — fetch server copy, update fields, re-save
            guard let serverRecord = ckError.serverRecord else { throw ckError }
            applyFields(of: car, listingType: listingType, listingURL: listingURL, hasFSD: hasFSD, freeSupercharging: freeSupercharging, to: serverRecord)
            if let city = record["locationCity"] as? String { serverRecord["locationCity"] = city as CKRecordValue }
            _ = try await publicDB.save(serverRecord)
        }

        car.cloudKitRecordName = recordName
        logger.info("Car published: \(recordName)")
    }

    private func applyFields(of car: Car, listingType: ListingType, listingURL: URL?, hasFSD: Bool, freeSupercharging: Bool, to record: CKRecord) {
        record["name"] = car.displayName as CKRecordValue
        record["make"] = car.make as CKRecordValue
        record["model"] = car.model as CKRecordValue
        record["year"] = NSNumber(value: car.year)
        record["listingType"] = listingType.rawValue as CKRecordValue
        if let trim = car.drivetrainSummary { record["trimSummary"] = trim as CKRecordValue }
        if let vin = car.vin, !vin.isEmpty { record["vin"] = vin as CKRecordValue }
        if let mileage = car.mileage { record["mileage"] = NSNumber(value: mileage) }
        if let health = car.tireHealthPercentage { record["tireHealthPercentage"] = health as CKRecordValue }
        if let depth = car.averageTreadDepth { record["averageTreadDepth"] = depth as CKRecordValue }
        if let url = listingURL { record["listingURL"] = url.absoluteString as CKRecordValue }
        record["hasFSD"] = NSNumber(value: hasFSD)
        record["freeSupercharging"] = NSNumber(value: freeSupercharging)
    }

    @MainActor
    func unpublishCar(_ car: Car) async throws {
        guard let recordName = car.cloudKitRecordName else { return }
        let recordID = CKRecord.ID(recordName: recordName)
        try await publicDB.deleteRecord(withID: recordID)
        car.cloudKitRecordName = nil
        logger.info("Car unpublished: \(recordName)")
    }

    private func approximateCity(for car: Car) async -> String? {
        guard let lat = car.latitude, let lon = car.longitude else { return nil }
        let location = CLLocation(latitude: lat, longitude: lon)
        guard let request = MKReverseGeocodingRequest(location: location) else { return nil }
        return await withCheckedContinuation { continuation in
            request.getMapItems { mapItems, _ in
                continuation.resume(returning: mapItems?.first?.addressRepresentations?.cityWithContext)
            }
        }
    }

    @MainActor
    func fetchPublicCars() async {
        isLoading = true
        defer { isLoading = false }

        let query = CKQuery(recordType: "PublicCar", predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

        do {
            let (results, _) = try await publicDB.records(matching: query, resultsLimit: 50)
            publicCars = results.compactMap { (_, result) in
                (try? result.get()).map { PublicCarRecord(from: $0) }
            }
            logger.info("Fetched \(self.publicCars.count) public cars")
        } catch {
            logger.error("Fetch failed: \(error)")
        }
    }
}
