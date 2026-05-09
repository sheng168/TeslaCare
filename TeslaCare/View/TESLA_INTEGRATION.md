# Tesla Integration Guide

## Overview

TeslaCare now includes Tesla account integration using the official Tesla Fleet API. This allows you to:

- Authenticate with your Tesla account securely
- View your Tesla vehicles
- Automatically sync vehicle information
- Access tire pressure and other vehicle data

## Implementation

### Files Created

1. **TeslaAuthView.swift** - Main authentication UI and manager
2. **Car+Tesla.swift** - Extension for Tesla-specific Car properties

### Key Components

#### TeslaAuthManager

An `ObservableObject` that manages the entire Tesla authentication flow:

- **OAuth 2.0 Authentication**: Uses `ASWebAuthenticationSession` for secure login
- **Token Management**: Stores access tokens and refresh tokens using `@AppStorage` (consider using Keychain for production)
- **Automatic Token Refresh**: Checks token expiry and refreshes automatically
- **Vehicle Fetching**: Retrieves and displays all vehicles associated with the account

#### TeslaAuthView

A SwiftUI view that provides:

- Login interface with Tesla branding
- Vehicle list display after authentication
- Sign out functionality
- Error handling and loading states

### Configuration

Update these values in `TeslaAuthManager` with your Tesla Fleet API credentials:

```swift
private let clientID = "YOUR_CLIENT_ID"
private let clientSecret = "YOUR_CLIENT_SECRET"
private let redirectURI = "YOUR_REDIRECT_URI"
```

### Security Considerations

⚠️ **Important**: The current implementation stores tokens in `@AppStorage` for development convenience. For production:

1. **Use Keychain**: Store sensitive tokens in the iOS Keychain
2. **Never commit credentials**: Use a configuration file or environment variables for API credentials
3. **Implement proper error handling**: Add retry logic and better error messages
4. **Add token encryption**: Consider encrypting tokens before storage

### Future Enhancements

Potential features to add:

- [ ] Fetch real-time tire pressure data from Tesla API
- [ ] Sync odometer readings automatically
- [ ] Link Tesla vehicles to Car models in SwiftData
- [ ] Display vehicle state (asleep, online, charging, etc.)
- [ ] Send commands to vehicles (honk, flash lights, etc.)
- [ ] Schedule automatic data sync
- [ ] Support for multiple Tesla accounts
- [ ] Offline mode with cached data

### Usage in App

Users can access Tesla integration from:

**Settings → Tesla Integration → Tesla Account**

The flow:
1. Tap "Sign In with Tesla"
2. Authenticate in Tesla's web view
3. Grant permissions to your app
4. View connected vehicles
5. Refresh vehicle list as needed

### API Reference

The integration uses [TeslaSwift](https://github.com/jonasman/TeslaSwift) library with the Fleet API:

- **Scopes Used**:
  - `vehicle_device_data`: Read vehicle data
  - `vehicle_cmds`: Send commands to vehicle
  - `vehicle_charging_cmds`: Control charging

### Troubleshooting

**Authentication fails:**
- Verify your Fleet API credentials are correct
- Check that your redirect URI matches Tesla's configuration
- Ensure your app has network permissions

**Vehicles not showing:**
- Check that you have vehicles associated with your Tesla account
- Try the refresh button
- Verify the access token hasn't expired

**Token refresh errors:**
- Sign out and sign in again
- Check network connectivity
- Verify refresh token is being stored correctly

## Development Notes

- Debugging is enabled by default (`api.debuggingEnabled = true`)
- All network calls use async/await for clean concurrency
- The manager automatically checks for existing authentication on init
- Tokens are shared across the app using `@AppStorage`

## License

This integration uses TeslaSwift which is available under the MIT license.
