//
//  ExportDataView.swift
//  TeslaCare
//
//  Created by Jin on 5/8/26.
//

import SwiftUI
import OSLog

private let logger = Logger(subsystem: "com.teslacare", category: "Settings")

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
        logger.info("Exporting as JSON")
    }

    private func exportAsCSV() {
        logger.info("Exporting as CSV")
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
