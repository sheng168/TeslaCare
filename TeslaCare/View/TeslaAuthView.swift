//
//  TeslaAuthView.swift
//  TeslaCare
//
//  Created by Jin on 5/8/26.
//

import SwiftUI
import SwiftData
import Combine
import Foundation
import OSLog
import TeslaSwift
import AuthenticationServices

private let logger = Logger(subsystem: "com.teslacare", category: "TeslaSync")

@MainActor
class TeslaAuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var vehicles: [Vehicle] = []
    @Published var vehicleData: [String: VehicleExtended] = [:]
    @Published var vehicleChargingSites: [String: NearbyChargingSites] = [:]
    
    private var api: TeslaSwift?
    private let clientID = "b7b3546b95f7-453c-ac19-5efbd8d3bd35"
    private let clientSecret = "ta-secret.6zpdiNudRJvDZ-P_"
    private let redirectURI = "teslacare://fob.jsy.us/login"

    private var modelContext: ModelContext?

    init() {
        setupAPI()
    }

    /// Called once the SwiftData ModelContext is available (from TeslaCareApp.onAppear).
    func setup(context: ModelContext) {
        guard modelContext == nil else { return }
        modelContext = context
        checkExistingAuth()
    }

    private func setupAPI() {
        api = TeslaSwift(teslaAPI: .fleetAPI(
            region: .northAmericaAsiaPacific,
            clientID: clientID,
            clientSecret: clientSecret,
            redirectURI: redirectURI,
            scopes: [.vehicleDeviceData, .vehicleCmds]
        ))
        api?.debuggingEnabled = true
    }

    private func credential() -> TeslaCredential {
        let existing = try? modelContext?.fetch(FetchDescriptor<TeslaCredential>())
        if let cred = existing?.first { return cred }
        let cred = TeslaCredential()
        modelContext?.insert(cred)
        return cred
    }

    private func saveTokens(access: String?, refresh: String?, expiry: Double?) {
        let cred = credential()
        cred.accessToken = access
        cred.refreshToken = refresh
        cred.tokenExpiry = expiry
    }

    private func checkExistingAuth() {
        let cred = credential()
        guard let accessToken = cred.accessToken,
              let refreshToken = cred.refreshToken,
              let expiry = cred.tokenExpiry else {
            isAuthenticated = false
            return
        }

        let expiryDate = Date(timeIntervalSince1970: expiry)
        if expiryDate > Date() {
            let token = AuthToken(accessToken: accessToken)
            token.refreshToken = refreshToken
            api?.reuse(token: token)
            isAuthenticated = true
            Task { await fetchVehicles() }
        } else {
            Task { _ = try? await api?.refreshToken() }
        }
    }

    func getAuthorizationURL() -> URL? {
        return api?.authenticateWebNativeURL()
    }

    func authenticate(callbackURL: URL) async {
        guard let api = api else {
            errorMessage = "API not initialized"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let token = try await api.authenticateWebNative(url: callbackURL)
            let expiry = token.expiresIn.map { Date().addingTimeInterval($0).timeIntervalSince1970 }
            saveTokens(access: token.accessToken, refresh: token.refreshToken, expiry: expiry)
            isAuthenticated = true
            await fetchVehicles()
        } catch {
            errorMessage = "Authentication failed: \(error.localizedDescription)"
            isAuthenticated = false
        }

        isLoading = false
    }

    func refreshToken() async {
        guard let api = api, credential().refreshToken != nil else {
            logout()
            return
        }

        do {
            _ = try await api.refreshToken()
            if let token = api.token {
                let expiry = token.expiresIn.map { Date().addingTimeInterval($0).timeIntervalSince1970 }
                saveTokens(access: token.accessToken, refresh: token.refreshToken, expiry: expiry)
                isAuthenticated = true
            }
        } catch {
            logger.error("Token refresh failed: \(error)")
            logout()
        }
    }
    
    func fetchVehicles() async {
        guard let api = api else {
            logger.warning("fetchVehicles: api is nil — not authenticated?")
            return
        }

        logger.info("fetchVehicles: starting")
        isLoading = true
        errorMessage = nil

        do {
            let fetchedVehicles = try await api.getVehicles()
            logger.info("fetchVehicles: got \(fetchedVehicles.count) vehicle(s)")
            vehicles = fetchedVehicles
            await fetchExtendedData(for: fetchedVehicles)
        } catch {
            logger.error("fetchVehicles: \(error)")
            errorMessage = "Failed to fetch vehicles: \(error.localizedDescription)"
        }

        isLoading = false
        logger.info("fetchVehicles: done")
    }

    private func fetchExtendedData(for vehicles: [Vehicle]) async {
        guard let api else { return }
        logger.info("fetchExtendedData: fetching data for \(vehicles.count) vehicle(s)")
        await withTaskGroup(of: (String, VehicleExtended?, NearbyChargingSites?).self) { group in
            for vehicle in vehicles {
                guard let vin = vehicle.vin else { continue }
                group.addTask {
                    async let extended = try? api.getAllData(vehicle, endpoints: [.vehicleConfig, .vehicleState, .climateState, .driveState, .chargeState])
                    async let nearby = try? api.getNearbyChargingSites(vehicle)
                    return (vin, await extended, await nearby)
                }
            }
            for await (vin, data, nearby) in group {
                logger.info("fetchExtendedData: vin=\(vin) extended=\(data != nil) nearby=\(nearby != nil)")
                if let data { vehicleData[vin] = data }
                if let nearby { vehicleChargingSites[vin] = nearby }
            }
        }
    }
    
    func logout() {
        saveTokens(access: nil, refresh: nil, expiry: nil)
        isAuthenticated = false
        vehicles = []
        vehicleData = [:]
        if let api = api {
            api.reuse(token: AuthToken(accessToken: ""))
        }
    }

    // MARK: - Daily Sync

    @AppStorage("lastTeslaSyncDate") var lastSyncDate: Double = 0

    var needsDailySync: Bool {
        Date().timeIntervalSince1970 - lastSyncDate > 86400
    }

    func syncCars(into context: ModelContext) {
        logger.info("syncCars: \(self.vehicles.count) vehicle(s), \(self.vehicleData.count) with extended data")
        for vehicle in vehicles {
            guard let vin = vehicle.vin else { continue }
            logger.info("syncCars: processing vin=\(vin)")

            let predicate = #Predicate<Car> { $0.vin == vin }
            let existing = (try? context.fetch(FetchDescriptor(predicate: predicate)))?.first

            let vehicleState = vehicleData[vin]?.vehicleState

            let car: Car
            if let existing {
                car = existing
            } else {
                car = Car(name: "", make: "Tesla", model: "", year: 0)
                car.vin = vin
                context.insert(car)
            }

            if let displayName = vehicle.displayName, !displayName.isEmpty {
                car.name = displayName
            }
            car.make = "Tesla"
            if let model = vinModel(vin) { car.model = model }
            if let year = vinYear(vin) { car.year = year }
            if let config = vehicleData[vin]?.vehicleConfig {
                if let trim = config.trimBadging { car.trimBadging = trim }
                if let perf = config.perfConfig { car.perfConfig = perf }
            }

            if let odometer = vehicleState?.odometer {
                let reading = MileageReading(date: Date(), mileage: Int(odometer), source: "tesla_api")
                reading.car = car
                context.insert(reading)
            }
            if let state = vehicleState, state.tpms_pressure_fl != nil {
                let reading = TPMSReading(
                    date: Date(),
                    frontLeft: state.tpms_pressure_fl,
                    frontRight: state.tpms_pressure_fr,
                    rearLeft: state.tpms_pressure_rl,
                    rearRight: state.tpms_pressure_rr,
                    outsideTemperature: vehicleData[vin]?.climateState?.outsideTemperature?.value.converted(to: .celsius).value
                )
                reading.car = car
                context.insert(reading)
            }
            if let charge = vehicleData[vin]?.chargeState {
                if let level = charge.batteryLevel { car.batteryLevel = level }
                if let state = charge.chargingState { car.chargingState = state.rawValue }
            }
            if let driveState = vehicleData[vin]?.driveState {
                if let lat = driveState.latitude { car.latitude = lat }
                if let lon = driveState.longitude { car.longitude = lon }
                if let hdg = driveState.heading { car.heading = hdg }
                if driveState.latitude != nil { car.locationUpdatedAt = Date() }
            }
            // Replace nearby charger records with fresh data
            if let sites = vehicleChargingSites[vin] {
                // Remove stale records
                let stale = car.nearbyChargers ?? []
                for old in stale { context.delete(old) }

                let superchargers = (sites.superchargers ?? []).map { sc in
                    NearbyCharger(
                        name: sc.name ?? "Supercharger",
                        chargerType: "supercharger",
                        rawType: sc.type,
                        latitude: sc.location?.latitude,
                        longitude: sc.location?.longitude,
                        distanceMiles: sc.distance?.miles ?? 0,
                        availableStalls: sc.availableStalls,
                        totalStalls: sc.totalStalls,
                        siteClosed: sc.siteClosed ?? false
                    )
                }
                let destinations = (sites.destinationChargers ?? []).map { dc in
                    NearbyCharger(
                        name: dc.name ?? "Destination Charger",
                        chargerType: "destination",
                        rawType: dc.type,
                        latitude: dc.location?.latitude,
                        longitude: dc.location?.longitude,
                        distanceMiles: dc.distance?.miles ?? 0,
                        availableStalls: nil,
                        totalStalls: nil,
                        siteClosed: false
                    )
                }
                for charger in superchargers + destinations {
                    charger.car = car
                    context.insert(charger)
                }
            }

            NotificationManager.scheduleUpdateReminder(for: car)
        }
        lastSyncDate = Date().timeIntervalSince1970
    }

    func vinYear(_ vin: String) -> Int? {
        guard vin.count >= 10 else { return nil }
        let yearChar = vin[vin.index(vin.startIndex, offsetBy: 9)]
        let yearMap: [Character: Int] = [
            "A": 2010, "B": 2011, "C": 2012, "D": 2013, "E": 2014,
            "F": 2015, "G": 2016, "H": 2017, "J": 2018, "K": 2019,
            "L": 2020, "M": 2021, "N": 2022, "P": 2023, "R": 2024,
            "S": 2025, "T": 2026
        ]
        return yearMap[yearChar]
    }

    func vinModel(_ vin: String) -> String? {
        guard vin.count >= 4 else { return nil }
        let modelChar = vin[vin.index(vin.startIndex, offsetBy: 3)]
        switch modelChar {
        case "S": return "Model S"
        case "X": return "Model X"
        case "3": return "Model 3"
        case "Y": return "Model Y"
        case "C": return "Cybertruck"
        default:  return nil
        }
    }
}

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
        guard let authURL = authManager.getAuthorizationURL() else {
            authManager.errorMessage = "Failed to generate authorization URL"
            return
        }
        
        let provider = ASWebAuthenticationPresentationContextProvider { _ in
            #if os(iOS)
            // Find the active window scene's key window
            let windowScene = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first { $0.activationState == .foregroundActive }
            // windowScene should always be non-nil for a foreground app;
            // the UIWindow() fallback is an emergency safety net
            return windowScene?.windows.first { $0.isKeyWindow }
                ?? windowScene?.windows.first
                ?? UIApplication.shared.connectedScenes
                    .compactMap { $0 as? UIWindowScene }
                    .flatMap { $0.windows }
                    .first { $0.isKeyWindow }
                ?? UIWindow()
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
                authManager.errorMessage = "Authentication cancelled: \(error.localizedDescription)"
                return
            }
            
            guard let callbackURL = callbackURL else {
                authManager.errorMessage = "Failed to receive callback URL"
                return
            }
            
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

import SafariServices

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

#Preview("Not Authenticated") {
    TeslaAuthView()
        .environmentObject(TeslaAuthManager())
}

#Preview("Authenticated") {
    let manager = TeslaAuthManager()
    manager.isAuthenticated = true
    return TeslaAuthView()
        .environmentObject(manager)
}
