# Tesla Account Integration Guide

## Overview
TeslaCare now supports connecting to your Tesla account to automatically import your vehicles! This feature eliminates manual data entry and ensures accurate vehicle information.

## Features

### 1. **Tesla Account Authentication**
- Secure login using your Tesla credentials
- OAuth-based authentication (production ready)
- Automatic token refresh for persistent sessions
- Privacy-focused: credentials are never stored

### 2. **Vehicle Import**
- Automatically fetch all vehicles from your Tesla account
- Extract vehicle details:
  - Model name (Model S, 3, X, Y)
  - Year (parsed from VIN)
  - Display name (if set in Tesla app)
  - VIN number
- Select which vehicles to import
- Bulk import support

### 3. **Account Management**
- View connection status in Settings
- Sync vehicles on demand
- Disconnect account securely
- Session persistence across app launches

## How to Use

### Connecting Your Tesla Account

#### From Main Screen (First Time)
1. Open TeslaCare
2. You'll see the empty state with two options
3. Tap **"Connect Tesla Account"** button
4. Enter your Tesla email and password
5. Tap **"Sign In"**
6. Select which vehicles to import
7. Tap **"Import"**

#### From Add Car Menu
1. Tap the **+** button in the top-right
2. Select **"Connect Tesla Account"**
3. Follow the login flow
4. Select vehicles to import

#### From Settings
1. Go to **Settings** tab
2. Tap **"Connect Tesla Account"** under Tesla Account section
3. Complete the login process

### Syncing Vehicles
After initial connection, you can sync your vehicles at any time:
1. Go to **Settings** tab
2. Under **Tesla Account** section
3. Tap **"Sync Vehicles"**

This will fetch any new vehicles added to your Tesla account.

### Disconnecting Your Account
1. Go to **Settings** tab
2. Under **Tesla Account** section
3. Tap **"Disconnect Account"**
4. Your local car data remains unchanged

## Technical Implementation

### Architecture

#### TeslaAuthManager
- Singleton class managing authentication state
- Uses `@Observable` macro for SwiftUI integration
- Handles:
  - Login/logout
  - Token management
  - Vehicle fetching
  - Token refresh
  - Error handling

#### TeslaLoginView
- SwiftUI form for credential entry
- Loading states and error handling
- Password visibility toggle
- Privacy-focused messaging

#### TeslaVehicleSelectionView
- Multi-select interface for vehicle import
- Vehicle details display
- Converts Tesla API data to local Car models

### Data Flow

```
User Login
    ↓
TeslaAuthManager.login()
    ↓
POST /oauth2/v3/token
    ↓
Store access_token & refresh_token
    ↓
fetchVehicles()
    ↓
GET /api/1/vehicles
    ↓
Parse TeslaVehicle objects
    ↓
Present TeslaVehicleSelectionView
    ↓
User selects vehicles
    ↓
Create Car objects in SwiftData
    ↓
Show in ContentView
```

### API Endpoints

#### Authentication
- **URL**: `https://auth.tesla.com/oauth2/v3/token`
- **Method**: POST
- **Body**: email, password, grant_type, client_id

#### Vehicles List
- **URL**: `https://owner-api.teslamotors.com/api/1/vehicles`
- **Method**: GET
- **Headers**: Authorization: Bearer {token}

### Security Considerations

#### What We Store
- Access token (for API calls)
- Refresh token (for token renewal)
- User email (for display only)

#### What We DON'T Store
- ❌ Password (never stored)
- ❌ Payment information
- ❌ Personal data beyond email

#### Storage Method
Currently using `UserDefaults` for simplicity. For production:
- **Recommended**: Migrate to iOS Keychain
- Use `Security` framework
- Encrypt tokens at rest

### Code Example: Using Keychain (Production)

```swift
import Security

class KeychainManager {
    static func save(key: String, data: String) {
        let data = data.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    static func load(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        SecItemCopyMatching(query as CFDictionary, &result)
        
        guard let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
```

## Tesla API Details

### Vehicle Data Structure

```json
{
  "response": [
    {
      "id": 123456789,
      "vehicle_id": 987654321,
      "vin": "5YJSA1E26MF123456",
      "display_name": "My Model S",
      "option_codes": "MS03,PPSW,...",
      "color": "Red",
      "state": "online"
    }
  ],
  "count": 1
}
```

