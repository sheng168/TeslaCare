//
//  VINScannerView.swift
//  TeslaCare
//

import SwiftUI
import VisionKit

struct VINScannerView: View {
    let onVINDetected: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        if DataScannerViewController.isSupported && DataScannerViewController.isAvailable {
            DataScannerRepresentable(onVINDetected: { vin in
                onVINDetected(vin)
                dismiss()
            })
            .ignoresSafeArea()
            .overlay(alignment: .top) {
                Text("Point at the VIN on the dashboard or door jamb")
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.black.opacity(0.6), in: Capsule())
                    .foregroundStyle(.white)
                    .padding(.top, 60)
            }
            .overlay(alignment: .bottom) {
                Button("Cancel") { dismiss() }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(.bottom, 40)
            }
        } else {
            ContentUnavailableView(
                "Scanner Unavailable",
                systemImage: "camera.slash",
                description: Text("VIN scanning is not available on this device.")
            )
        }
    }
}

private struct DataScannerRepresentable: UIViewControllerRepresentable {
    let onVINDetected: (String) -> Void

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.text()],
            qualityLevel: .accurate,
            recognizesMultipleItems: false,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )
        scanner.delegate = context.coordinator
        try? scanner.startScanning()
        return scanner
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let parent: DataScannerRepresentable
        private var hasDetected = false

        init(_ parent: DataScannerRepresentable) { self.parent = parent }

        func dataScanner(_ dataScanner: DataScannerViewController,
                         didAdd addedItems: [RecognizedItem],
                         allItems: [RecognizedItem]) {
            guard !hasDetected else { return }
            for item in addedItems {
                if case .text(let text) = item, let vin = extractVIN(from: text.transcript) {
                    hasDetected = true
                    parent.onVINDetected(vin)
                    return
                }
            }
        }

        // VIN: 17 chars, A-Z excluding I/O/Q, plus digits
        private func extractVIN(from text: String) -> String? {
            let pattern = "[A-HJ-NPR-Z0-9]{17}"
            guard let regex = try? NSRegularExpression(pattern: pattern),
                  let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
                  let range = Range(match.range, in: text) else { return nil }
            return String(text[range])
        }
    }
}
