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
    @Environment(LocationManager.self) private var locationManager
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
                    Label("Tires", systemImage: "circle.dotted")
                }
                .tag(1)
            
//            MaintenanceView()
//                .tabItem {
//                    Label("Maintenance", systemImage: "wrench.and.screwdriver.fill")
//                }
//                .tag(2)
            
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
            if phase == .active { rescheduleAll() }
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
}