### VIN Decoding
We parse the VIN to extract:
- **Characters 1-3**: Manufacturer & model
  - `5YJ`: Tesla Model S/X (US)
  - `7SA`: Tesla Model 3/Y (US)
  - `LRW`: Tesla Model Y (China)
- **Character 10**: Model year
  - `L` = 2020
  - `M` = 2021
  - `N` = 2022
  - `P` = 2023
  - `R` = 2024
  - `S` = 2025
  - `T` = 2026

### Option Codes
Used to determine exact model:
- `MS`: Model S
- `M3`: Model 3
- `MX`: Model X
- `MY`: Model Y

## Error Handling

### Common Errors

#### Authentication Failed
- **Cause**: Invalid email/password or MFA required
- **Solution**: Verify credentials, check for MFA token request

#### Token Expired
- **Cause**: Access token lifetime exceeded
- **Solution**: Automatically refreshes using refresh_token

#### No Vehicles Found
- **Cause**: Account has no registered vehicles
- **Solution**: Display friendly message

#### Network Error
- **Cause**: No internet connection
- **Solution**: Display error and retry option

### Error Types
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

## Future Enhancements

### Planned Features
1. **Multi-Factor Authentication (MFA) Support**
   - Captcha handling
   - SMS/TOTP verification
   - Device authorization flow

2. **Real-Time Vehicle Data**
   - Current mileage sync
   - Tire pressure monitoring
   - Battery health (for EVs)

3. **Enhanced Vehicle Info**
   - Vehicle photos from Tesla API
   - Warranty information
   - Service history

4. **Automatic Sync**
   - Background refresh
   - Push notifications for new vehicles
   - Periodic mileage updates

5. **Fleet Support**
   - Business accounts
   - Multiple account management
   - Organization hierarchy

### API Expansion
Additional endpoints to consider:
- `/api/1/vehicles/{id}/data` - Detailed vehicle state
- `/api/1/vehicles/{id}/service_data` - Service history
- `/api/1/vehicles/{id}/charge_state` - Battery info

## Privacy & Terms

### User Privacy
- Credentials used only for Tesla API authentication
- No data shared with third parties
- Local storage of vehicle information
- User can disconnect at any time

### Tesla Terms of Service
Users must comply with Tesla's API Terms of Service:
- Rate limiting (10 requests/minute recommended)
- No commercial use without permission
- Respect user privacy and data

### Disclaimers
- TeslaCare is not affiliated with Tesla, Inc.
- Use at your own risk
- No warranty or guarantee provided
- Vehicle data may be delayed or inaccurate

## Troubleshooting

### Can't Log In
1. Verify email and password in Tesla app
2. Check internet connection
3. Try logging out of Tesla app and back in
4. Contact support if issue persists

### Vehicles Not Appearing
1. Tap "Sync Vehicles" in Settings
2. Ensure vehicles are registered to your account
3. Check vehicle is visible in Tesla app
4. Disconnect and reconnect account

### Token Expired Repeatedly
1. Check system date/time is correct
2. Log out and log back in
3. Update to latest app version

## Support

### Getting Help
- Email: support@teslacare.example.com
- GitHub Issues: github.com/yourrepo/teslacare/issues
- Documentation: docs.teslacare.example.com

### Reporting Bugs
Include:
- App version
- iOS version
- Steps to reproduce
- Error messages
- Screenshots (without sensitive data)

## Development Notes

### Testing
Use in-memory mode for unit tests:
```swift
@Test("Tesla vehicle import")
func testVehicleImport() async throws {
    let manager = TeslaAuthManager()
    // Mock network responses
    // Test import logic
}
```

### CI/CD Considerations
- Store test credentials securely (GitHub Secrets)
- Use mocked API responses for CI
- Don't commit real tokens

### Code Style
Following Apple's Swift API Design Guidelines:
- Clear naming conventions
- Async/await for network calls
- @Observable for state management
- SwiftUI-native patterns

## License
[Your license information]

## Credits
- Tesla API documentation by various community contributors
- Icons from SF Symbols
- SwiftUI and SwiftData by Apple

---

**Last Updated**: May 8, 2026
**Version**: 1.0.0
