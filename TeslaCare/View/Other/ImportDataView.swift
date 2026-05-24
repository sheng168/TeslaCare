//
//  ImportDataView.swift
//  TeslaCare
//
//  Created by Jin on 5/8/26.
//

import SwiftUI
import UniformTypeIdentifiers
import OSLog
import SwiftData

private let logger = Logger(subsystem: "com.teslacare", category: "Settings")

struct ImportDataView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showingFilePicker = false
    @State private var resultMessage: String?
    @State private var errorMessage: String?

    var body: some View {
        List {
            Section {
                Text("Import tire and maintenance data from a previously exported JSON or CSV file.")
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
        .alert("Import Complete", isPresented: .constant(resultMessage != nil)) {
            Button("OK") { resultMessage = nil }
        } message: {
            Text(resultMessage ?? "")
        }
        .alert("Import Failed", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func handleImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            logger.info("Importing from: \(url.lastPathComponent)")
            // The picked file lives outside the app sandbox — claim access while reading it.
            let didAccess = url.startAccessingSecurityScopedResource()
            defer {
                if didAccess { url.stopAccessingSecurityScopedResource() }
            }
            do {
                let data = try Data(contentsOf: url)
                let summary: ImportSummary
                if url.pathExtension.lowercased() == "csv" {
                    summary = try DataTransferService.importCSV(data: data, context: modelContext)
                } else {
                    summary = try DataTransferService.importJSON(data: data, context: modelContext)
                }
                logger.info("Import succeeded: \(summary.description)")
                resultMessage = summary.description
            } catch {
                logger.error("Import failed: \(error)")
                errorMessage = error.localizedDescription
            }
        case .failure(let error):
            logger.error("Import failed: \(error)")
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        ImportDataView()
    }
}
