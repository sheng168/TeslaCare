//
//  TeslaAuthView.swift
//  TeslaCare
//
//  Created by Jin on 5/8/26.
//

import SwiftUI
import SwiftData
import OSLog
import TeslaSwift
import AuthenticationServices
import SafariServices

private let logger = Logger(subsystem: "com.teslacare", category: "TeslaSync")

struct TeslaAuthView: View {
    @EnvironmentObject private var authManager: TeslaAuthManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var showingWebAuth = false
    // Keep a strong reference so the presentation context provider isn't deallocated
    // while the ASWebAuthenticationSession is in progress
    @State private var authSession: ASWebAuthenticationSession?
    @State private var contextProvider: ASWebAuthenticationPresentationContextProvider?

    var body: some View {
        NavigationStack {
            Group {
                if authManager.isAuthenticated {
                    authenticatedView
                } else {
                    loginView
                }
            }
            .navigationTitle("Tesla Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .onChange(of: authManager.isLoading) { _, isLoading in
                if !isLoading && authManager.isAuthenticated && !authManager.vehicles.isEmpty {
                    syncCarsFromTesla()
                }
            }
        }
    }

    private var loginView: some View {
        VStack(spacing: 24) {
            Image(systemName: "bolt.car.fill")
                .font(.system(size: 80))
                .foregroundStyle(.blue)

            Text("Connect Your Tesla")
                .font(.title2)
                .fontWeight(.bold)

            Text("Sign in with your Tesla account to automatically sync your vehicle information and tire data.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            if let errorMessage = authManager.errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
            }

            Button {
                startAuthentication()
            } label: {
                HStack {
                    if authManager.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "person.badge.key.fill")
                        Text("Sign In with Tesla")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(authManager.isLoading)
            .padding(.horizontal)
        }
        .padding()
    }

    private var authenticatedView: some View {
        List {
            Section {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Connected to Tesla")
                        .fontWeight(.medium)
                }
            }

            Section("Your Vehicles") {
                if authManager.isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                } else if authManager.vehicles.isEmpty {
                    Text("No vehicles found")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(authManager.vehicles.indices, id: \.self) { index in
                        let vehicle = authManager.vehicles[index]
                        let extended = vehicle.vin.flatMap { authManager.vehicleData[$0] }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(vehicle.displayName ?? "Tesla Vehicle")
                                .font(.headline)
                            if let vin = vehicle.vin {
                                let year = authManager.vinYear(vin)
                                let model = authManager.vinModel(vin)
                                Text("\(year.map(String.init) ?? "Tesla") Tesla \(model ?? "Vehicle")")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                if let trim = extended?.vehicleConfig?.trimBadging {
                                    Text(formatTrim(trim))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                if let odometer = extended?.vehicleState?.odometer {
                                    Text("\(Int(odometer).formatted()) mi")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                let vs = extended?.vehicleState
                                if vs?.tpms_pressure_fl != nil {
                                    HStack(spacing: 10) {
                                        tpmsBadge("FL", bar: vs?.tpms_pressure_fl)
                                        tpmsBadge("FR", bar: vs?.tpms_pressure_fr)
                                        tpmsBadge("RL", bar: vs?.tpms_pressure_rl)
                                        tpmsBadge("RR", bar: vs?.tpms_pressure_rr)
                                    }
                                    .padding(.top, 2)
                                }
                                Text("VIN: \(vin)")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            Section {
                Button {
                    Task {
                        await authManager.fetchVehicles()
                    }
                } label: {
                    Label("Refresh Vehicles", systemImage: "arrow.clockwise")
                }
                .disabled(authManager.isLoading)
            }

            Section {
                Button(role: .destructive) {
                    authManager.logout()
                } label: {
                    Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                }
            }
        }
    }

    private func syncCarsFromTesla() {
        logger.info("syncCarsFromTesla: triggered after vehicle load")
        authManager.syncCars(into: modelContext)
    }

    private func formatTrim(_ badge: String) -> String {
        badge.replacingOccurrences(of: "_", with: " ").uppercased()
    }

    @ViewBuilder
    private func tpmsBadge(_ label: String, bar: Double?) -> some View {
        let psi = bar.map { $0 * 14.504 }
        let color: Color = {
            guard let psi else { return .secondary }
            if psi < 28 { return .red }
            if psi < 36 { return .orange }
            return .green
        }()
        VStack(spacing: 1) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(psi.map { String(format: "%.0f", $0) } ?? "--")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(color)
        }
    }

    private func startAuthentication() {
        logger.info("startAuthentication: initiating OAuth session")
        guard let authURL = authManager.getAuthorizationURL() else {
            logger.error("startAuthentication: failed to generate authorization URL")
            authManager.errorMessage = "Failed to generate authorization URL"
            return
        }

        let provider = ASWebAuthenticationPresentationContextProvider { _ in
            #if os(iOS)
            let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
            let activeScene = scenes.first { $0.activationState == .foregroundActive } ?? scenes.first
            let allWindows = scenes.flatMap { $0.windows }
            if let window = allWindows.first(where: { $0.isKeyWindow }) ?? allWindows.first {
                return window
            }
            guard let scene = activeScene else {
                fatalError("No UIWindowScene available — this cannot happen in a foreground app")
            }
            return UIWindow(windowScene: scene)
            #else
            return ASPresentationAnchor()
            #endif
        }
        // Retain the provider so it isn't deallocated before the session finishes
        contextProvider = provider

        let session = ASWebAuthenticationSession(
            url: authURL,
            callbackURLScheme: "teslacare"
        ) { [self] callbackURL, error in
            contextProvider = nil
            authSession = nil

            if let error = error {
                logger.error("startAuthentication: OAuth session error — \(error)")
                authManager.errorMessage = "Authentication cancelled: \(error.localizedDescription)"
                return
            }

            guard let callbackURL = callbackURL else {
                logger.error("startAuthentication: no callback URL received")
                authManager.errorMessage = "Failed to receive callback URL"
                return
            }
            logger.info("startAuthentication: received callback URL")

            // Pass the full callback URL — authenticateWebNative parses the code from it
            Task {
                await authManager.authenticate(callbackURL: callbackURL)
            }
        }

        session.presentationContextProvider = provider
        session.prefersEphemeralWebBrowserSession = false
        session.start()
        // Retain the session so it isn't cancelled before completing
        authSession = session
    }
}

// MARK: - Web Login UIViewControllerRepresentable

/// Wraps TeslaSwift's SFSafariViewController-based OAuth login flow.
/// Present this view to show the Tesla login page inline.
/// Handle the callback URL externally via `.onOpenURL` and call
/// `api.authenticateWebNative(url:)` to exchange it for an `AuthToken`.
struct TeslaWebLogin: UIViewControllerRepresentable {
    let api: TeslaSwift
    /// Called when the user dismisses the Safari view without completing login.
    var onCancel: () -> Void = {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onCancel: onCancel)
    }

    func makeUIViewController(context: Context) -> SFSafariViewController {
        guard let vc = api.authenticateWeb(delegate: context.coordinator) else {
            fatalError("TeslaSwift failed to produce an SFSafariViewController")
        }
        return vc
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}

    final class Coordinator: NSObject, SFSafariViewControllerDelegate {
        var onCancel: () -> Void

        init(onCancel: @escaping () -> Void) {
            self.onCancel = onCancel
        }

        func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
            onCancel()
        }
    }
}

// MARK: - Presentation Context Provider

private class ASWebAuthenticationPresentationContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    let provider: (ASWebAuthenticationSession) -> ASPresentationAnchor

    init(provider: @escaping (ASWebAuthenticationSession) -> ASPresentationAnchor) {
        self.provider = provider
    }

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return provider(session)
    }
}

// MARK: - Previews

#Preview {
    TeslaAuthView()
        .environmentObject(TeslaAuthManager())
}
