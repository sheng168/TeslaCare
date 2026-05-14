//
//  MainTabView.swift
//  TeslaCare
//
//  Created by Jin on 5/8/26.
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    @AppStorage("selectedTab") private var selectedTab = 0
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.modelContext) private var modelContext
    @Environment(LocationManager.self) private var locationManager
    @EnvironmentObject private var authManager: TeslaAuthManager
    @Query private var cars: [Car]

    var body: some View {
        TabView(selection: $selectedTab) {
            CarListView()
                .tabItem {
                    Label("Cars", systemImage: "car.fill")
                }
                .tag(0)
            
            TireListView()
                .tabItem {
                    Label("Tires", systemImage: "circle.circle")
                }
                .tag(1)

            PublicCarsView()
                .tabItem {
                    Label("Community", systemImage: "globe")
                }
                .tag(2)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(3)
        }
        .onAppear {
            NotificationManager.requestPermission()
            locationManager.requestPermission()
            rescheduleAll()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                rescheduleAll()
                if authManager.isAuthenticated && authManager.needsDailySync {
                    Task { await authManager.fetchVehicles() }
                }
            }
        }
        .onChange(of: authManager.isLoading) { _, isLoading in
            if !isLoading && authManager.isAuthenticated && !authManager.vehicles.isEmpty {
                authManager.syncCars(into: modelContext)
            }
        }
    }

    private func rescheduleAll() {
        for car in cars {
            NotificationManager.scheduleUpdateReminder(for: car)
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [Car.self, Tire.self, TireMeasurement.self], inMemory: true)
        .environment(LocationManager())
        .environment(CloudKitPublicService())
        .environmentObject(TeslaAuthManager())
}
