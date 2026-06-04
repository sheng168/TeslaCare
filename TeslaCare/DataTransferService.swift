//
//  DataTransferService.swift
//  TeslaCare
//
//  Backup / restore for the local SwiftData store.
//  - JSON  → full-fidelity export & import (cars, tires, measurements, photos, events).
//  - CSV   → human-readable measurements table; export & import.
//

import Foundation
import SwiftData
import OSLog

private let logger = Logger(subsystem: "com.teslacare", category: "DataTransfer")

// MARK: - Errors

enum DataTransferError: LocalizedError {
    case emptyData
    case invalidFormat
    case notUTF8

    var errorDescription: String? {
        switch self {
        case .emptyData:     return "The file contains no records to import."
        case .invalidFormat: return "The file isn't a valid TezCare export."
        case .notUTF8:       return "The file could not be read as text."
        }
    }
}

// MARK: - Import summary

struct ImportSummary {
    var cars = 0
    var tires = 0
    var measurements = 0
    var events = 0          // rotation + replacement + air filter + repair
    var mileageReadings = 0
    var tpmsReadings = 0

    var description: String {
        var parts: [String] = []
        func add(_ count: Int, _ singular: String) {
            guard count > 0 else { return }
            parts.append("\(count) \(singular)\(count == 1 ? "" : "s")")
        }
        add(cars, "car")
        add(tires, "tire")
        add(measurements, "measurement")
        add(events, "event")
        add(mileageReadings, "mileage reading")
        add(tpmsReadings, "TPMS reading")
        if parts.isEmpty { return "Nothing to import — the file contained no records." }
        return "Imported " + parts.joined(separator: ", ") + "."
    }
}

// MARK: - Codable transfer objects

struct ExportDocument: Codable {
    var formatVersion: Int = 1
    var exportedAt: Date = Date()
    var appVersion: String?
    var cars: [CarDTO]
}

struct CarDTO: Codable {
    var name: String
    var make: String
    var model: String
    var year: Int
    var dateAdded: Date
    var vin: String?
    var trimBadging: String?
    var listingURL: String?
    var purchasePrice: Double?
    var hasFSD: Bool?
    var freeSupercharging: Bool?
    var perfConfig: String?
    var batteryLevel: Int?
    var chargingState: String?
    var latitude: Double?
    var longitude: Double?
    var heading: Double?
    var locationUpdatedAt: Date?

    var tires: [TireDTO]
    var measurements: [MeasurementDTO]
    var mileageReadings: [MileageReadingDTO]
    var tpmsReadings: [TPMSReadingDTO]
    var rotationEvents: [RotationEventDTO]
    var replacementEvents: [ReplacementEventDTO]
    var airFilterChanges: [AirFilterChangeDTO]
    var repairEvents: [RepairEventDTO]
}

struct TireDTO: Codable {
    /// Stable ID within this export, used to re-link measurements and repairs to their tire.
    var localID: String
    var brand: String
    var modelName: String
    var size: String
    var dotNumber: String
    var purchaseDate: Date
    var installDate: Date
    var initialTreadDepth: Double
    var purchasePrice: Double?
    var currentPosition: String
    var mileageAtInstall: Int?
    var notes: String
}

struct MeasurementDTO: Codable {
    var date: Date
    var treadDepth: Double
    var positionRaw: String
    var notes: String
    var mileage: Int?
    /// Multi-point depths ordered innermost → outermost. Preferred over the legacy
    /// inner/center/outer fields, which remain decodable for one release for compatibility.
    var treadDepths: [Double]?
    var innerTreadDepth: Double?
    var centerTreadDepth: Double?
    var outerTreadDepth: Double?
    var tireLocalID: String?
    var photos: [PhotoDTO]
}

struct PhotoDTO: Codable {
    var data: Data          // JSON-encoded as base64
    var sortIndex: Int
    var createdAt: Date
}

struct MileageReadingDTO: Codable {
    var date: Date
    var mileage: Int
    var source: String
}

struct TPMSReadingDTO: Codable {
    var date: Date
    var frontLeft: Double?
    var frontRight: Double?
    var rearLeft: Double?
    var rearRight: Double?
    var outsideTemperature: Double?
}

