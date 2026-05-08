//
//  SettingsView.swift
//  TeslaCare
//
//  Created by Jin on 5/8/26.
//

import SwiftUI
import SwiftData
internal import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("measurementUnit") private var measurementUnit = "imperial"
    @AppStorage("showNotifications") private var showNotifications = true
    @AppStorage("replacementThreshold") private var replacementThreshold = 2.0
    @AppStorage("warningThreshold") private var warningThreshold = 4.0
    
    var body: some View {
        NavigationStack {
            List {
                Section("Units") {
                    Picker("Tread Depth Unit", selection: $measurementUnit) {
                        Text("32nds of an inch").tag("imperial")
                        Text("Millimeters").tag("metric")
                    }
                }
                
                Section("Notifications") {
                    Toggle("Enable Reminders", isOn: $showNotifications)
                    
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
        print("Exporting as JSON")
    }
    
    private func exportAsCSV() {
        // Implementation for CSV export
        print("Exporting as CSV")
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
                print("Importing from: \(url)")
            }
        case .failure(let error):
            print("Import failed: \(error)")
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
