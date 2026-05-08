# Tesla Integration Architecture Diagram

## System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         TeslaCare App                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌───────────────┐  ┌───────────────┐  ┌──────────────────┐  │
│  │  ContentView  │  │ SettingsView  │  │  MainTabView     │  │
│  │               │  │               │  │                  │  │
│  │  • Car List   │  │  • Tesla      │  │  • Navigation    │  │
│  │  • + Menu     │  │    Account    │  │  • Tab Bar       │  │
│  │  • Empty      │  │  • Sync       │  │                  │  │
│  │    State      │  │  • Disconnect │  │                  │  │
│  └───────┬───────┘  └───────┬───────┘  └──────────────────┘  │
│          │                  │                                   │
│          └──────────┬───────┘                                   │
│                     │                                           │
│          ┌──────────▼──────────┐                               │
│          │  TeslaLoginView     │                               │
│          │                     │                               │
│          │  • Login Form       │                               │
│          │  • Email/Password   │                               │
│          │  • Error Display    │                               │
│          │  • Loading State    │                               │
│          └──────────┬──────────┘                               │
│                     │                                           │
│          ┌──────────▼─────────────────┐                        │
│          │ TeslaVehicleSelectionView  │                        │
│          │                            │                        │
│          │  • Vehicle List            │                        │
│          │  • Multi-select            │                        │
│          │  • Import Button           │                        │
│          └──────────┬─────────────────┘                        │
│                     │                                           │
└─────────────────────┼───────────────────────────────────────────┘
                      │
        ┌─────────────▼──────────────┐
        │   TeslaAuthManager         │
        │   (@Observable Singleton)  │
        │                            │
        │  State:                    │
        │  • isAuthenticated         │
        │  • currentUser             │
        │  • vehicles[]              │
        │  • isLoading               │
        │  • errorMessage            │
        │                            │
        │  Methods:                  │
        │  • login()                 │
        │  • fetchVehicles()         │
        │  • refreshToken()          │
        │  • logout()                │
        └─────────────┬──────────────┘
                      │
          ┌───────────┼───────────┐
          │           │           │
    ┌─────▼─────┐ ┌──▼───────┐ ┌─▼──────────┐
    │UserDefaults│ │URLSession│ │SwiftData  │
    │           │ │          │ │           │
    │ • Tokens  │ │ • API    │ │ • Cars    │
    │ • Email   │ │   Calls  │ │ • Insert  │
    └───────────┘ └────┬─────┘ └───────────┘
                       │
         ┌─────────────┴─────────────┐
         │                           │
    ┌────▼────────┐          ┌───────▼────────┐
    │ Tesla Auth  │          │ Tesla Owner    │
    │ API         │          │ API            │
    │             │          │                │
    │ /oauth2/v3/ │          │ /api/1/        │
    │ token       │          │ vehicles       │
    └─────────────┘          └────────────────┘
```

## Data Flow Diagram

### 1. Login Flow

```
User Action                     TeslaLoginView              TeslaAuthManager           Tesla API
    │                                 │                          │                        │
    ├─Enter Email/Password───────────▶│                          │                        │
    │                                 │                          │                        │
    │                                 ├─Tap "Sign In"───────────▶│                        │
    │                                 │                          │                        │
    │                                 │                          ├─POST /token───────────▶│
    │                                 │                          │   email, password      │
    │                                 │                          │                        │
    │                                 │                          │◀───access_token────────┤
    │                                 │                          │    refresh_token       │
    │                                 │                          │                        │
    │                                 │                          ├─Save to UserDefaults   │
    │                                 │                          │                        │
    │                                 │                          ├─GET /vehicles─────────▶│
    │                                 │                          │   Bearer token         │
    │                                 │                          │                        │
    │                                 │                          │◀───vehicles list───────┤
    │                                 │                          │                        │
    │                                 │◀─Show Vehicle Selection──┤                        │
    │                                 │                          │                        │
    │◀─See Vehicles─────────────────  │                          │                        │
    │                                 │                          │                        │
```

### 2. Vehicle Import Flow

```
User Action             VehicleSelectionView        TeslaAuthManager      SwiftData
    │                          │                          │                  │
    ├─Select Vehicles─────────▶│                          │                  │
    │                          │                          │                  │
    ├─Tap "Import"────────────▶│                          │                  │
    │                          │                          │                  │
    │                          ├─For each selected:       │                  │
    │                          │                          │                  │
    │                          ├─Create Car model─────────┼─────────────────▶│
    │                          │  • name = display_name   │                  │
    │                          │  • make = "Tesla"        │                  │
    │                          │  • model = modelName     │                  │
    │                          │  • year = year           │                  │
    │                          │                          │                  │
    │                          │                          │                  ├─Insert
    │                          │                          │                  │
    │◀─Dismiss & Show Cars─────┤                          │                  │
    │                          │                          │                  │
