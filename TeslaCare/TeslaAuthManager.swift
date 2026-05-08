//
//  TeslaAuthManager.swift
//  TeslaCare
//
//  Created by Jin on 5/8/26.
//

import Foundation
import SwiftUI

/// Manages Tesla account authentication and vehicle data fetching
@Observable
class TeslaAuthManager {
    var isAuthenticated = false
    var currentUser: String?
    var vehicles: [TeslaVehicle] = []
    var isLoading = false
    var errorMessage: String?
    
    // Tesla API endpoints
    private let authURL = "https://auth.tesla.com/oauth2/v3/token"
    private let vehiclesURL = "https://owner-api.teslamotors.com/api/1/vehicles"
    
    private var accessToken: String?
    private var refreshToken: String?
    
    // Singleton instance
    static let shared = TeslaAuthManager()
    
    private init() {
        // Load saved credentials if available
        loadSavedCredentials()
    }
    
    /// Authenticate with Tesla account
    func login(email: String, password: String) async throws {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        // Note: Tesla's actual OAuth flow requires client_id, client_secret, and may require
        // MFA support. This is a simplified implementation for demonstration.
        // In production, you'd use Tesla's official OAuth 2.0 flow with PKCE.
        
        let requestBody: [String: Any] = [
            "grant_type": "password",
            "client_id": "ownerapi", // Tesla's owner API client
            "email": email,
            "password": password
        ]
        
        guard let url = URL(string: authURL) else {
            throw TeslaError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TeslaError.invalidResponse
        }
        
        if httpResponse.statusCode == 200 {
            let authResponse = try JSONDecoder().decode(TeslaAuthResponse.self, from: data)
            accessToken = authResponse.access_token
            refreshToken = authResponse.refresh_token
            currentUser = email
            isAuthenticated = true
            
            // Save credentials securely
            saveCredentials()
            
            // Fetch vehicles
            try await fetchVehicles()
        } else {
            let errorResponse = try? JSONDecoder().decode(TeslaErrorResponse.self, from: data)
            throw TeslaError.authenticationFailed(errorResponse?.error_description ?? "Unknown error")
        }
    }
    
    /// Fetch user's Tesla vehicles
    func fetchVehicles() async throws {
        guard let token = accessToken else {
            throw TeslaError.notAuthenticated
        }
        
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        guard let url = URL(string: vehiclesURL) else {
            throw TeslaError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TeslaError.invalidResponse
        }
        
        if httpResponse.statusCode == 200 {
            let vehiclesResponse = try JSONDecoder().decode(TeslaVehiclesResponse.self, from: data)
            vehicles = vehiclesResponse.response
        } else if httpResponse.statusCode == 401 {
            // Token expired, try to refresh
            try await refreshAccessToken()
            try await fetchVehicles()
        } else {
            throw TeslaError.fetchFailed("Failed to fetch vehicles")
        }
    }
    
    /// Refresh the access token
    private func refreshAccessToken() async throws {
        guard let token = refreshToken else {
            throw TeslaError.notAuthenticated
        }
        
        let requestBody: [String: Any] = [
            "grant_type": "refresh_token",
            "client_id": "ownerapi",
            "refresh_token": token
        ]
        
        guard let url = URL(string: authURL) else {
            throw TeslaError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw TeslaError.refreshFailed
        }
        
        let authResponse = try JSONDecoder().decode(TeslaAuthResponse.self, from: data)
        accessToken = authResponse.access_token
        refreshToken = authResponse.refresh_token
        saveCredentials()
    }
    
    /// Log out and clear credentials
    func logout() {
        accessToken = nil
        refreshToken = nil
        currentUser = nil
        isAuthenticated = false
        vehicles = []
        clearSavedCredentials()
    }
    
    // MARK: - Keychain Storage
    
    private func saveCredentials() {
        // In production, use Keychain to securely store tokens
        UserDefaults.standard.set(accessToken, forKey: "tesla_access_token")
        UserDefaults.standard.set(refreshToken, forKey: "tesla_refresh_token")
        UserDefaults.standard.set(currentUser, forKey: "tesla_user_email")
        UserDefaults.standard.set(true, forKey: "tesla_is_authenticated")
    }
    
    private func loadSavedCredentials() {
        accessToken = UserDefaults.standard.string(forKey: "tesla_access_token")
        refreshToken = UserDefaults.standard.string(forKey: "tesla_refresh_token")
        currentUser = UserDefaults.standard.string(forKey: "tesla_user_email")
        isAuthenticated = UserDefaults.standard.bool(forKey: "tesla_is_authenticated")
        
        if isAuthenticated {
            Task {
                try? await fetchVehicles()
            }
        }
    }
    
    private func clearSavedCredentials() {
        UserDefaults.standard.removeObject(forKey: "tesla_access_token")
        UserDefaults.standard.removeObject(forKey: "tesla_refresh_token")
        UserDefaults.standard.removeObject(forKey: "tesla_user_email")
        UserDefaults.standard.removeObject(forKey: "tesla_is_authenticated")
    }
}

// MARK: - Data Models

struct TeslaVehicle: Codable, Identifiable {
    let id: Int64
    let vehicle_id: Int64
    let vin: String
    let display_name: String?
    let option_codes: String?
    let color: String?
    let state: String
    
    var modelName: String {
        // Parse model from option codes or VIN
        if let optionCodes = option_codes {
            if optionCodes.contains("MS") { return "Model S" }
            if optionCodes.contains("M3") { return "Model 3" }
            if optionCodes.contains("MX") { return "Model X" }
            if optionCodes.contains("MY") { return "Model Y" }
        }
        
        // Fallback to VIN parsing
        let vinPrefix = String(vin.prefix(3))
        switch vinPrefix {
        case "5YJ": return "Model S"
        case "5YJ", "7SA": return "Model 3"
        case "5YJ": return "Model X"
        case "7SA", "LRW": return "Model Y"
        default: return "Tesla"
        }
    }
    
    var year: Int {
        // Extract year from VIN (10th character)
        let yearCharacter = vin[vin.index(vin.startIndex, offsetBy: 9)]
        
        // VIN year encoding (simplified)
        let yearMap: [Character: Int] = [
            "L": 2020, "M": 2021, "N": 2022, "P": 2023,
            "R": 2024, "S": 2025, "T": 2026, "V": 2027
        ]
        
        return yearMap[yearCharacter] ?? Calendar.current.component(.year, from: Date())
    }
}

struct TeslaVehiclesResponse: Codable {
    let response: [TeslaVehicle]
    let count: Int
}

struct TeslaAuthResponse: Codable {
    let access_token: String
    let refresh_token: String
    let expires_in: Int
    let token_type: String
}

struct TeslaErrorResponse: Codable {
    let error: String
    let error_description: String
}

enum TeslaError: LocalizedError {
    case invalidURL
    case invalidResponse
    case notAuthenticated
    case authenticationFailed(String)
    case fetchFailed(String)
    case refreshFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from Tesla servers"
        case .notAuthenticated:
            return "Not authenticated. Please log in."
        case .authenticationFailed(let message):
            return "Login failed: \(message)"
        case .fetchFailed(let message):
            return message
        case .refreshFailed:
            return "Failed to refresh authentication"
        }
    }
}
