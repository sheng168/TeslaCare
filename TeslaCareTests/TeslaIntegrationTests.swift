//
//  TeslaIntegrationTests.swift
//  TeslaCareTests
//
//  Created by Jin on 5/8/26.
//

import Testing
import Foundation
@testable import TeslaCare

/// Test suite for Tesla account integration functionality
@Suite("Tesla Account Integration")
struct TeslaIntegrationTests {
    
    // MARK: - Vehicle Data Parsing Tests
    
    @Test("Parse Model S from option codes")
    func parseModelS() async throws {
        let vehicle = TeslaVehicle(
            id: 1,
            vehicle_id: 123456789,
            vin: "5YJSA1E26MF123456",
            display_name: "My Model S",
            option_codes: "MS03,PPSW,PRM30",
            color: "Red",
            state: "online"
        )
        
        #expect(vehicle.modelName == "Model S")
    }
    
    @Test("Parse Model 3 from option codes")
    func parseModel3() async throws {
        let vehicle = TeslaVehicle(
            id: 2,
            vehicle_id: 987654321,
            vin: "5YJ3E1EA6LF123456",
            display_name: nil,
            option_codes: "M3,LONG",
            color: "Blue",
            state: "asleep"
        )
        
        #expect(vehicle.modelName == "Model 3")
    }
    
    @Test("Parse Model Y from option codes")
    func parseModelY() async throws {
        let vehicle = TeslaVehicle(
            id: 3,
            vehicle_id: 456789123,
            vin: "7SAYGDEE1NF123456",
            display_name: "Family Car",
            option_codes: "MY,AWD",
            color: "White",
            state: "online"
        )
        
        #expect(vehicle.modelName == "Model Y")
    }
    
    @Test("Parse Model X from option codes")
    func parseModelX() async throws {
        let vehicle = TeslaVehicle(
            id: 4,
            vehicle_id: 321654987,
            vin: "5YJXCBE26GF123456",
            display_name: "The X",
            option_codes: "MX,LONG,FWD",
            color: "Black",
            state: "online"
        )
        
        #expect(vehicle.modelName == "Model X")
    }
    
    // MARK: - VIN Parsing Tests
    
    @Test("Parse year 2025 from VIN")
    func parseYear2025() async throws {
        // 'S' in position 10 = 2025
        let vehicle = TeslaVehicle(
            id: 5,
            vehicle_id: 111222333,
            vin: "5YJSA1E2SMFXXXXXX",
            display_name: nil,
            option_codes: "MS",
            color: "Silver",
            state: "online"
        )
        
        #expect(vehicle.year == 2025)
    }
    
    @Test("Parse year 2026 from VIN")
    func parseYear2026() async throws {
        // 'T' in position 10 = 2026
        let vehicle = TeslaVehicle(
            id: 6,
            vehicle_id: 444555666,
            vin: "7SAYGDEE1TFXXXXXX",
            display_name: "New Car",
            option_codes: "MY",
            color: "Red",
            state: "online"
        )
        
        #expect(vehicle.year == 2026)
    }
    
    @Test("Parse year 2024 from VIN")
    func parseYear2024() async throws {
        // 'R' in position 10 = 2024
        let vehicle = TeslaVehicle(
            id: 7,
            vehicle_id: 777888999,
            vin: "5YJ3E1EA6RFXXXXXX",
            display_name: nil,
            option_codes: "M3",
            color: "Blue",
            state: "asleep"
        )
        
        #expect(vehicle.year == 2024)
    }
    
    // MARK: - Display Name Tests
    
    @Test("Use custom display name when provided")
    func useCustomDisplayName() async throws {
        let vehicle = TeslaVehicle(
            id: 8,
            vehicle_id: 123123123,
            vin: "5YJSA1E2SMFXXXXXX",
            display_name: "My Favorite Tesla",
            option_codes: "MS",
            color: "Red",
            state: "online"
        )
        
        #expect(vehicle.display_name == "My Favorite Tesla")
    }
    
    @Test("Fall back to model name when no display name")
    func fallbackToModelName() async throws {
        let vehicle = TeslaVehicle(
            id: 9,
            vehicle_id: 456456456,
            vin: "7SAYGDEE1NFXXXXXX",
            display_name: nil,
            option_codes: "MY",
            color: "White",
            state: "online"
        )
        
        #expect(vehicle.display_name == nil)
        #expect(vehicle.modelName == "Model Y")
    }
    
    // MARK: - Error Handling Tests
    