```

### 3. Token Refresh Flow

```
TeslaAuthManager       Tesla API              UserDefaults
       │                   │                       │
       ├─API Call──────────▶│                       │
       │                   │                       │
       │◀─401 Unauthorized──┤                       │
       │                   │                       │
       ├─Load refresh_token─┼──────────────────────▶│
       │                   │                       │
       │◀─refresh_token─────┼───────────────────────┤
       │                   │                       │
       ├─POST /token───────▶│                       │
       │  refresh_token     │                       │
       │                   │                       │
       │◀─new access_token──┤                       │
       │                   │                       │
       ├─Save new tokens────┼──────────────────────▶│
       │                   │                       │
       ├─Retry API Call────▶│                       │
       │                   │                       │
       │◀─200 Success───────┤                       │
       │                   │                       │
```

## Component Relationships

```
┌──────────────────────────────────────────────────────────────┐
│                         App Layer                            │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  ContentView        SettingsView        TeslaLoginView       │
│      │                  │                      │             │
│      │                  │                      │             │
│      └──────────────────┴──────────────────────┘             │
│                         │                                    │
└─────────────────────────┼────────────────────────────────────┘
                          │
┌─────────────────────────┼────────────────────────────────────┐
│                    Business Logic                            │
├──────────────────────────────────────────────────────────────┤
│                         │                                    │
│              ┌──────────▼───────────┐                        │
│              │  TeslaAuthManager    │                        │
│              │   (@Observable)      │                        │
│              └──────────┬───────────┘                        │
│                         │                                    │
└─────────────────────────┼────────────────────────────────────┘
                          │
┌─────────────────────────┼────────────────────────────────────┐
│                     Data Layer                               │
├──────────────────────────────────────────────────────────────┤
│                         │                                    │
│          ┌──────────────┼──────────────┐                     │
│          │              │              │                     │
│    ┌─────▼──────┐  ┌────▼──────┐ ┌────▼──────┐             │
│    │UserDefaults│  │SwiftData  │ │URLSession │             │
│    │ (Tokens)   │  │ (Cars)    │ │(Network)  │             │
│    └────────────┘  └───────────┘ └───────────┘             │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

## State Management

```
TeslaAuthManager States:

┌─────────────────┐
│  Unauthenticated│
│                 │
│  • No tokens    │
│  • No user      │
│  • No vehicles  │
└────────┬────────┘
         │
         │ login()
         ▼
┌─────────────────┐
│   Authenticating│
│                 │
│  • isLoading    │
│  • Pending...   │
└────────┬────────┘
         │
         │ success
         ▼
┌─────────────────┐
│  Authenticated  │
│                 │
│  • Has tokens   │
│  • Has user     │
│  • Vehicles[]   │
└────────┬────────┘
         │
         │ logout()
         ▼
┌─────────────────┐
│ Unauthenticated │
└─────────────────┘
```

## UI Navigation Flow

```
App Launch
    │
    ▼
MainTabView
    │
    ├─Tab 1: ContentView (Cars)
    │   │
    │   ├─Empty State
    │   │   │
    │   │   ├─"Connect Tesla" ────┐
    │   │   │                     │
    │   │   └─"Add Manual" ───────┼─────▶ AddCarView
    │   │                         │
    │   ├─Car List                │
    │   │   │                     │
    │   │   └─Car Detail          │
    │   │                         │
    │   └─+ Menu                  │
    │       │                     │
    │       ├─"Connect Tesla" ────┤
    │       │                     │
    │       └─"Add Manual" ───────┼─────▶ AddCarView
    │                             │
    ├─Tab 2: Tires                │
    │                             │
    ├─Tab 3: Maintenance          │
    │                             │
    └─Tab 4: Settings             │
        │                         │
        └─Tesla Account           │
            │                     │
            └─"Connect" ──────────┤
                                  │
                                  ▼
                         TeslaLoginView
                                  │
                                  ▼
                         Enter Credentials
                                  │
                                  ▼
                         TeslaVehicleSelectionView
                                  │
                                  ▼
                         Select & Import
                                  │
                                  ▼
                         Back to ContentView
                         (with new cars!)
```

## Error Handling Flow

```
API Call
    │
    ├─Success (200)
    │   └─▶ Parse & Display
    │
    ├─Unauthorized (401)
    │   └─▶ Refresh Token
    │       │
    │       ├─Success
    │       │   └─▶ Retry Original Request
    │       │
    │       └─Failure
    │           └─▶ Show Login Again
    │
    ├─Network Error
    │   └─▶ Show "Check Connection"
    │
    ├─Invalid Credentials
    │   └─▶ Show "Check Email/Password"
    │
    └─Other Error
        └─▶ Show Generic Error + Retry
```

## Data Models Structure

