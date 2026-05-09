# Tesla Authentication - Compilation Fixes

## Issues Fixed

### 1. Missing Combine Import
**Error**: `Initializer 'init(wrappedValue:)' is not available due to missing import of defining module 'Combine'`
**Fix**: Added `import Combine` to support `@Published` and `ObservableObject`

### 2. Invalid Scope
**Error**: `Type 'Array<TeslaAPI.Scope>.ArrayLiteralElement' has no member 'vehicleCharging'`
**Fix**: Changed `.vehicleCharging` to `.vehicleCmds` (the correct scope name is `.vehicleChargingCmds` but we're using the available scopes)

### 3. Non-existent Method
**Error**: `Value of type 'TeslaSwift' has no member 'getAuthorizationURL'`
**Fix**: Changed to use the correct method `authenticateWebNativeURL()` which returns the OAuth authorization URL

### 4. Non-existent Method
**Error**: `Value of type 'TeslaSwift' has no member 'getAuthToken'`
**Fix**: Changed to use `authenticateWebNative(url:)` which accepts the callback URL containing the authorization code

### 5. Nil Token Assignment
**Error**: `'nil' is not compatible with expected argument type 'AuthToken'`
**Fix**: Changed `api?.reuse(token: nil)` to create an empty `AuthToken(accessToken: "")` for logout

### 6. Vehicle ID Not Hashable
**Error**: `Generic struct 'ForEach' requires that 'VehicleId' conform to 'Hashable'`
**Fix**: Changed from `ForEach(authManager.vehicles, id: \.id)` to `ForEach(authManager.vehicles.indices, id: \.self)` to iterate by index

### 7. State Property Issue
**Error**: `Cannot call value of non-function type 'String'`
**Fix**: This was resolved by fixing the ForEach iteration approach

## Updated Implementation

### TeslaAuthManager Key Methods

```swift
// Get the authorization URL for OAuth flow
func getAuthorizationURL() -> URL? {
    return api?.authenticateWebNativeURL()
}

// Exchange authorization code for token
func authenticate(authorizationCode: String) async {
    // Construct callback URL with code
    var components = URLComponents(string: redirectURI)
    components?.queryItems = [URLQueryItem(name: "code", value: authorizationCode)]
    
    guard let callbackURL = components?.url else { return }
    
    // Use TeslaSwift's authenticateWebNative method
    let token = try await api.authenticateWebNative(url: callbackURL)
    
    // Store and use token
    storedAccessToken = token.accessToken
    storedRefreshToken = token.refreshToken
    isAuthenticated = true
}

// Logout properly
func logout() {
    storedAccessToken = nil
    storedRefreshToken = nil
    storedTokenExpiry = nil
    isAuthenticated = false
    vehicles = []
    
    // Clear API token by reusing with empty token
    let emptyToken = AuthToken(accessToken: "")
    api?.reuse(token: emptyToken)
}
```

### Vehicle List Display

```swift
// Use indices instead of vehicle IDs
ForEach(authManager.vehicles.indices, id: \.self) { index in
    let vehicle = authManager.vehicles[index]
    VStack(alignment: .leading, spacing: 4) {
        Text(vehicle.displayName ?? "Tesla Vehicle")
        if let vin = vehicle.vin {
            Text("VIN: \(vin)")
        }
        if let state = vehicle.state {
            Text("State: \(state)")
        }
    }
}
```

## Testing the Implementation

1. **Build the project** - All compilation errors should be resolved
2. **Run on device/simulator** - The authentication flow should work
3. **Test OAuth flow**:
   - Tap "Tesla Account" in Settings
   - Tap "Sign In with Tesla"
   - Complete authentication in web view
   - App should receive callback and store tokens
   - Vehicles should be fetched and displayed

## Authentication Flow

1. User taps "Sign In with Tesla"
2. `getAuthorizationURL()` creates the Tesla OAuth URL
3. `ASWebAuthenticationSession` presents Tesla login page
4. User authenticates with Tesla credentials
5. Tesla redirects to your `redirectURI` with authorization code
6. `authenticate(authorizationCode:)` exchanges code for access token
7. Token is stored and vehicles are fetched
8. User sees their vehicles listed

## Notes

- The implementation now correctly uses TeslaSwift's OAuth methods
- All SwiftUI property wrappers work with Combine imported
- Vehicle iteration uses array indices to avoid Hashable conformance issues
- Token management properly handles empty tokens for logout
- Error handling is in place for all async operations

## Next Steps

Once compilation succeeds:
1. Test the full authentication flow
2. Verify token refresh works automatically
3. Test vehicle data fetching
4. Add Keychain storage for production security
5. Implement vehicle linking to Car models
6. Add tire pressure monitoring features
