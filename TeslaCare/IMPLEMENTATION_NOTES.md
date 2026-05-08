//
//  IMPLEMENTATION_NOTES.md
//  TeslaCare Tesla Integration
//
//  Created by Jin on 5/8/26.
//

# Tesla Integration Implementation Notes

## Files Added

### 1. TeslaAuthManager.swift
**Purpose**: Core authentication and API management
**Key Components**:
- `TeslaAuthManager` class with `@Observable` macro
- OAuth token management (access + refresh tokens)
- Vehicle data fetching and parsing
- Secure credential storage
- Error handling

**Important Methods**:
```swift
func login(email: String, password: String) async throws
func fetchVehicles() async throws
func logout()
```

### 2. TeslaLoginView.swift
**Purpose**: User interface for Tesla authentication
**Key Components**:
- `TeslaLoginView` - Login form with credentials
- `TeslaVehicleSelectionView` - Multi-select vehicle picker
- Password visibility toggle
- Loading states and error display

**SwiftUI Features Used**:
- Form with TextField/SecureField
- State management with @State
- Sheet presentations
- Environment integration for modelContext

### 3. TESLA_INTEGRATION.md
**Purpose**: Comprehensive documentation for Tesla integration
**Contents**:
- User guide
- Technical architecture
- API documentation
- Security considerations
- Troubleshooting guide

## Files Modified

### ContentView.swift
**Changes**:
- Added `@State private var showingTeslaLogin = false`
- Changed + button to Menu with two options:
  - "Add Car Manually"
  - "Connect Tesla Account"
- Updated empty state to show both options as buttons
- Added `.sheet(isPresented: $showingTeslaLogin)`

### SettingsView.swift
**Changes**:
- Added Tesla Account section at top
- Shows connection status
- Displays connected email
- Sync Vehicles button (when connected)
- Disconnect button (when connected)
- Connect button (when not connected)
- Added reference to `TeslaAuthManager.shared`

### README.md
**Changes**:
- Added Tesla Account Integration as Feature #1
- Updated feature numbering
- Enhanced Usage Guide with Tesla login instructions
- Added async/await and @Observable to best practices

## Data Models

### TeslaVehicle
```swift
struct TeslaVehicle: Codable, Identifiable {
    let id: Int64
    let vehicle_id: Int64
    let vin: String
    let display_name: String?
    let option_codes: String?
    let color: String?
    let state: String
    
    var modelName: String { /* Parses from option codes */ }
    var year: Int { /* Parses from VIN */ }
}
```

### TeslaVehiclesResponse
API response wrapper:
```swift
struct TeslaVehiclesResponse: Codable {
    let response: [TeslaVehicle]
    let count: Int
}
```

### TeslaAuthResponse
OAuth response:
```swift
struct TeslaAuthResponse: Codable {
    let access_token: String
    let refresh_token: String
    let expires_in: Int
    let token_type: String
}
```

## Integration Points

### 1. ContentView Integration
```swift
// User taps "Connect Tesla Account"
showingTeslaLogin = true
    ↓
// TeslaLoginView presented as sheet
TeslaLoginView()
    ↓
// After successful login
TeslaVehicleSelectionView(vehicles: authManager.vehicles)
    ↓
// User selects vehicles and taps "Import"
for vehicle in selectedVehicles {
    let car = Car(...)
    modelContext.insert(car)
}
```

### 2. Settings Integration
```swift
if teslaAuth.isAuthenticated {
    // Show connected state
    // Offer sync and disconnect
} else {
    // Show connect button
}
```

## Security Implementation

### Current Storage (Development)
```swift
UserDefaults.standard.set(accessToken, forKey: "tesla_access_token")
UserDefaults.standard.set(refreshToken, forKey: "tesla_refresh_token")
```

### Recommended for Production
Use iOS Keychain:
```swift
import Security

// Save to Keychain
let query: [String: Any] = [
    kSecClass as String: kSecClassGenericPassword,
    kSecAttrAccount as String: "tesla_access_token",
    kSecValueData as String: tokenData
]
SecItemAdd(query as CFDictionary, nil)
```

## API Flow

### Login Flow
```
User Input (email, password)
    ↓
POST https://auth.tesla.com/oauth2/v3/token
    {
        "grant_type": "password",
        "client_id": "ownerapi",
        "email": "...",
        "password": "..."
    }
    ↓
Response:
    {
        "access_token": "...",
        "refresh_token": "...",
        "expires_in": 3888000
    }
    ↓
Store tokens
    ↓
Fetch vehicles automatically
```

### Fetch Vehicles Flow
```
GET https://owner-api.teslamotors.com/api/1/vehicles
Headers: Authorization: Bearer {access_token}
    ↓
Response:
    {
        "response": [
            {
                "id": 123,
                "vin": "5YJSA...",
                "display_name": "My Tesla",
                ...
            }
        ],
        "count": 1
    }
    ↓
Parse TeslaVehicle objects
    ↓
Display in selection view
```