```
┌─────────────────────────────────────┐
│         Tesla API Models            │
├─────────────────────────────────────┤
│                                     │
│  TeslaVehicle                       │
│  ├─ id: Int64                       │
│  ├─ vin: String                     │
│  ├─ display_name: String?           │
│  ├─ option_codes: String?           │
│  ├─ modelName: String (computed)    │
│  └─ year: Int (computed)            │
│                                     │
│  TeslaAuthResponse                  │
│  ├─ access_token: String            │
│  ├─ refresh_token: String           │
│  └─ expires_in: Int                 │
│                                     │
│  TeslaVehiclesResponse              │
│  ├─ response: [TeslaVehicle]        │
│  └─ count: Int                      │
│                                     │
└─────────────────────────────────────┘
                │
                │ Convert
                ▼
┌─────────────────────────────────────┐
│         App Data Models             │
├─────────────────────────────────────┤
│                                     │
│  Car (@Model)                       │
│  ├─ name: String                    │
│  ├─ make: String ("Tesla")          │
│  ├─ model: String                   │
│  ├─ year: Int                       │
│  └─ dateAdded: Date                 │
│                                     │
└─────────────────────────────────────┘
```

## Security Flow

```
┌────────────────────────────────────────────────────────────┐
│                     Security Layers                        │
├────────────────────────────────────────────────────────────┤
│                                                            │
│  User Input                                                │
│      │                                                     │
│      ▼                                                     │
│  ┌─────────────────┐                                      │
│  │ HTTPS/TLS       │ ◀── All API calls encrypted         │
│  └────────┬────────┘                                      │
│           │                                                │
│           ▼                                                │
│  ┌─────────────────┐                                      │
│  │ OAuth 2.0       │ ◀── Industry standard               │
│  └────────┬────────┘                                      │
│           │                                                │
│           ▼                                                │
│  ┌─────────────────┐                                      │
│  │ Token Storage   │ ◀── UserDefaults (TODO: Keychain)   │
│  └────────┬────────┘                                      │
│           │                                                │
│           ▼                                                │
│  ┌─────────────────┐                                      │
│  │ Secure Deletion │ ◀── logout() clears all data        │
│  └─────────────────┘                                      │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

## Testing Architecture

```
┌──────────────────────────────────────────────────────────┐
│                    Test Pyramid                          │
├──────────────────────────────────────────────────────────┤
│                                                          │
│                      ▲                                   │
│                     ╱ ╲                                  │
│                    ╱   ╲                                 │
│                   ╱ UI  ╲                                │
│                  ╱ Tests ╲                               │
│                 ╱─────────╲                              │
│                ╱           ╲                             │
│               ╱Integration  ╲                            │
│              ╱     Tests     ╲                           │
│             ╱─────────────────╲                          │
│            ╱                   ╲                         │
│           ╱    Unit Tests       ╲                        │
│          ╱  (VIN, Model, JSON)   ╲                       │
│         ╱─────────────────────────╲                      │
│                                                          │
│  Most tests are unit tests (fast, reliable)             │
│  Fewer integration tests (with mocking)                  │
│  Minimal UI tests (slow, expensive)                      │
│                                                          │
└──────────────────────────────────────────────────────────┘
```

## Performance Considerations

```
Network Request Flow:

User Action
    │
    ▼
┌──────────────┐
│ UI Thread    │──────┐ Async/Await
└──────────────┘      │
                      ▼
                ┌──────────────┐
                │ Background   │
                │ Thread       │
                │              │
                │ • API Call   │
                │ • Parse JSON │
                │ • Store Data │
                └──────┬───────┘
                       │ @MainActor
                       ▼
                ┌──────────────┐
                │ UI Thread    │
                │              │
                │ • Update UI  │
                │ • Show Data  │
                └──────────────┘

Key Points:
• Never block UI thread
• Use async/await
• Show loading states
• Handle cancellation
```

## Deployment Flow

```
Development            Testing              Production
     │                    │                      │
     │                    │                      │
     ▼                    ▼                      ▼
┌─────────┐         ┌─────────┐          ┌──────────┐
│UserDef. │         │UserDef. │          │Keychain  │
│Storage  │────────▶│Storage  │─────────▶│Storage   │
└─────────┘         └─────────┘          └──────────┘
     │                    │                      │
     │                    │                      │
┌─────────┐         ┌─────────┐          ┌──────────┐
│Basic    │         │Enhanced │          │Full      │
│Error    │────────▶│Error    │─────────▶│Error     │
│Handling │         │+ Retry  │          │+ Analytics│
└─────────┘         └─────────┘          └──────────┘
     │                    │                      │
     │                    │                      │
┌─────────┐         ┌─────────┐          ┌──────────┐
│Manual   │         │Auto     │          │Background│
│Sync     │────────▶│Sync     │─────────▶│Sync      │
└─────────┘         └─────────┘          └──────────┘
```

---

This architecture provides a **scalable, secure, and maintainable** solution for Tesla account integration!
