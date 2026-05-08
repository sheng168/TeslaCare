# Tesla Integration Quick Start Guide

## 🚀 Quick Start for Developers

This guide will help you understand and work with the Tesla account integration feature in TeslaCare.

## Overview

The Tesla integration consists of 3 main components:
1. **TeslaAuthManager** - Authentication and API management
2. **TeslaLoginView** - User interface for login
3. **TeslaVehicleSelectionView** - Vehicle selection and import

## File Structure

```
TeslaCare/
├── TeslaAuthManager.swift       # Core authentication logic
├── TeslaLoginView.swift         # Login UI + Vehicle Selection
├── ContentView.swift            # Main view (modified)
├── SettingsView.swift           # Settings (modified)
├── TESLA_INTEGRATION.md         # Full documentation
├── IMPLEMENTATION_NOTES.md      # Technical details
└── TeslaIntegrationTests.swift  # Test suite
```

## Basic Usage

### 1. User Login Flow

```swift
// User taps "Connect Tesla Account"
@State private var showingTeslaLogin = false

Button("Connect Tesla") {
    showingTeslaLogin = true
}
.sheet(isPresented: $showingTeslaLogin) {
    TeslaLoginView()
}
```

### 2. Check Authentication Status

```swift
let authManager = TeslaAuthManager.shared

if authManager.isAuthenticated {
    // User is logged in
    Text("Connected as \(authManager.currentUser ?? "User")")
} else {
    // User needs to log in
    Button("Connect Tesla Account") {
        // Show login
    }
}
```

### 3. Fetch Vehicles

```swift
Task {
    do {
        try await authManager.fetchVehicles()
        // authManager.vehicles now contains TeslaVehicle objects
        print("Found \(authManager.vehicles.count) vehicles")
    } catch {
        print("Error: \(error.localizedDescription)")
    }
}
```

### 4. Convert to Car Model

```swift
for vehicle in authManager.vehicles {
    let car = Car(
        name: vehicle.display_name ?? vehicle.modelName,
        make: "Tesla",
        model: vehicle.modelName,
        year: vehicle.year
    )
    modelContext.insert(car)
}
```

## API Reference

### TeslaAuthManager

```swift
class TeslaAuthManager: @Observable {
    // Properties
    var isAuthenticated: Bool
    var currentUser: String?
    var vehicles: [TeslaVehicle]
    var isLoading: Bool
    var errorMessage: String?
    
    // Methods
    func login(email: String, password: String) async throws
    func fetchVehicles() async throws
    func logout()
}
```

### TeslaVehicle

```swift
struct TeslaVehicle: Codable, Identifiable {
    let id: Int64
    let vin: String
    let display_name: String?
    
    // Computed properties
    var modelName: String    // "Model S", "Model 3", etc.
    var year: Int           // Parsed from VIN
}
```

### TeslaError

```swift
enum TeslaError: LocalizedError {
    case invalidURL
    case invalidResponse
    case notAuthenticated
    case authenticationFailed(String)
    case fetchFailed(String)
    case refreshFailed
}
```

## Common Tasks

### Task 1: Add Login Button

```swift
Button {
    showingTeslaLogin = true
} label: {
    Label("Connect Tesla Account", systemImage: "bolt.car.fill")
}
.sheet(isPresented: $showingTeslaLogin) {
    TeslaLoginView()
}
```

### Task 2: Display Connection Status

```swift
Section("Tesla Account") {
    if authManager.isAuthenticated {
        HStack {
            Text("Connected")
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        }
        
        if let email = authManager.currentUser {
            Text(email)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    } else {
        Text("Not connected")
            .foregroundStyle(.secondary)
    }
}
```

### Task 3: Handle Login Errors

```swift
do {
    try await authManager.login(email: email, password: password)
    // Success!
} catch TeslaError.authenticationFailed(let message) {
    errorMessage = "Login failed: \(message)"
} catch TeslaError.notAuthenticated {
    errorMessage = "Please check your credentials"
} catch {
    errorMessage = "An unexpected error occurred"
}
```

### Task 4: Sync Vehicles

```swift
Button {
    Task {
        isLoading = true
        do {
            try await authManager.fetchVehicles()
            // Update UI with new vehicles
        } catch {
            showError = true
        }
        isLoading = false
    }
} label: {
    if isLoading {
        ProgressView()
    } else {
        Label("Sync Vehicles", systemImage: "arrow.triangle.2.circlepath")
    }
}
```

### Task 5: Logout

```swift
Button("Disconnect Account", role: .destructive) {
    authManager.logout()
}
```

## Testing

### Run Tests

```swift
// Run all Tesla integration tests
@Test("Vehicle parsing")
func testVehicleParsing() async throws {
    let vehicle = TeslaVehicle(
        id: 1,
        vehicle_id: 123,
        vin: "5YJSA1E2SMFXXXXXX",
        display_name: "Test",
        option_codes: "MS",
        color: "Red",
        state: "online"
    )
    
    #expect(vehicle.modelName == "Model S")
    #expect(vehicle.year == 2025)
}
```

### Mock Network Responses

```swift
// For testing without real API calls
let mockResponse = """
{
    "response": [
        {
            "id": 1,
            "vehicle_id": 123,
            "vin": "5YJSA1E2SMFXXXXXX",
            "display_name": "Test Car",
            "option_codes": "MS",
            "color": "Red",
            "state": "online"
        }
    ],
    "count": 1
}
"""
```

## Debugging