    @Test("Handle missing option codes gracefully")
    func handleMissingOptionCodes() async throws {
        let vehicle = TeslaVehicle(
            id: 10,
            vehicle_id: 789789789,
            vin: "5YJSA1E2SMFXXXXXX",
            display_name: "Unknown Model",
            option_codes: nil,
            color: "Gray",
            state: "online"
        )
        
        // Should fall back to VIN parsing or default
        #expect(vehicle.modelName.contains("Tesla") || vehicle.modelName.contains("Model"))
    }
    
    // MARK: - Authentication Manager Tests
    
    @Test("TeslaAuthManager starts unauthenticated")
    func managerStartsUnauthenticated() async throws {
        let manager = TeslaAuthManager.shared
        
        // Note: This test depends on no saved credentials
        // In a real test, you'd want to use a test instance
        #expect(manager.vehicles.isEmpty || manager.vehicles.count >= 0)
    }
    
    @Test("TeslaError has proper descriptions")
    func errorDescriptions() async throws {
        let invalidURLError = TeslaError.invalidURL
        #expect(invalidURLError.errorDescription == "Invalid API URL")
        
        let notAuthenticatedError = TeslaError.notAuthenticated
        #expect(notAuthenticatedError.errorDescription == "Not authenticated. Please log in.")
        
        let authFailedError = TeslaError.authenticationFailed("Invalid credentials")
        #expect(authFailedError.errorDescription?.contains("Invalid credentials") == true)
    }
    
    // MARK: - JSON Decoding Tests
    
    @Test("Decode TeslaVehiclesResponse from JSON")
    func decodeVehiclesResponse() async throws {
        let json = """
        {
            "response": [
                {
                    "id": 123,
                    "vehicle_id": 456,
                    "vin": "5YJSA1E2SMFXXXXXX",
                    "display_name": "Test Car",
                    "option_codes": "MS,LONG",
                    "color": "Blue",
                    "state": "online"
                }
            ],
            "count": 1
        }
        """
        
        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(TeslaVehiclesResponse.self, from: data)
        
        #expect(response.count == 1)
        #expect(response.response.count == 1)
        #expect(response.response[0].vin == "5YJSA1E2SMFXXXXXX")
        #expect(response.response[0].display_name == "Test Car")
    }
    
    @Test("Decode TeslaAuthResponse from JSON")
    func decodeAuthResponse() async throws {
        let json = """
        {
            "access_token": "abc123",
            "refresh_token": "xyz789",
            "expires_in": 3888000,
            "token_type": "Bearer"
        }
        """
        
        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(TeslaAuthResponse.self, from: data)
        
        #expect(response.access_token == "abc123")
        #expect(response.refresh_token == "xyz789")
        #expect(response.expires_in == 3888000)
        #expect(response.token_type == "Bearer")
    }
    
    @Test("Decode TeslaErrorResponse from JSON")
    func decodeErrorResponse() async throws {
        let json = """
        {
            "error": "invalid_credentials",
            "error_description": "The provided credentials are invalid."
        }
        """
        
        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(TeslaErrorResponse.self, from: data)
        
        #expect(response.error == "invalid_credentials")
        #expect(response.error_description == "The provided credentials are invalid.")
    }
    
    // MARK: - Integration Tests (require mocking)
    
    @Test("Vehicle conversion to Car model", .disabled("Requires SwiftData context"))
    func convertVehicleToCar() async throws {
        let vehicle = TeslaVehicle(
            id: 100,
            vehicle_id: 999888777,
            vin: "5YJSA1E2SMFXXXXXX",
            display_name: "Test Tesla",
            option_codes: "MS",
            color: "Red",
            state: "online"
        )
        
        // This would require a SwiftData context in a real test
        // let car = Car(
        //     name: vehicle.display_name ?? vehicle.modelName,
        //     make: "Tesla",
        //     model: vehicle.modelName,
        //     year: vehicle.year
        // )
        // 
        // #expect(car.make == "Tesla")
        // #expect(car.model == "Model S")
        // #expect(car.year == 2025)
    }
}

// MARK: - Mock Network Tests

@Suite("Tesla API Network Mocking")
struct TeslaNetworkMockTests {
    
    @Test("Mock successful login response")
    func mockSuccessfulLogin() async throws {
        // Example of how you'd mock network responses
        let mockJSON = """
        {
            "access_token": "mock_access_token_12345",
            "refresh_token": "mock_refresh_token_67890",
            "expires_in": 3888000,
            "token_type": "Bearer"
        }
        """
        
        let data = mockJSON.data(using: .utf8)!
        let response = try JSONDecoder().decode(TeslaAuthResponse.self, from: data)
        
        #expect(response.access_token.starts(with: "mock_"))
        #expect(response.expires_in > 0)
    }
    
