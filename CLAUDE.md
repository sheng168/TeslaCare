# TeslaCare — Claude Development Guide

## Project Overview

**TeslaCare** (marketed as "TezCare") is an iOS 26 + watchOS app for tracking tire health,
maintenance events, and Tesla vehicle data for one or more cars.

- **Minimum deployment**: iOS 26 / watchOS 11
- **Language**: Swift 6, strict concurrency enabled
- **UI framework**: SwiftUI throughout — no UIKit unless absolutely unavoidable
- **Persistence**: SwiftData with automatic CloudKit (iCloud) sync
- **External dependency**: `TeslaSwift` (SPM) for Tesla Fleet API

---

## Architecture

### MVVM

- ViewModels use `@Observable` macro (NOT `ObservableObject`) unless forced by a third-party
  dependency. Example exception: `TeslaAuthManager` uses `@MainActor class … ObservableObject`
  because `TeslaSwift` requires it — inject it with `.environmentObject()`.
- Views hold their ViewModel as a `@State` property.
- Views are declarative only — all business logic lives in the ViewModel.

### Navigation

- Use `NavigationSplitView` for list/detail layouts (iPad-friendly).
- Use `NavigationStack` + `NavigationPath` for push-based flows.
- **Never** use `NavigationView`.

### Dependency Injection

- Inject services through the SwiftUI environment:
  - `LocationManager` → `.environment(locationManager)` (`@Observable`)
  - `CloudKitPublicService` → `.environment(cloudKitService)` (`@Observable`)
  - `TeslaAuthManager` → `.environmentObject(authManager)` (`ObservableObject`)
- Use `@AppStorage` for simple user preferences (units, notification toggles, etc.).
- Use SwiftData (`@Environment(\.modelContext)`, `@Query`) for all persistent data.

---

## SwiftData Schema

The `ModelContainer` is configured in `TeslaCareApp.swift` with CloudKit sync enabled.
All 13 models must be declared in the `Schema([…])` array when the container is created:

| Model | Purpose |
|---|---|
| `Car` | Vehicle with Tesla API fields (VIN, battery, location) |
| `Tire` | Individual tire with brand/model/size, linked to a `Car` |
| `TireMeasurement` | Tread-depth reading (supports 3-point: inner/center/outer) |
| `TirePhoto` | Photo attachment for a `Tire` |
| `TireRepairEvent` | Repair record with notes and photos |
| `TireRepairPhoto` | Photo attachment for a `TireRepairEvent` |
| `TireRotationEvent` | Rotation event with pattern |
| `TireReplacementEvent` | Replacement event |
| `AirFilterChangeEvent` | Air filter change record |
| `TPMSReading` | Pressure reading from Tesla API (stored in bar, displayed in PSI) |
| `MileageReading` | Odometer reading (manual or synced from Tesla API) |
| `TeslaCredential` | OAuth token storage |
| `NearbyCharger` | Supercharger data with estimated power rating |

All relationships use `.cascade` delete rules. When adding a new model:
1. Add it to the `Schema([…])` list in `TeslaCareApp.swift`.
2. Add it to the lean schema in `TezCare Watch App/TezCareApp.swift` only if the watch needs it.

---

## Directory Structure

```
TeslaCare/
├── TeslaCareApp.swift          # App entry — ModelContainer, environment setup
├── SettingsView.swift          # Settings tab
├── TeslaAuthView.swift         # Tesla OAuth sheet
├── TeslaAuthManager.swift      # Tesla Fleet API (ObservableObject, @MainActor)
├── LocationManager.swift       # Core Location wrapper (@Observable)
├── NotificationManager.swift   # Push notification scheduling
├── CloudKitPublicService.swift # Public community car listings (@Observable)
├── DataTransferService.swift   # JSON & CSV import/export
├── TireSpecs.json              # PSI recommendations, tread thresholds by model/size
├── Model/                      # 18 SwiftData @Model files (one type per file)
└── View/
    ├── Car/                    # Car list, detail, add, mileage, TPMS, history
    ├── Tire/                   # Tire list, detail, add, measure, rotate, replace
    ├── Community/              # CloudKit public listings
    └── Other/                  # Shared utilities (image picker, VIN scanner, export, etc.)

TezCare Watch App/              # watchOS companion (minimal SwiftData schema)
TeslaCareTests/                 # Unit tests (Swift Testing framework)
TeslaCareUITests/               # UI tests
Screenshots/                    # Generated PNG screenshots (390×844, 3×)
scripts/
└── capture-screenshots.sh      # Runs ScreenshotTests on simulator, saves to Screenshots/
```

