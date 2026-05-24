import SwiftUI
import SwiftData

// MARK: - Lean models mirroring the iOS app's CloudKit schema.
// Field names must match so SwiftData maps to the same CloudKit record fields (CD_<name>).
// Extra iOS fields not declared here are preserved in CloudKit and ignored on the watch.

@Model final class Car {
    var name: String = ""
    var make: String = ""
    var model: String = ""
    var year: Int = 0
    var dateAdded: Date = Date()
    var vin: String?
    var trimBadging: String?
    var batteryLevel: Int?
    var chargingState: String?

    @Relationship(deleteRule: .cascade, inverse: \Tire.car)
    var tires: [Tire]?

    @Relationship(deleteRule: .cascade, inverse: \TireMeasurement.car)
    var measurements: [TireMeasurement]?

    init(name: String = "", make: String = "", model: String = "", year: Int = 0) {
        self.name = name
        self.make = make
        self.model = model
        self.year = year
    }

    var displayName: String {
        name.isEmpty ? "\(year) \(make) \(model)" : name
    }

    func latestMeasurement(for position: TirePosition) -> TireMeasurement? {
        measurements?
            .filter { $0.position == position }
            .sorted { $0.date > $1.date }
            .first
    }

    var averageTreadDepth: Double? {
        let latest = TirePosition.allCases.compactMap { latestMeasurement(for: $0) }
        guard !latest.isEmpty else { return nil }
        return latest.reduce(0.0) { $0 + $1.treadDepth } / Double(latest.count)
    }

    var tireHealthPercentage: Double? {
        guard let avg = averageTreadDepth else { return nil }
        return min(100, max(0, (avg - 2.0) / 8.0 * 100))
    }
}

@Model final class Tire {
    var brand: String = ""
    var modelName: String = ""
    var size: String = ""
    var currentPosition: String = "Front Left"
    var initialTreadDepth: Double = 10.0
    var car: Car?

    @Relationship(deleteRule: .cascade, inverse: \TireMeasurement.tire)
    var measurements: [TireMeasurement]?

    init(brand: String = "", modelName: String = "", size: String = "", currentPosition: String = "Front Left", initialTreadDepth: Double = 10.0) {
        self.brand = brand
        self.modelName = modelName
        self.size = size
        self.currentPosition = currentPosition
        self.initialTreadDepth = initialTreadDepth
    }

    var position: TirePosition {
        get { TirePosition(rawValue: currentPosition) ?? .frontLeft }
        set { currentPosition = newValue.rawValue }
    }

    var latestMeasurement: TireMeasurement? {
        measurements?.sorted { $0.date > $1.date }.first
    }

    var needsReplacement: Bool {
        (latestMeasurement?.treadDepth ?? 100) <= 2.0
    }
}

@Model final class TireMeasurement {
    var date: Date = Date()
    var treadDepth: Double = 0.0
    var positionRaw: String = "Front Left"
    var car: Car?
    var tire: Tire?

    init(date: Date = Date(), treadDepth: Double = 0.0, positionRaw: String = "Front Left", car: Car? = nil, tire: Tire? = nil) {
        self.date = date
        self.treadDepth = treadDepth
        self.positionRaw = positionRaw
        self.car = car
        self.tire = tire
    }

    var position: TirePosition {
        get { TirePosition(rawValue: positionRaw) ?? .frontLeft }
        set { positionRaw = newValue.rawValue }
    }

    var isDanger: Bool { treadDepth <= 2.0 }
    var isWarning: Bool { treadDepth <= 4.0 }
}

enum TirePosition: String, Codable, CaseIterable {
    case frontLeft  = "Front Left"
    case frontRight = "Front Right"
    case rearLeft   = "Rear Left"
    case rearRight  = "Rear Right"

    var abbreviation: String {
        switch self {
        case .frontLeft:  return "FL"
        case .frontRight: return "FR"
        case .rearLeft:   return "RL"
        case .rearRight:  return "RR"
        }
    }
}

// MARK: - App

@main
struct TezCare_Watch_AppApp: App {
    let modelContainer: ModelContainer = {
        let schema = Schema([Car.self, Tire.self, TireMeasurement.self])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic
        )
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            CarListView()
        }
        .modelContainer(modelContainer)
    }
}