### Enable Logging

```swift
// Add to TeslaAuthManager methods
print("🔐 Attempting login for: \(email)")
print("🚗 Fetched \(vehicles.count) vehicles")
print("❌ Error: \(error.localizedDescription)")
```

### Check Token Status

```swift
// In TeslaAuthManager
private func debugTokens() {
    print("Access Token: \(accessToken != nil ? "✓" : "✗")")
    print("Refresh Token: \(refreshToken != nil ? "✓" : "✗")")
    print("Is Authenticated: \(isAuthenticated)")
}
```

### Network Request Inspection

```swift
// Add before making request
print("📡 Request URL: \(url)")
print("📡 Headers: \(request.allHTTPHeaderFields ?? [:])")

// Add after receiving response
print("📥 Response Code: \(httpResponse.statusCode)")
print("📥 Response Body: \(String(data: data, encoding: .utf8) ?? "")")
```

## Troubleshooting

### Issue: Login Fails Immediately

**Check:**
- Internet connection
- Correct email/password
- API endpoint URLs are correct

**Solution:**
```swift
// Add error logging in login method
catch {
    print("Login error details: \(error)")
    errorMessage = error.localizedDescription
}
```

### Issue: Vehicles Don't Appear

**Check:**
- `fetchVehicles()` was called after login
- API returned 200 status
- Vehicles array is being updated

**Solution:**
```swift
// After fetchVehicles
print("Vehicles fetched: \(authManager.vehicles.count)")
for vehicle in authManager.vehicles {
    print("  - \(vehicle.display_name ?? vehicle.modelName)")
}
```

### Issue: Token Expired

**Check:**
- Token refresh logic is working
- Refresh token is valid

**Solution:**
```swift
// Manually trigger refresh
try await authManager.refreshAccessToken()
```

## Best Practices

### 1. Handle Loading States

```swift
@State private var isLoading = false

if isLoading {
    ProgressView()
} else {
    Button("Login") {
        // ...
    }
}
```

### 2. Show User-Friendly Errors

```swift
if let errorMessage = authManager.errorMessage {
    Label {
        Text(errorMessage)
    } icon: {
        Image(systemName: "exclamationmark.triangle.fill")
            .foregroundStyle(.red)
    }
}
```

### 3. Use Task for Async Operations

```swift
Button("Sync") {
    Task {
        try? await authManager.fetchVehicles()
    }
}
```

### 4. Cancel In-Flight Requests

```swift
@State private var syncTask: Task<Void, Never>?

Button("Sync") {
    syncTask?.cancel()
    syncTask = Task {
        try? await authManager.fetchVehicles()
    }
}

.onDisappear {
    syncTask?.cancel()
}
```

### 5. Secure Token Storage

```swift
// TODO: Migrate from UserDefaults to Keychain
// import Security

func saveToKeychain(key: String, value: String) {
    let data = value.data(using: .utf8)!
    let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrAccount as String: key,
        kSecValueData as String: data
    ]
    
    SecItemDelete(query as CFDictionary)
    SecItemAdd(query as CFDictionary, nil)
}
```

## Integration Checklist

### For New Features

- [ ] Check if user is authenticated
- [ ] Handle unauthenticated state
- [ ] Show loading indicators
- [ ] Handle errors gracefully
- [ ] Update UI on success
- [ ] Test with no internet
- [ ] Test with expired tokens
- [ ] Add appropriate logging
- [ ] Write unit tests
- [ ] Update documentation

## Advanced Topics

### Custom API Endpoints

```swift
// Add to TeslaAuthManager
func fetchVehicleDetails(id: Int64) async throws -> VehicleDetails {
    let url = "https://owner-api.teslamotors.com/api/1/vehicles/\(id)/data"
    // Implementation...
}
```

### Background Refresh

```swift
// Add to app delegate or scene
import BackgroundTasks

BGTaskScheduler.shared.register(
    forTaskWithIdentifier: "com.teslacare.vehiclesync",
    using: nil
) { task in
    Task {
        try? await TeslaAuthManager.shared.fetchVehicles()
        task.setTaskCompleted(success: true)
    }
}
```

### Multiple Accounts (Future)

```swift
// Multiple auth manager instances
class TeslaAccountManager {
    var accounts: [TeslaAuthManager] = []
    
    func addAccount(_ manager: TeslaAuthManager) {
        accounts.append(manager)
    }
}
```

## Resources

- **Full Documentation**: [TESLA_INTEGRATION.md](TESLA_INTEGRATION.md)
- **Implementation Notes**: [IMPLEMENTATION_NOTES.md](IMPLEMENTATION_NOTES.md)
- **Tests**: [TeslaIntegrationTests.swift](TeslaIntegrationTests.swift)
- **Tesla API Docs**: Community-maintained wikis (unofficial)
- **SwiftUI Docs**: https://developer.apple.com/documentation/swiftui
- **Swift Concurrency**: https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html

## Support

**Questions?** Open an issue on GitHub or contact support@teslacare.example.com

**Found a bug?** Check existing issues or create a new one with:
- Steps to reproduce
- Expected vs actual behavior
- iOS version and device
- Relevant code snippets or logs

## Contributing

When adding features to Tesla integration:

1. Update this guide
2. Add tests
3. Update TESLA_INTEGRATION.md
4. Test with real Tesla account (if possible)
5. Test error cases
6. Check performance impact

---

**Last Updated**: May 8, 2026  
**Version**: 1.0.0  
**Status**: Active Development
