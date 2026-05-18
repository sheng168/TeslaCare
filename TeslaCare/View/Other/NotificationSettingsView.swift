//
//  NotificationSettingsView.swift
//  TeslaCare
//
//  Created by Jin on 5/8/26.
//

import SwiftUI
import SwiftData

struct NotificationSettingsView: View {
    @AppStorage("notifyWeeklyCheck") private var notifyWeeklyCheck = false
    @AppStorage("notifyLowTread") private var notifyLowTread = true
    @AppStorage("notifyRotationDue") private var notifyRotationDue = true
    @AppStorage("rotationInterval") private var rotationInterval = 5000.0
    @AppStorage("warningThreshold") private var warningThreshold = 4.0
    @Query private var cars: [Car]
    @Query private var tires: [Tire]

    var body: some View {
        List {
            Section("Reminders") {
                Toggle("Weekly Tire Check", isOn: $notifyWeeklyCheck)
                    .onChange(of: notifyWeeklyCheck) { _, enabled in
                        if enabled {
                            NotificationManager.scheduleWeeklyTireCheck()
                        } else {
                            NotificationManager.cancelWeeklyTireCheck()
                        }
                    }

                Toggle("Low Tread Alert", isOn: $notifyLowTread)
                    .onChange(of: notifyLowTread) { _, enabled in
                        if enabled {
                            NotificationManager.scheduleLowTreadAlerts(for: tires, warningThreshold: warningThreshold)
                        } else {
                            NotificationManager.cancelLowTreadAlerts()
                        }
                    }

                Toggle("Rotation Due", isOn: $notifyRotationDue)
                    .onChange(of: notifyRotationDue) { _, enabled in
                        if enabled {
                            NotificationManager.scheduleRotationReminders(for: cars, intervalMiles: rotationInterval)
                        } else {
                            NotificationManager.cancelRotationReminders(for: cars)
                        }
                    }
            }

            if notifyRotationDue {
                Section("Rotation Schedule") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Remind every \(Int(rotationInterval)) miles")
                            .font(.subheadline)

                        Slider(value: $rotationInterval, in: 3000...10000, step: 500)
                            .onChange(of: rotationInterval) { _, interval in
                                NotificationManager.scheduleRotationReminders(for: cars, intervalMiles: interval)
                            }

                        HStack {
                            Text("3,000 mi")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("10,000 mi")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section {
                Text("You'll receive notifications when tires need attention based on your settings.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Notification Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        NotificationSettingsView()
    }
    .modelContainer(for: [Car.self, Tire.self], inMemory: true)
}
