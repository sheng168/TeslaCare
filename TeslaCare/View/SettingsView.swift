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
import UniformTypeIdentifiers
import UserNotifications
import TeslaSwift

private let logger = Logger(subsystem: "com.teslacare", category: "Settings")

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("measurementUnit") private var measurementUnit = "imperial"
    @AppStorage("showNotifications") private var showNotifications = true
    @AppStorage("replacementThreshold") private var replacementThreshold = 2.0
    @AppStorage("warningThreshold") private var warningThreshold = 4.0
    @AppStorage("teslaAccessToken") private var teslaAccessToken: String?
    @EnvironmentObject private var authManager: TeslaAuthManager

    @State private var showingTeslaAuth = false
    @State private var iCloudStatus: CKAccountStatus = .couldNotDetermine
    @Query private var cars: [Car]

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
                    
                    Link("Privacy Policy", destination: URL(string: "https://example.com/privacy")!)
                    Link("Terms of Service", destination: URL(string: "https://example.com/terms")!)
                    
                    Button("Send Feedback") {
                        sendFeedback()
                    }
                }
                
                Section {
                    Button(role: .destructive) {
                        // Show confirmation alert
                    } label: {
                        Text("Delete All Data")
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .task { await fetchiCloudStatus() }
            .sheet(isPresented: $showingTeslaAuth) {
                TeslaAuthView()
            }
        }
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
        case .available:             return "checkmark.icloud.fill"
        case .noAccount:             return "icloud.slash.fill"
        case .restricted:            return "lock.icloud.fill"
        case .temporarilyUnavailable: return "exclamationmark.icloud.fill"
        default:                     return "icloud.fill"
        }
    }

    private var iCloudStatusColor: Color {
        switch iCloudStatus {
        case .available:             return .green
        case .noAccount:             return .orange
        case .restricted:            return .red
        case .temporarilyUnavailable: return .orange
        default:                     return .secondary
        }
    }

    private var iCloudStatusText: String {
        switch iCloudStatus {
        case .available:             return "Syncing with iCloud"
        case .noAccount:             return "Not Signed In"
        case .restricted:            return "iCloud Restricted"
        case .temporarilyUnavailable: return "Temporarily Unavailable"
        default:                     return "Checking…"
        }
    }

    private var iCloudStatusDetail: String {
        switch iCloudStatus {
        case .available:             return "Your data syncs automatically across devices"
        case .noAccount:             return "Sign in to iCloud in Settings to enable sync"
        case .restricted:            return "iCloud access is restricted on this device"
        case .temporarilyUnavailable: return "iCloud is unavailable — will retry automatically"
        default:                     return "Determining iCloud availability"
        }
    }

    private func sendFeedback() {
        // Open mail or feedback form
        if let url = URL(string: "mailto:feedback@example.com") {
            #if os(iOS)
            UIApplication.shared.open(url)
            #endif
        }
    }
}

// MARK: - Notification Settings

struct NotificationSettingsView: View {
    @AppStorage("notifyWeeklyCheck") private var notifyWeeklyCheck = false
    @AppStorage("notifyLowTread") private var notifyLowTread = true
    @AppStorage("notifyRotationDue") private var notifyRotationDue = true
    @AppStorage("rotationInterval") private var rotationInterval = 5000.0
    
    var body: some View {
        List {
            Section("Reminders") {
                Toggle("Weekly Tire Check", isOn: $notifyWeeklyCheck)
                
                Toggle("Low Tread Alert", isOn: $notifyLowTread)
                
                Toggle("Rotation Due", isOn: $notifyRotationDue)
            }
            
            if notifyRotationDue {
                Section("Rotation Schedule") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Remind every \(Int(rotationInterval)) miles")
                            .font(.subheadline)
                        
                        Slider(value: $rotationInterval, in: 3000...10000, step: 500)
                        
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

// MARK: - Export/Import Views

struct ExportDataView: View {
    @State private var showingShareSheet = false
    @State private var exportURL: URL?
    
    var body: some View {
        List {
            Section {
                Text("Export all your tire and maintenance data to a file that can be imported later or shared with another device.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Section("Export Format") {
                Button {
                    exportAsJSON()
                } label: {
                    Label("Export as JSON", systemImage: "doc.text")
                }
                
                Button {
                    exportAsCSV()
                } label: {
                    Label("Export as CSV", systemImage: "tablecells")
                }
            }
        }
        .navigationTitle("Export Data")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingShareSheet) {
            if let url = exportURL {
                ShareSheet(items: [url])
            }
        }
    }
    
    private func exportAsJSON() {
        // Implementation for JSON export
        logger.info("Exporting as JSON")
    }

    private func exportAsCSV() {
        // Implementation for CSV export
        logger.info("Exporting as CSV")
    }
}

struct ImportDataView: View {
    @State private var showingFilePicker = false
    
    var body: some View {
        List {
            Section {
                Text("Import tire and maintenance data from a previously exported file.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Section {
                Button {
                    showingFilePicker = true
                } label: {
                    Label("Choose File", systemImage: "folder")
                }
            }
            
            Section {
                Text("⚠️ Importing will merge with existing data. Duplicate entries may be created.")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .navigationTitle("Import Data")
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.json, .commaSeparatedText],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result: result)
        }
    }
    
    private func handleImport(result: Result<[URL], Error>) {
        // Implementation for import
        switch result {
        case .success(let urls):
            if let url = urls.first {
                logger.info("Importing from: \(url)")
            }
        case .failure(let error):
            logger.error("Import failed: \(error)")
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Previews

#Preview("Settings") {
    SettingsView()
        .modelContainer(for: Car.self, inMemory: true)
}

#Preview("Notification Settings") {
    NavigationStack {
        NotificationSettingsView()
    }
}

#Preview("Export Data") {
    NavigationStack {
        ExportDataView()
    }
}

#Preview("Import Data") {
    NavigationStack {
        ImportDataView()
    }
}
