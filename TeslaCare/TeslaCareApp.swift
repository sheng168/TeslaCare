//
//  TeslaCareApp.swift
//  TeslaCare
//
//  Created by Jin on 5/7/26.
//

import SwiftUI
import SwiftData
import OSLog

private let logger = Logger(subsystem: "com.teslacare", category: "App")

@main
struct TeslaCareApp: App {
    @StateObject private var authManager = TeslaAuthManager()
    @State private var locationManager = LocationManager()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Car.self,
            Tire.self,
            TireMeasurement.self,
            TirePhoto.self,
            TireRotationEvent.self,
            TireReplacementEvent.self,
            AirFilterChangeEvent.self,
            TPMSReading.self,
            MileageReading.self,
            TeslaCredential.self,
            NearbyCharger.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            logger.info("ModelContainer created successfully")
            return container
        } catch {
            logger.error("Failed to create ModelContainer: \(error)")
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(locationManager)
                .environmentObject(authManager)
                .onAppear {
                    logger.info("App appeared, setting up authManager")
                    authManager.setup(context: sharedModelContainer.mainContext)
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