### Token Refresh Flow
```
API call returns 401 Unauthorized
    ↓
POST https://auth.tesla.com/oauth2/v3/token
    {
        "grant_type": "refresh_token",
        "client_id": "ownerapi",
        "refresh_token": "..."
    }
    ↓
Get new access_token
    ↓
Retry original request
```

## Error Handling Strategy

### Network Errors
- Display user-friendly messages
- Offer retry option
- Log technical details for debugging

### Authentication Errors
- Clear, actionable error messages
- Link to Tesla account help if needed
- Suggest checking credentials

### Token Expiration
- Automatic refresh attempt
- Fallback to re-authentication if refresh fails
- Maintain user session whenever possible

## Testing Strategy

### Unit Tests
```swift
@Test("Vehicle year parsing from VIN")
func testVehicleYearParsing() {
    let vehicle = TeslaVehicle(vin: "5YJSA1E2SMFXXXXXX", ...)
    #expect(vehicle.year == 2025) // 'S' = 2025
}

@Test("Model name detection")
func testModelDetection() {
    let vehicle = TeslaVehicle(option_codes: "MS03,PPSW", ...)
    #expect(vehicle.modelName == "Model S")
}
```

### Integration Tests
```swift
@Test("Tesla login flow")
func testLoginFlow() async throws {
    let manager = TeslaAuthManager()
    // Use mocked network responses
    try await manager.login(email: "test@example.com", password: "test")
    #expect(manager.isAuthenticated == true)
}
```

### UI Tests
- Test login form validation
- Test vehicle selection
- Test empty states
- Test error displays

## Performance Considerations

### Network Calls
- Rate limiting: Max 10 requests/minute recommended
- Cache vehicle list locally
- Only fetch when needed (not on every app launch)

### Token Management
- Check expiration before making requests
- Refresh proactively if close to expiration
- Handle refresh failures gracefully

### UI Responsiveness
- Use async/await for all network calls
- Show loading states
- Never block main thread
- Cancel in-flight requests when view dismisses

## Privacy Compliance

### Data Collection
**What we collect**:
- Email address (for display only)
- Vehicle information (VIN, model, year)
- Access tokens (temporary, for API calls)

**What we DON'T collect**:
- Passwords (never stored)
- Location data
- Driving habits
- Personal information beyond email

### User Rights
- View connected account (Settings)
- Disconnect at any time
- Delete all data
- Export data

### Privacy Policy Requirements
Must disclose:
- Tesla account connection
- Data stored locally
- No third-party sharing
- User can disconnect anytime

## Future Enhancements

### Phase 1: Enhanced Authentication
- [ ] Multi-factor authentication (MFA) support
- [ ] Captcha handling
- [ ] Device authorization flow
- [ ] Biometric authentication for app access

### Phase 2: Real-Time Data
- [ ] Fetch current mileage from Tesla API
- [ ] Tire pressure monitoring (TPMS data)
- [ ] Battery health tracking
- [ ] Last service date

### Phase 3: Advanced Features
- [ ] Background sync
- [ ] Push notifications for vehicle updates
- [ ] Multiple account support
- [ ] Fleet management for businesses

### Phase 4: Enhanced UX
- [ ] Vehicle photos from API
- [ ] Service history integration
- [ ] Warranty information
- [ ] Nearby service centers

## Known Limitations

### Tesla API
1. **Rate Limiting**: 10 requests/minute recommended
2. **No Official Documentation**: Community-maintained
3. **Breaking Changes**: API can change without notice
4. **MFA Not Fully Supported**: Current implementation is simplified

### App Limitations
1. **Manual Refresh**: No automatic background sync
2. **UserDefaults Storage**: Not as secure as Keychain
3. **No Offline Mode**: Requires internet for login
4. **Single Account**: Can't manage multiple Tesla accounts

## Deployment Checklist

### Before Production Release

#### Security
- [ ] Migrate from UserDefaults to Keychain
- [ ] Implement certificate pinning
- [ ] Add request signing
- [ ] Encrypt sensitive data at rest

#### Features
- [ ] Add MFA support
- [ ] Implement proper error recovery
- [ ] Add analytics (privacy-focused)
- [ ] Test with multiple account types

#### Documentation
- [ ] Update privacy policy
- [ ] Create user guide
- [ ] Add troubleshooting FAQ
- [ ] Document API rate limits

#### Testing
- [ ] Test on all iOS versions
- [ ] Test with slow/unstable networks
- [ ] Test edge cases (no vehicles, many vehicles)
- [ ] Security audit

#### Legal
- [ ] Review Tesla API terms
- [ ] Add disclaimers
- [ ] Update app description
- [ ] Prepare for App Store review

## Support Resources

### Internal Documentation
- `README.md` - Overview and features
- `TESLA_INTEGRATION.md` - Detailed integration guide
- This file - Implementation notes

### External Resources
- Tesla API Community Wiki
- iOS Keychain Documentation
- Swift Concurrency Guide
- SwiftUI Documentation

### Contact
For questions or issues:
- GitHub Issues
- Email: support@teslacare.example.com
- Developer docs: docs.teslacare.example.com

---

**Implementation Date**: May 8, 2026  
**Developer**: Jin  
**Version**: 1.0.0  
**Status**: Ready for Review
