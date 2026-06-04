//
//  SettingsView.swift
//  TeslaCare
//
//  Created by Jin on 5/8/26.
//

import SwiftUI
import SwiftData
import CloudKit
import OSLog
import UserNotifications

private let logger = Logger(subsystem: "com.teslacare", category: "Settings")

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("measurementUnit") private var measurementUnit = "imperial"
    @AppStorage("showNotifications") private var showNotifications = true
    @AppStorage("replacementThreshold") private var replacementThreshold = 2.0
    @AppStorage("warningThreshold") private var warningThreshold = 4.0
    @EnvironmentObject private var authManager: TeslaAuthManager

    @State private var showingTeslaAuth = false
    @State private var showingDeleteConfirmation = false
    @State private var iCloudStatus: CKAccountStatus = .couldNotDetermine
    @Query private var cars: [Car]
    @Query private var credentials: [TeslaCredential]

    private var mostRecentUpdate: Date? {
        cars.compactMap(\.lastUpdatedAt).max()
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Units") {
                    Picker("Tread Depth Unit", selection: $measurementUnit) {
                        Text("32nds of an inch").tag("imperial")
                        Text("Millimeters").tag("metric")
                    }
                    .disabled(true)
                }

                Section("iCloud Sync") {
                    HStack(spacing: 12) {
                        Image(systemName: iCloudStatusIcon)
                            .font(.title3)
                            .foregroundStyle(iCloudStatusColor)
                            .frame(width: 28)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(iCloudStatusText)
                                .font(.subheadline)
                            Text(iCloudStatusDetail)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 2)

                    if let lastUpdate = mostRecentUpdate {
                        LabeledContent("Last Updated") {
                            Text(lastUpdate, style: .relative)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Tesla Integration") {
                    Button {
                        showingTeslaAuth = true
                    } label: {
                        HStack {
                            Image(systemName: "bolt.car.fill")
                            Text("Tesla Account")
                            Spacer()
                            if authManager.isAuthenticated {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            }
                        }
                    }

                    if authManager.isAuthenticated {
                        Button(role: .destructive) {
                            authManager.logout()
                        } label: {
                            Label("Sign Out of Tesla", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    }
                }

                Section("Notifications") {
                    Toggle("Enable Reminders", isOn: $showNotifications)
                        .onChange(of: showNotifications) { _, enabled in
                            if enabled {
                                NotificationManager.requestPermission()
                                cars.forEach { NotificationManager.scheduleUpdateReminder(for: $0) }
                            } else {
                                UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
                            }
                        }

                    if showNotifications {
                        NavigationLink("Configure Reminders") {
                            NotificationSettingsView()
                        }
                    }
                }

                Section("Tread Depth Thresholds") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Replacement Threshold")
                            .font(.subheadline)

                        HStack {
                            Slider(value: $replacementThreshold, in: 1.0...4.0, step: 0.5)
                            Text(String(format: "%.1f/32\"", replacementThreshold))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(width: 60, alignment: .trailing)
                        }

                        Text("Tires below this depth will be marked for replacement")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Warning Threshold")
                            .font(.subheadline)

                        HStack {
                            Slider(value: $warningThreshold, in: 3.0...6.0, step: 0.5)
                            Text(String(format: "%.1f/32\"", warningThreshold))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(width: 60, alignment: .trailing)
                        }

                        Text("Tires below this depth will show a warning")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Data") {
                    NavigationLink("Export Data") {
                        ExportDataView()
                    }

                    NavigationLink("Import Data") {
                        ImportDataView()
                    }
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }

                    Link("Refer a Friend", destination: URL(string: "https://ts.la/jin50175")!)

                    Link("Privacy Policy", destination: URL(string: "https://example.com/privacy")!)
                    Link("Terms of Service", destination: URL(string: "https://example.com/terms")!)

                    Button("Send Feedback") {
                        sendFeedback()
                    }
                }

                Section {
                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        Text("Delete All Data")
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .task { await fetchiCloudStatus() }
            .sheet(isPresented: $showingTeslaAuth) {
                TeslaAuthSheet()
            }
            .alert("Delete All Data", isPresented: $showingDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    deleteAllData()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete all cars, tire measurements, and maintenance history. This action cannot be undone.")
            }
        }
    }

    private func deleteAllData() {
        cars.forEach { modelContext.delete($0) }
        credentials.forEach { modelContext.delete($0) }
        authManager.logout()
        logger.info("All user data deleted")
    }

    // MARK: - iCloud Helpers

    private func fetchiCloudStatus() async {
        do {
            iCloudStatus = try await CKContainer.default().accountStatus()
        } catch {
            iCloudStatus = .couldNotDetermine
        }
    }

    private var iCloudStatusIcon: String {
        switch iCloudStatus {
        case .available:              return "checkmark.icloud.fill"
        case .noAccount:              return "icloud.slash.fill"
        case .restricted:             return "lock.icloud.fill"
        case .temporarilyUnavailable: return "exclamationmark.icloud.fill"
        default:                      return "icloud.fill"
        }
    }

    private var iCloudStatusColor: Color {
        switch iCloudStatus {
        case .available:              return .green
        case .noAccount:              return .orange
        case .restricted:             return .red
        case .temporarilyUnavailable: return .orange
        default:                      return .secondary
        }
    }

    private var iCloudStatusText: String {
        switch iCloudStatus {
        case .available:              return "Syncing with iCloud"
        case .noAccount:              return "Not Signed In"
        case .restricted:             return "iCloud Restricted"
        case .temporarilyUnavailable: return "Temporarily Unavailable"
        default:                      return "Checking…"
        }
    }

    private var iCloudStatusDetail: String {
        switch iCloudStatus {
        case .available:              return "Your data syncs automatically across devices"
        case .noAccount:              return "Sign in to iCloud in Settings to enable sync"
        case .restricted:             return "iCloud access is restricted on this device"
        case .temporarilyUnavailable: return "iCloud is unavailable — will retry automatically"
        default:                      return "Determining iCloud availability"
        }
    }

    private func sendFeedback() {
        if let url = URL(string: "mailto:feedback@example.com") {
            #if os(iOS)
            UIApplication.shared.open(url)
            #endif
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: Car.self, inMemory: true)
        .environmentObject(TeslaAuthManager())
}
