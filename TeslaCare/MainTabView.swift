//
//  MainTabView.swift
//  TeslaCare
//
//  Created by Jin on 5/8/26.
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    var body: some View {
        TabView {
            ContentView()
                .tabItem {
                    Label("Cars", systemImage: "car.fill")
                }
            
            TireListView()
                .tabItem {
                    Label("Tires", systemImage: "circle.dotted")
                }
            
            MaintenanceView()
                .tabItem {
                    Label("Maintenance", systemImage: "wrench.and.screwdriver.fill")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [Car.self, Tire.self, TireMeasurement.self], inMemory: true)
}
