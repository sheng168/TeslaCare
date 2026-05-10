//
//  TeslaCareApp.swift
//  TeslaCare
//
//  Created by Jin on 5/7/26.
//

import SwiftUI
import SwiftData

@main
struct TeslaCareApp: App {
    @StateObject private var authManager = TeslaAuthManager()
    @State private var locationManager = LocationManager()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Car.self,
            Tire.self,
            TireMeasurement.self,
            TireRotationEvent.self,
            TireReplacementEvent.self,
            AirFilterChangeEvent.self,
            TPMSReading.self,
            MileageReading.self,
            TeslaCredential.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(locationManager)
                .environmentObject(authManager)
                .onAppear {
                    authManager.setup(context: sharedModelContainer.mainContext)
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