struct RotationEventDTO: Codable {
    var date: Date
    var patternRaw: String
    var mileage: Int?
    var notes: String
}

struct ReplacementEventDTO: Codable {
    var date: Date
    var mileage: Int?
    var notes: String
    var brand: String
    var modelName: String
    var cost: Double?
    var replacedFrontLeft: Bool
    var replacedFrontRight: Bool
    var replacedRearLeft: Bool
    var replacedRearRight: Bool
}

struct AirFilterChangeDTO: Codable {
    var date: Date
    var filterTypeRaw: String
    var mileage: Int?
    var brand: String
    var partNumber: String
    var cost: Double?
    var notes: String
}

struct RepairEventDTO: Codable {
    var date: Date
    var repairTypeRaw: String
    var positionRaw: String
    var shopName: String
    var cost: Double?
    var mileage: Int?
    var notes: String
    var tireLocalID: String?
    var photos: [PhotoDTO]
}

// MARK: - Service

enum DataTransferService {

    private static var appVersion: String? {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    }

    // MARK: JSON export

    @MainActor
    static func exportJSON(context: ModelContext, excludePhotos: Bool = false) throws -> URL {
        let cars = try context.fetch(FetchDescriptor<Car>())
        let document = ExportDocument(
            appVersion: appVersion,
            cars: cars.map { carDTO(from: $0, excludePhotos: excludePhotos) }
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(document)
        logger.info("exportJSON: \(cars.count) car(s), \(data.count) bytes")
        return try writeTempFile(data: data, ext: "json")
    }

    private static func carDTO(from car: Car, excludePhotos: Bool = false) -> CarDTO {
        // Each tire gets a localID so measurements/repairs can reference it on import.
        var tireIDs: [PersistentIdentifier: String] = [:]
        let tireDTOs: [TireDTO] = (car.tires ?? []).map { tire in
            let id = UUID().uuidString
            tireIDs[tire.persistentModelID] = id
            return TireDTO(
                localID: id,
                brand: tire.brand,
                modelName: tire.modelName,
                size: tire.size,
                dotNumber: tire.dotNumber,
                purchaseDate: tire.purchaseDate,
                installDate: tire.installDate,
                initialTreadDepth: tire.initialTreadDepth,
                purchasePrice: tire.purchasePrice,
                currentPosition: tire.currentPosition,
                mileageAtInstall: tire.mileageAtInstall,
                notes: tire.notes
            )
        }

        let measurementDTOs: [MeasurementDTO] = (car.measurements ?? []).map { m in
            let depths = m.effectiveTreadDepths
            return MeasurementDTO(
                date: m.date,
                treadDepth: m.treadDepth,
                positionRaw: m.positionRaw,
                notes: m.notes,
                mileage: m.mileage,
                treadDepths: depths.isEmpty ? nil : depths,
                innerTreadDepth: nil,
                centerTreadDepth: nil,
                outerTreadDepth: nil,
                tireLocalID: m.tire.flatMap { tireIDs[$0.persistentModelID] },
                photos: excludePhotos ? [] : photoDTOs(m.photos?.map { ($0.data, $0.sortIndex, $0.createdAt) })
            )
        }

        let repairDTOs: [RepairEventDTO] = (car.repairEvents ?? []).map { r in
            RepairEventDTO(
                date: r.date,
                repairTypeRaw: r.repairTypeRaw,
                positionRaw: r.positionRaw,
                shopName: r.shopName,
                cost: r.cost,
                mileage: r.mileage,
                notes: r.notes,
                tireLocalID: r.tire.flatMap { tireIDs[$0.persistentModelID] },
                photos: excludePhotos ? [] : photoDTOs(r.photos?.map { ($0.data, $0.sortIndex, $0.createdAt) })
            )
        }

        return CarDTO(
            name: car.name,
            make: car.make,
            model: car.model,
            year: car.year,
            dateAdded: car.dateAdded,
            vin: car.vin,
            trimBadging: car.trimBadging,
            listingURL: car.listingURL,
            purchasePrice: car.purchasePrice,
            hasFSD: car.hasFSD,
            freeSupercharging: car.freeSupercharging,
            perfConfig: car.perfConfig,
            batteryLevel: car.batteryLevel,
            chargingState: car.chargingState,
            latitude: car.latitude,
            longitude: car.longitude,
            heading: car.heading,
            locationUpdatedAt: car.locationUpdatedAt,
            tires: tireDTOs,
            measurements: measurementDTOs,
            mileageReadings: (car.mileageReadings ?? []).map {
                MileageReadingDTO(date: $0.date, mileage: $0.mileage, source: $0.source)
            },
            tpmsReadings: (car.tpmsReadings ?? []).map {
                TPMSReadingDTO(date: $0.date, frontLeft: $0.frontLeft, frontRight: $0.frontRight,
                               rearLeft: $0.rearLeft, rearRight: $0.rearRight,
                               outsideTemperature: $0.outsideTemperature)
            },
            rotationEvents: (car.rotationEvents ?? []).map {
                RotationEventDTO(date: $0.date, patternRaw: $0.patternRaw, mileage: $0.mileage, notes: $0.notes)
            },
            replacementEvents: (car.replacementEvents ?? []).map {
                ReplacementEventDTO(date: $0.date, mileage: $0.mileage, notes: $0.notes,
                                    brand: $0.brand, modelName: $0.modelName, cost: $0.cost,
                                    replacedFrontLeft: $0.replacedFrontLeft,
                                    replacedFrontRight: $0.replacedFrontRight,
                                    replacedRearLeft: $0.replacedRearLeft,
                                    replacedRearRight: $0.replacedRearRight)
            },
            airFilterChanges: (car.airFilterChanges ?? []).map {
                AirFilterChangeDTO(date: $0.date, filterTypeRaw: $0.filterTypeRaw, mileage: $0.mileage,
                                   brand: $0.brand, partNumber: $0.partNumber, cost: $0.cost, notes: $0.notes)
            },
            repairEvents: repairDTOs
        )
    }

    private static func photoDTOs(_ raw: [(Data, Int, Date)]?) -> [PhotoDTO] {
        (raw ?? [])
            .sorted { $0.1 < $1.1 }
            .map { PhotoDTO(data: $0.0, sortIndex: $0.1, createdAt: $0.2) }
    }

    // MARK: JSON import

    @MainActor
    static func importJSON(data: Data, context: ModelContext) throws -> ImportSummary {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let document: ExportDocument
        do {
            document = try decoder.decode(ExportDocument.self, from: data)
        } catch {
            logger.error("importJSON: decode failed — \(error)")
            throw DataTransferError.invalidFormat
        }
        guard !document.cars.isEmpty else { throw DataTransferError.emptyData }

        var summary = ImportSummary()

        for carDTO in document.cars {
            let car = Car(name: carDTO.name, make: carDTO.make, model: carDTO.model,
                          year: carDTO.year, dateAdded: carDTO.dateAdded)
            car.vin = carDTO.vin
            car.trimBadging = carDTO.trimBadging
            car.listingURL = carDTO.listingURL
            car.purchasePrice = carDTO.purchasePrice
            car.hasFSD = carDTO.hasFSD
            car.freeSupercharging = carDTO.freeSupercharging
            car.perfConfig = carDTO.perfConfig
            car.batteryLevel = carDTO.batteryLevel
            car.chargingState = carDTO.chargingState
            car.latitude = carDTO.latitude
            car.longitude = carDTO.longitude
            car.heading = carDTO.heading
            car.locationUpdatedAt = carDTO.locationUpdatedAt
            context.insert(car)
            summary.cars += 1

            // Tires first, tracking localID → Tire so measurements/repairs can re-link.
            var tireMap: [String: Tire] = [:]
            var tiresByPosition: [TirePosition: Tire] = [:]
            for t in carDTO.tires {
                let position = TirePosition(rawValue: t.currentPosition) ?? .frontLeft
                let tire = Tire(brand: t.brand, modelName: t.modelName, size: t.size,
                                dotNumber: t.dotNumber, purchaseDate: t.purchaseDate,
                                installDate: t.installDate, initialTreadDepth: t.initialTreadDepth,
                                purchasePrice: t.purchasePrice, currentPosition: position,
                                mileageAtInstall: t.mileageAtInstall, notes: t.notes)
                tire.car = car
                context.insert(tire)
                tireMap[t.localID] = tire
                tiresByPosition[position] = tire
                summary.tires += 1
            }

            for m in carDTO.measurements {
                let position = TirePosition(rawValue: m.positionRaw) ?? .frontLeft
                let tire = resolveTire(localID: m.tireLocalID, position: position, car: car,
                                       tireMap: tireMap, tiresByPosition: &tiresByPosition, context: context)
                let depths = m.treadDepths
                    ?? [m.innerTreadDepth, m.centerTreadDepth, m.outerTreadDepth].compactMap { $0 }
                let measurement = TireMeasurement(
                    date: m.date, treadDepth: m.treadDepth, position: position, tire: tire,
                    notes: m.notes, mileage: m.mileage,
                    treadDepths: depths.count >= 2 ? depths : [])
                measurement.car = car
                context.insert(measurement)
                for p in m.photos {
                    let photo = TirePhoto(data: p.data, sortIndex: p.sortIndex)
                    photo.createdAt = p.createdAt
                    photo.measurement = measurement
                    context.insert(photo)
                }
                summary.measurements += 1
            }

            for r in carDTO.mileageReadings {
                let reading = MileageReading(date: r.date, mileage: r.mileage, source: r.source)
                reading.car = car
                context.insert(reading)
                summary.mileageReadings += 1
            }

            for t in carDTO.tpmsReadings {
                let reading = TPMSReading(date: t.date, frontLeft: t.frontLeft, frontRight: t.frontRight,
                                          rearLeft: t.rearLeft, rearRight: t.rearRight,
                                          outsideTemperature: t.outsideTemperature)
                reading.car = car
                context.insert(reading)
                summary.tpmsReadings += 1
            }

            for e in carDTO.rotationEvents {
                let event = TireRotationEvent(date: e.date,
                                              pattern: TireRotationPattern(rawValue: e.patternRaw) ?? .frontToBack,
                                              mileage: e.mileage, notes: e.notes)
                event.car = car
                context.insert(event)
                summary.events += 1
            }

            for e in carDTO.replacementEvents {
                var positions: [TirePosition] = []
                if e.replacedFrontLeft { positions.append(.frontLeft) }
                if e.replacedFrontRight { positions.append(.frontRight) }
                if e.replacedRearLeft { positions.append(.rearLeft) }
                if e.replacedRearRight { positions.append(.rearRight) }
                let event = TireReplacementEvent(date: e.date, positions: positions, brand: e.brand,
                                                 modelName: e.modelName, mileage: e.mileage,
                                                 cost: e.cost, notes: e.notes)
                event.car = car
                context.insert(event)
                summary.events += 1
            }

            for e in carDTO.airFilterChanges {
                let event = AirFilterChangeEvent(date: e.date,
                                                 filterType: AirFilterType(rawValue: e.filterTypeRaw) ?? .cabin,
                                                 mileage: e.mileage, brand: e.brand,
                                                 partNumber: e.partNumber, cost: e.cost, notes: e.notes)
                event.car = car
                context.insert(event)
                summary.events += 1
            }

            for r in carDTO.repairEvents {
                let position = TirePosition(rawValue: r.positionRaw) ?? .frontLeft
                let event = TireRepairEvent(date: r.date,
                                            repairType: TireRepairType(rawValue: r.repairTypeRaw) ?? .plug,
                                            position: position, shopName: r.shopName,
                                            cost: r.cost, mileage: r.mileage, notes: r.notes)
                event.car = car
                if let id = r.tireLocalID { event.tire = tireMap[id] }
                context.insert(event)
                for p in r.photos {
                    let photo = TireRepairPhoto(data: p.data, sortIndex: p.sortIndex)
                    photo.createdAt = p.createdAt
                    photo.repairEvent = event
                    context.insert(photo)
                }
                summary.events += 1
            }
        }

        try context.save()
        logger.info("importJSON: \(summary.description)")
        return summary
    }

    /// Resolves the tire a measurement belongs to: by localID, then by position,
    /// creating a placeholder tire if neither matches (mirrors AddMeasurementView).
    @MainActor
    private static func resolveTire(localID: String?, position: TirePosition, car: Car,
                                    tireMap: [String: Tire],
                                    tiresByPosition: inout [TirePosition: Tire],
                                    context: ModelContext) -> Tire {
        if let localID, let tire = tireMap[localID] { return tire }
        if let tire = tiresByPosition[position] { return tire }
        let placeholder = Tire(brand: "", modelName: "", size: "", currentPosition: position)
        placeholder.car = car
        context.insert(placeholder)
        tiresByPosition[position] = placeholder
        return placeholder
    }

    // MARK: CSV export

    /// Column order for the measurements CSV. Import looks columns up by name, so order is not load-bearing.
    /// `Tread Depths` is a pipe-separated list of values ordered innermost → outermost.
    /// `Inner`/`Center`/`Outer` are retained for one release for legacy importers.
    private static let csvColumns = [
        "Car Name", "VIN", "Date", "Position", "Tire Brand", "Tire Model", "Tire Size",
        "Tread Depth (32nds)", "Tread Depths", "Inner", "Center", "Outer", "Mileage", "Notes"
    ]

    @MainActor
    static func exportCSV(context: ModelContext) throws -> URL {
        let cars = try context.fetch(FetchDescriptor<Car>())
        let isoFormatter = ISO8601DateFormatter()

        var lines = [csvColumns.map(csvEscape).joined(separator: ",")]
        for car in cars.sorted(by: { $0.displayName < $1.displayName }) {
            let measurements = (car.measurements ?? []).sorted { $0.date < $1.date }
            for m in measurements {
                let tire = m.tire
                let depths = m.effectiveTreadDepths
                let depthsField = depths.map { String(format: "%.2f", $0) }.joined(separator: "|")
                let fields = [
                    car.displayName,
                    car.vin ?? "",
                    isoFormatter.string(from: m.date),
                    m.positionRaw,
                    tire?.brand ?? "",
                    tire?.modelName ?? "",
                    tire?.size ?? "",
                    String(format: "%.2f", m.treadDepth),
                    depthsField,
                    "",
                    "",
                    "",
                    m.mileage.map(String.init) ?? "",
                    m.notes
                ]
                lines.append(fields.map(csvEscape).joined(separator: ","))
            }
        }

        let csv = lines.joined(separator: "\r\n")
        guard let data = csv.data(using: .utf8) else { throw DataTransferError.invalidFormat }
        logger.info("exportCSV: \(lines.count - 1) measurement row(s)")
        return try writeTempFile(data: data, ext: "csv")
    }

    // MARK: CSV import

    @MainActor
    static func importCSV(data: Data, context: ModelContext) throws -> ImportSummary {
        guard let text = String(data: data, encoding: .utf8) else { throw DataTransferError.notUTF8 }
        let rows = parseCSV(text).filter { !($0.count == 1 && $0[0].isEmpty) }
        guard rows.count > 1 else { throw DataTransferError.emptyData }

        let header = rows[0].map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
        func index(_ name: String) -> Int? { header.firstIndex(of: name.lowercased()) }
        func field(_ row: [String], _ name: String) -> String {
            guard let i = index(name), i < row.count else { return "" }
            return row[i].trimmingCharacters(in: .whitespaces)
        }

        guard index("date") != nil, index("tread depth (32nds)") != nil else {
            throw DataTransferError.invalidFormat
        }

        let isoFormatter = ISO8601DateFormatter()
        var summary = ImportSummary()

        // Cache of cars touched during this import so repeated rows reuse the same car/tire.
        let existingCars = try context.fetch(FetchDescriptor<Car>())
        var carsByVIN: [String: Car] = [:]
        var carsByName: [String: Car] = [:]
        for car in existingCars {
            if let vin = car.vin, !vin.isEmpty { carsByVIN[vin.uppercased()] = car }
            carsByName[car.displayName.lowercased()] = car
        }
        var tiresByCar: [ObjectIdentifier: [TirePosition: Tire]] = [:]

        for row in rows.dropFirst() {
            guard let date = isoFormatter.date(from: field(row, "date")),
                  let depth = Double(field(row, "tread depth (32nds)")) else { continue }
            let position = TirePosition(rawValue: field(row, "position")) ?? .frontLeft

            // Resolve (or create) the car.
            let vin = field(row, "vin")
            let name = field(row, "car name")
            let car: Car
            if !vin.isEmpty, let existing = carsByVIN[vin.uppercased()] {
                car = existing
            } else if vin.isEmpty, !name.isEmpty, let existing = carsByName[name.lowercased()] {
                car = existing
            } else {
                car = Car(name: name.isEmpty ? "Imported Car" : name, make: "Tesla", model: "", year: 0)
                if !vin.isEmpty { car.vin = vin }
                context.insert(car)
                if !vin.isEmpty { carsByVIN[vin.uppercased()] = car }
                carsByName[car.displayName.lowercased()] = car
                summary.cars += 1
            }

            // Resolve (or create) the tire at this position.
            var tiresForCar = tiresByCar[ObjectIdentifier(car)] ?? Dictionary(
                (car.tires ?? []).map { ($0.position, $0) },
                uniquingKeysWith: { first, _ in first }
            )
            let tire: Tire
            if let existing = tiresForCar[position] {
                tire = existing
            } else {
                tire = Tire(brand: field(row, "tire brand"), modelName: field(row, "tire model"),
                            size: field(row, "tire size"), currentPosition: position)
                tire.car = car
                context.insert(tire)
                tiresForCar[position] = tire
                summary.tires += 1
            }
            tiresByCar[ObjectIdentifier(car)] = tiresForCar

            let depths: [Double] = {
                let raw = field(row, "tread depths")
                if !raw.isEmpty {
                    return raw.split(separator: "|").compactMap { Double($0) }
                }
                return [field(row, "inner"), field(row, "center"), field(row, "outer")]
                    .compactMap { Double($0) }
            }()
            let measurement = TireMeasurement(
                date: date, treadDepth: depth, position: position, tire: tire,
                notes: field(row, "notes"),
                mileage: Int(field(row, "mileage")),
                treadDepths: depths.count >= 2 ? depths : [])
            measurement.car = car
            context.insert(measurement)
            summary.measurements += 1
        }

        guard summary.measurements > 0 else { throw DataTransferError.emptyData }
        try context.save()
        logger.info("importCSV: \(summary.description)")
        return summary
    }

    // MARK: - Helpers

    private static func writeTempFile(data: Data, ext: String) throws -> URL {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HHmmss"
        let name = "TezCare-Export-\(formatter.string(from: Date())).\(ext)"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        try data.write(to: url, options: .atomic)
        return url
    }

    private static func csvEscape(_ value: String) -> String {
        guard value.contains(where: { $0 == "," || $0 == "\"" || $0 == "\n" || $0 == "\r" }) else {
            return value
        }
        return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }

    /// Minimal RFC 4180 CSV parser — handles quoted fields containing commas, quotes and newlines.
    private static func parseCSV(_ text: String) -> [[String]] {
        var rows: [[String]] = []
        var record: [String] = []
        var field = ""
        var inQuotes = false
        let chars = Array(text)
        var i = 0

        func endField() { record.append(field); field = "" }
        func endRecord() { endField(); rows.append(record); record = [] }

        while i < chars.count {
            let c = chars[i]
            if inQuotes {
                if c == "\"" {
                    if i + 1 < chars.count, chars[i + 1] == "\"" {
                        field.append("\"")
                        i += 2
                    } else {
                        inQuotes = false
                        i += 1
                    }
                } else {
                    field.append(c)
                    i += 1
                }
            } else {
                switch c {
                case "\"":
                    inQuotes = true
                    i += 1
                case ",":
                    endField()
                    i += 1
                case "\r":
                    endRecord()
                    i += (i + 1 < chars.count && chars[i + 1] == "\n") ? 2 : 1
                case "\n":
                    endRecord()
                    i += 1
                default:
                    field.append(c)
                    i += 1
                }
            }
        }
        if !field.isEmpty || !record.isEmpty { endRecord() }
        return rows
    }
}
