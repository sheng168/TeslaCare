//
//  TeslaAuthView.swift
//
//  Reusable Tesla OAuth sign-in component. Drop this file into any project
//  using TeslaSwift; supply an auth manager conforming to
//  `TeslaAuthenticating`, the app's redirect URL scheme, and a vehicle-row
//  view-builder.
//

import SwiftUI
import OSLog
import TeslaSwift
import AuthenticationServices
import SafariServices

// MARK: - Protocol

/// Minimum surface a Tesla auth manager must expose to drive `TeslaAuthView`.
@MainActor
public protocol TeslaAuthenticating: ObservableObject {
    var isAuthenticated: Bool { get }
    var isLoading: Bool { get }
    var errorMessage: String? { get set }
    var vehicles: [Vehicle] { get }

    func getAuthorizationURL() -> URL?
    func authenticate(callbackURL: URL) async
    func fetchVehicles() async
    func logout()
}

// MARK: - View

/// Tesla sign-in / vehicle list UI. Generic over any `TeslaAuthenticating`
/// manager and any vehicle-row view, so the same component works across apps.
public struct TeslaAuthView<Manager: TeslaAuthenticating, VehicleRow: View>: View {
    @ObservedObject private var authManager: Manager
    @Environment(\.dismiss) private var dismiss

    @State private var authSession: ASWebAuthenticationSession?
    @State private var contextProvider: AuthPresentationContextProvider?

    private let callbackURLScheme: String
    private let title: LocalizedStringKey
    private let signInPrompt: LocalizedStringKey
    private let signInDescription: LocalizedStringKey
    private let signInButtonLabel: LocalizedStringKey
    private let onVehiclesLoaded: () -> Void
    private let vehicleRow: (Vehicle) -> VehicleRow

    private static var logger: Logger {
        Logger(subsystem: Bundle.main.bundleIdentifier ?? "TeslaAuth", category: "TeslaAuthView")
    }

    public init(
        authManager: Manager,
        callbackURLScheme: String,
        title: LocalizedStringKey = "Tesla Account",
        signInPrompt: LocalizedStringKey = "Connect Your Tesla",
        signInDescription: LocalizedStringKey = "Sign in with your Tesla account to access your vehicle data.",
        signInButtonLabel: LocalizedStringKey = "Sign In with Tesla",
        onVehiclesLoaded: @escaping () -> Void = {},
        @ViewBuilder vehicleRow: @escaping (Vehicle) -> VehicleRow
    ) {
        self.authManager = authManager
        self.callbackURLScheme = callbackURLScheme
        self.title = title
        self.signInPrompt = signInPrompt
        self.signInDescription = signInDescription
        self.signInButtonLabel = signInButtonLabel
        self.onVehiclesLoaded = onVehiclesLoaded
        self.vehicleRow = vehicleRow
    }

    public var body: some View {
        NavigationStack {
            Group {
                if authManager.isAuthenticated {
                    authenticatedView
                } else {
                    loginView
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .onChange(of: authManager.isLoading) { _, isLoading in
                if !isLoading && authManager.isAuthenticated && !authManager.vehicles.isEmpty {
                    onVehiclesLoaded()
                }
            }
        }
    }

    private var loginView: some View {
        VStack(spacing: 24) {
            Image(systemName: "bolt.car.fill")
                .font(.system(size: 80))
                .foregroundStyle(.blue)

            Text(signInPrompt)
                .font(.title2)
                .fontWeight(.bold)

            Text(signInDescription)
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
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: "person.badge.key.fill")
                        Text(signInButtonLabel)
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
                        vehicleRow(authManager.vehicles[index])
                    }
                }
            }

            Section {
                Button {
                    Task { await authManager.fetchVehicles() }
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

    private func startAuthentication() {
        Self.logger.info("startAuthentication: initiating OAuth session")
        guard let authURL = authManager.getAuthorizationURL() else {
            Self.logger.error("startAuthentication: failed to generate authorization URL")
            authManager.errorMessage = "Failed to generate authorization URL"
            return
        }

        let provider = AuthPresentationContextProvider { _ in
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
        contextProvider = provider

        let session = ASWebAuthenticationSession(
            url: authURL,
            callbackURLScheme: callbackURLScheme
        ) { callbackURL, error in
            contextProvider = nil
            authSession = nil

            if let error = error {
                Self.logger.error("startAuthentication: OAuth session error — \(error)")
                authManager.errorMessage = "Authentication cancelled: \(error.localizedDescription)"
                return
            }

            guard let callbackURL = callbackURL else {
                Self.logger.error("startAuthentication: no callback URL received")
                authManager.errorMessage = "Failed to receive callback URL"
                return
            }
            Self.logger.info("startAuthentication: received callback URL")

            Task {
                await authManager.authenticate(callbackURL: callbackURL)
            }
        }

        session.presentationContextProvider = provider
        session.prefersEphemeralWebBrowserSession = false
        session.start()
        authSession = session
    }
}

// MARK: - Web Login (SFSafariViewController-based fallback)

/// Wraps TeslaSwift's SFSafariViewController-based OAuth login flow.
/// Present this view to show the Tesla login page inline. Handle the
/// callback URL externally via `.onOpenURL` and call
/// `api.authenticateWebNative(url:)` to exchange it for an `AuthToken`.
public struct TeslaWebLogin: UIViewControllerRepresentable {
    let api: TeslaSwift
    var onCancel: () -> Void = {}

    public init(api: TeslaSwift, onCancel: @escaping () -> Void = {}) {
        self.api = api
        self.onCancel = onCancel
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(onCancel: onCancel)
    }

    public func makeUIViewController(context: Context) -> SFSafariViewController {
        guard let vc = api.authenticateWeb(delegate: context.coordinator) else {
            fatalError("TeslaSwift failed to produce an SFSafariViewController")
        }
        return vc
    }

    public func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}

    public final class Coordinator: NSObject, SFSafariViewControllerDelegate {
        var onCancel: () -> Void

        init(onCancel: @escaping () -> Void) {
            self.onCancel = onCancel
        }

        public func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
            onCancel()
        }
    }
}

// MARK: - Presentation Context Provider

private final class AuthPresentationContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
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
    TeslaAuthView(
        authManager: TeslaAuthManager(),
        callbackURLScheme: "teslacare"
    ) { vehicle in
        Text(vehicle.displayName ?? "Tesla Vehicle")
            .padding(.vertical, 4)
    }
}
