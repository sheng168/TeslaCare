//
//  ExportDataView.swift
//  TeslaCare
//
//  Created by Jin on 5/8/26.
//

import SwiftUI
import OSLog
import SwiftData

private let logger = Logger(subsystem: "com.teslacare", category: "Settings")

struct ExportDataView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showingShareSheet = false
    @State private var exportURL: URL?
    @State private var errorMessage: String?

    var body: some View {
        List {
            Section {
                Text("Export your tire and maintenance data to a file that can be imported later or shared with another device.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section("Export Format") {
                Button {
                    export(.json)
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Label("Export as JSON", systemImage: "doc.text")
                        Text("Full backup — cars, tires, measurements, photos and events.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Button {
                    export(.csv)
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Label("Export as CSV", systemImage: "tablecells")
                        Text("Measurements only — opens in any spreadsheet app.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
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
        .alert("Export Failed", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private enum ExportFormat { case json, csv }

    private func export(_ format: ExportFormat) {
        do {
            let url: URL
            switch format {
            case .json:
                logger.info("Exporting as JSON")
                url = try DataTransferService.exportJSON(context: modelContext)
            case .csv:
                logger.info("Exporting as CSV")
                url = try DataTransferService.exportCSV(context: modelContext)
            }
            exportURL = url
            showingShareSheet = true
        } catch {
            logger.error("Export failed: \(error)")
            errorMessage = error.localizedDescription
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationStack {
        ExportDataView()
    }
}