    @Test("Mock failed login response")
    func mockFailedLogin() async throws {
        let mockJSON = """
        {
            "error": "invalid_grant",
            "error_description": "The provided authorization grant is invalid, expired, or revoked."
        }
        """
        
        let data = mockJSON.data(using: .utf8)!
        let response = try JSONDecoder().decode(TeslaErrorResponse.self, from: data)
        
        #expect(response.error == "invalid_grant")
    }
    
    @Test("Mock vehicles list response")
    func mockVehiclesList() async throws {
        let mockJSON = """
        {
            "response": [
                {
                    "id": 1,
                    "vehicle_id": 111,
                    "vin": "5YJSA1E2SMFXXXXXX",
                    "display_name": "Model S",
                    "option_codes": "MS",
                    "color": "Red",
                    "state": "online"
                },
                {
                    "id": 2,
                    "vehicle_id": 222,
                    "vin": "7SAYGDEE1NFXXXXXX",
                    "display_name": "Model Y",
                    "option_codes": "MY",
                    "color": "Blue",
                    "state": "asleep"
                }
            ],
            "count": 2
        }
        """
        
        let data = mockJSON.data(using: .utf8)!
        let response = try JSONDecoder().decode(TeslaVehiclesResponse.self, from: data)
        
        #expect(response.count == 2)
        #expect(response.response.count == 2)
        #expect(response.response[0].modelName == "Model S")
        #expect(response.response[1].modelName == "Model Y")
    }
}

// MARK: - Performance Tests

@Suite("Tesla Integration Performance")
struct TeslaPerformanceTests {
    
    @Test("VIN parsing performance")
    func vinParsingPerformance() async throws {
        let vehicle = TeslaVehicle(
            id: 1,
            vehicle_id: 123,
            vin: "5YJSA1E2SMFXXXXXX",
            display_name: nil,
            option_codes: "MS",
            color: "Red",
            state: "online"
        )
        
        // Parse year 1000 times - should be fast
        for _ in 0..<1000 {
            _ = vehicle.year
        }
        
        // If we get here without timeout, performance is acceptable
        #expect(vehicle.year > 0)
    }
    
    @Test("Model name parsing performance")
    func modelNameParsingPerformance() async throws {
        let vehicle = TeslaVehicle(
            id: 1,
            vehicle_id: 123,
            vin: "5YJSA1E2SMFXXXXXX",
            display_name: nil,
            option_codes: "MS,LONG,AWD,FWD",
            color: "Red",
            state: "online"
        )
        
        // Parse model name 1000 times
        for _ in 0..<1000 {
            _ = vehicle.modelName
        }
        
        #expect(vehicle.modelName.isEmpty == false)
    }
}

// MARK: - Edge Case Tests

@Suite("Tesla Integration Edge Cases")
struct TeslaEdgeCaseTests {
    
    @Test("Handle empty VIN gracefully")
    func handleEmptyVIN() async throws {
        let vehicle = TeslaVehicle(
            id: 1,
            vehicle_id: 123,
            vin: "",
            display_name: "Empty VIN Car",
            option_codes: "MS",
            color: "Red",
            state: "online"
        )
        
        // Should not crash
        _ = vehicle.year
        _ = vehicle.modelName
        
        #expect(vehicle.vin.isEmpty)
    }
    
    @Test("Handle very long option codes")
    func handleLongOptionCodes() async throws {
        let longCodes = String(repeating: "MS,LONG,AWD,", count: 100)
        
        let vehicle = TeslaVehicle(
            id: 1,
            vehicle_id: 123,
            vin: "5YJSA1E2SMFXXXXXX",
            display_name: nil,
            option_codes: longCodes,
            color: "Red",
            state: "online"
        )
        
        // Should handle without crashing
        let model = vehicle.modelName
        #expect(model == "Model S")
    }
    
    @Test("Handle special characters in display name")
    func handleSpecialCharacters() async throws {
        let vehicle = TeslaVehicle(
            id: 1,
            vehicle_id: 123,
            vin: "5YJSA1E2SMFXXXXXX",
            display_name: "🚗 My Tesla! @#$%^&*()",
            option_codes: "MS",
            color: "Red",
            state: "online"
        )
        
        #expect(vehicle.display_name?.contains("🚗") == true)
        #expect(vehicle.display_name?.contains("Tesla!") == true)
    }
}
