//
//  ScreenshotTests.swift
//  TeslaCareTests
//
//  Renders key views with ImageRenderer and saves PNGs to Screenshots/.
//  Run from the command line:
//    xcodebuild test -scheme TeslaCare \
//      -destination 'platform=iOS Simulator,name=iPhone 16' \
//      -only-testing:TeslaCareTests/ScreenshotTests
//

import XCTest
import SwiftUI
import SwiftData
@testable import TeslaCare

@MainActor
final class ScreenshotTests: XCTestCase {

    // Resolves to <repo-root>/Screenshots/ regardless of simulator sandbox
    private var outputDir: URL {
        URL(fileURLWithPath: #filePath)          // .../TeslaCareTests/ScreenshotTests.swift
            .deletingLastPathComponent()          // .../TeslaCareTests/
            .deletingLastPathComponent()          // .../TeslaCare/ (inner)
            .deletingLastPathComponent()          // .../TeslaCare/ (repo root)
            .appendingPathComponent("Screenshots")
    }

    override func setUp() async throws {
        try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)
    }

    // MARK: - Helpers

    private func save<V: View>(_ view: V, as name: String) throws {
        let framed = view.frame(width: 390, height: 844, alignment: .top)
        let renderer = ImageRenderer(content: framed)
        renderer.scale = 3.0
        guard let image = renderer.uiImage, let data = image.pngData() else {
            XCTFail("ImageRenderer returned nil for \(name)")
            return
        }
        let dest = outputDir.appendingPathComponent("\(name).png")
        try data.write(to: dest)
        print("✓ \(name).png → \(dest.path)")
    }

    private func makeCarContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Car.self, Tire.self, TireMeasurement.self,
                TPMSReading.self, MileageReading.self,
            configurations: config
        )
        let ctx = container.mainContext

        let car1 = Car(name: "My Tesla", make: "Tesla", model: "Model 3", year: 2023)
        car1.trimBadging = "lr awd"
        car1.batteryLevel = 82
        car1.chargingState = "Charging"
        ctx.insert(car1)
        let mileage1 = MileageReading(date: Date(), mileage: 24_831)
        mileage1.car = car1
        ctx.insert(mileage1)
        let tpms1 = TPMSReading(date: Date(), frontLeft: 2.93, frontRight: 2.93, rearLeft: 2.76, rearRight: 2.79)
        tpms1.car = car1
        ctx.insert(tpms1)
        for position in TirePosition.allCases {
            let tire = Tire(brand: "Michelin", modelName: "Pilot Sport 4S", size: "235/45R18", currentPosition: position)
            tire.car = car1
            ctx.insert(tire)
            let m = TireMeasurement(date: Date(), treadDepth: 7.5, position: position, tire: tire)
            m.car = car1
            ctx.insert(m)
        }

        let car2 = Car(name: "Family Car", make: "Tesla", model: "Model Y", year: 2022)
        car2.trimBadging = "p100d"
        car2.batteryLevel = 41
        ctx.insert(car2)
        for position in TirePosition.allCases {
            let tire = Tire(brand: "Goodyear", modelName: "Eagle F1", size: "255/45R19", currentPosition: position)
            tire.car = car2
            ctx.insert(tire)
            let m = TireMeasurement(date: .now.addingTimeInterval(-86400), treadDepth: 3.5, position: position, tire: tire)
            m.car = car2
            ctx.insert(m)
        }
        return container
    }

    private func makeTireContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Tire.self, TireMeasurement.self, Car.self, configurations: config)
        let ctx = container.mainContext

        let car = Car(name: "My Tesla", make: "Tesla", model: "Model 3", year: 2023)
        ctx.insert(car)
        let tires: [(String, String, TirePosition, Double)] = [
            ("Michelin",    "Pilot Sport 4S",  .frontLeft,  8.5),
            ("Goodyear",    "Eagle F1",        .frontRight, 3.5),
            ("Bridgestone", "Turanza",         .rearLeft,   1.8),
            ("Continental", "ExtremeContact",  .rearRight, 10.0),
        ]
        for (brand, model, pos, depth) in tires {
            let tire = Tire(brand: brand, modelName: model, size: "235/45R18", currentPosition: pos)
            tire.car = car
            ctx.insert(tire)
            let m = TireMeasurement(date: Date(), treadDepth: depth, position: pos, tire: tire)
            ctx.insert(m)
        }
        return container
    }

    // MARK: - Tests

    func testCarList() throws {
        let container = try makeCarContainer()
        try save(
            CarListView()
                .modelContainer(container)
                .environmentObject(TeslaAuthManager())
                .environment(LocationManager()),
            as: "CarList"
        )
    }

    func testTireList() throws {
        let container = try makeTireContainer()
        try save(TireListView().modelContainer(container), as: "TireList")
    }

    func testAddTire() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Car.self, Tire.self, configurations: config)
        container.mainContext.insert(Car(name: "My Tesla", make: "Tesla", model: "Model 3", year: 2023))
        try save(AddTireView().modelContainer(container), as: "AddTire")
    }

    func testSettings() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Car.self, configurations: config)
        try save(SettingsView().modelContainer(container), as: "Settings")
    }

    func testAddCar() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Car.self, configurations: config)
        try save(AddCarView().modelContainer(container), as: "AddCar")
    }

    func testMainTabView() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Car.self, configurations: config)
        try save(
            MainTabView()
                .modelContainer(container)
                .environmentObject(TeslaAuthManager())
                .environment(LocationManager()),
            as: "MainTabView"
        )
    }
}