---

## Build System

- **Build tool**: Use `BuildProject` MCP tool — do NOT use shell commands or `xcodebuild` directly.
- **Previews**: Use `RenderPreview` MCP tool.
- **Build target (iOS)**: `TeslaCare`
- **Build target (watchOS)**: `TezCare Watch App`
- **Package manager**: SPM only — no CocoaPods.

---

## Testing

- **Framework**: Swift Testing (`import Testing`) — NOT XCTest.
- Test functions use `@Test func myTest() { … }` (not `func testMyTest()`).
- Assertions use `#expect(…)` — not `XCTAssertEqual`.
- **Test target**: `TeslaCareTests`
- **Run tests**: `RunAllTests` or `RunSomeTests` MCP tools.

Screenshot tests (`ScreenshotTests.swift`) are XCTest-based (an intentional exception) and
produce the PNGs under `Screenshots/`.

---

## Tesla API Integration

`TeslaAuthManager` wraps the `TeslaSwift` package:

- **Auth flow**: OAuth 2.0 via `ASWebAuthenticationSession`.
- **Scopes**: `openId`, `offlineAccess`, `vehicleDeviceData`, `vehicleCmds`.
- **Token storage**: `TeslaCredential` SwiftData model (migrate to Keychain in the future).
- **Sync**: `fetchVehicles()` + `syncCars(into:)` pull vehicle state into SwiftData `Car` models.
- **TPMS data**: Pressure values from the API are in **bar**; convert to PSI for display
  (`1 bar ≈ 14.504 PSI`).

Do not hard-code the client ID/secret — they live in `TeslaAuthManager.swift` and the
`TESLA_INTEGRATION.md` doc explains the registration flow.

---

## Key Business Logic

### Tire Health

Thresholds are defined in `TireSpecs.json` and enforced in the UI:

| Tread depth | Status |
|---|---|
| > 4/32" | Good (green) |
| 2–4/32" | Warning (orange) |
| ≤ 2/32" | Danger / replace (red) |

Health percentage formula (in `Car.tireHealthPercentage`):
```
health% = (treadDepth - 2) / (10 - 2) * 100    // clamped 0–100
```

### TPMS

- `TPMSReading` stores four pressures (FL/FR/RL/RR) in bar.
- `Car.latestTPMSReading` returns the most recent reading.
- `Car.tpmsPressure(for:)` returns the pressure for a specific `TirePosition`.

### Mileage

`Car.mileage` is a computed property returning the highest-date `MileageReading.mileage`.

---

## Documentation & APIs

- Use `DocumentationSearch` for Apple API questions — **do not hallucinate API names**.
- Prefer `async/await` — never completion handlers.
- Use structured concurrency (`TaskGroup`, `async let`) over manual task management.
- Use typed throws where Swift supports it.

---

## Code Style

| Rule | Detail |
|---|---|
| **One type per file** | File name matches type name |
| **Feature grouping** | `Car/`, `Tire/`, `Community/` — not by type |
| **Naming** | `PascalCase` for types; `camelCase` for properties/functions |
| **Icons** | SF Symbols only — use exact symbol names |
| **Materials** | Prefer Liquid Glass (`.glassEffect()`) for iOS 26 UI |
| **Logging** | Use `OSLog` (`Logger(subsystem:category:)`) — no `print()` |
| **Previews** | Every new `View` must have a `#Preview` block |

### Preview pattern

Previews that need SwiftData should create an in-memory `ModelContainer`:

```swift
#Preview("With data") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Car.self, Tire.self, configurations: config)
    // insert sample data into container.mainContext …
    return MyView()
        .modelContainer(container)
        .environmentObject(TeslaAuthManager())
        .environment(LocationManager())
}
```

---

## Services Summary

| Service | Type | Injected via |
|---|---|---|
| `TeslaAuthManager` | `@MainActor ObservableObject` | `.environmentObject()` |
| `LocationManager` | `@Observable` | `.environment()` |
| `CloudKitPublicService` | `@Observable` | `.environment()` |
| `NotificationManager` | Singleton (`shared`) | Direct call |
| `DataTransferService` | Stateless | Instantiate locally |

---

## watchOS Companion

`TezCare Watch App` has its own lean `ModelContainer` with only the models it needs.
Keep watch code minimal. Do not copy full iOS views to watchOS — adapt for the smaller screen.

---

## Workflow Notes

- Always commit to the designated feature branch (see session instructions above).
- Push with `git push -u origin <branch>`.
- Screenshot automation: `bash scripts/capture-screenshots.sh` (requires a booted simulator).
