//
//  ImportDataView.swift
//  TeslaCare
//
//  Created by Jin on 5/8/26.
//

import SwiftUI
import UniformTypeIdentifiers
import OSLog

private let logger = Logger(subsystem: "com.teslacare", category: "Settings")

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

#Preview {
    NavigationStack {
        ImportDataView()
    }
}
