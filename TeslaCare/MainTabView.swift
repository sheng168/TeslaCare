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

    var body: some View {
        TabView(selection: $selectedTab) {
            ContentView()
                .tabItem {
                    Label("Cars", systemImage: "car.fill")
                }
                .tag(0)
            
            TireListView()
                .tabItem {
                    Label("Tires", systemImage: "circle.dotted")
                }
                .tag(1)
            
            MaintenanceView()
                .tabItem {
                    Label("Maintenance", systemImage: "wrench.and.screwdriver.fill")
                }
                .tag(2)
            
            ChargersView()
                .tabItem {
                    Label("Chargers", systemImage: "bolt.fill")
                }
                .tag(3)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(4)
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [Car.self, Tire.self, TireMeasurement.self], inMemory: true)
}
