# TeslaCare UI Testing Guide

## Overview

This document describes the comprehensive UI test suite created for the `CarDetailView` and its components. The tests capture screenshots of different view states and validate UI behavior.

## Test Files

### 1. **TeslaCareUITests.swift**
Traditional XCTest UI tests covering:
- Empty car state
- Cars with measurements (healthy, warning, danger states)
- History views (rotation, replacement, air filter)
- Complete history with all events
- Action button interactions
- Different car configurations

### 2. **CarDetailViewComponentTests.swift**
Modern Swift Testing framework tests with focused component testing:
- Car info header display
- Tire health indicators
- Health status variations (healthy/warning/danger)
- Action buttons
- Measurement history (empty and populated)
- Event history sections

### 3. **UITestDataHelper.swift**
Helper class that creates test data based on launch arguments:
- Sets up different car states for testing
- Generates realistic test data
- Clears data between test runs

## Test Scenarios

### Empty State
- **Launch Argument**: `EmptyCarState`
- **Screenshot Name**: `CarDetailView_EmptyState`
- **Description**: Car with no measurements or history

### Healthy Tires
- **Launch Argument**: `HealthyTires`
- **Screenshot Name**: `CarDetailView_HealthyTires`
- **Description**: All tires with 8-9/32" tread depth (green indicators)

### Warning Tires
- **Launch Argument**: `WarningTires`
- **Screenshot Name**: `CarDetailView_WarningTires`
- **Description**: Some tires with 2-4/32" tread depth (orange indicators)

### Dangerous Tires
- **Launch Argument**: `DangerousTires`
- **Screenshot Name**: `CarDetailView_DangerousTires`
- **Description**: Tires below 2/32" (red indicators, critical warnings)

### With Measurements
- **Launch Argument**: `CarWithMeasurements`
- **Screenshot Name**: `CarDetailView_WithMeasurements`
- **Description**: Car with multiple tire measurements

### With Rotation History
- **Launch Argument**: `WithRotationHistory`
- **Screenshot Name**: `CarDetailView_WithRotationHistory`
- **Description**: Car with tire rotation events

### With Replacement History
- **Launch Argument**: `WithReplacementHistory`
- **Screenshot Name**: `CarDetailView_WithReplacementHistory`
- **Description**: Car with tire replacement events

### With Air Filter History
- **Launch Argument**: `WithAirFilterHistory`
- **Screenshot Name**: `CarDetailView_WithAirFilterHistory`
- **Description**: Car with air filter change events

### Complete History
- **Launch Argument**: `CompleteHistory`
- **Screenshot Names**: 
  - `CarDetailView_CompleteHistory_Top`
  - `CarDetailView_CompleteHistory_Middle`
  - `CarDetailView_CompleteHistory_Bottom`
- **Description**: Car with all types of events and measurements (captured in 3 sections)

## Running the Tests

### Using Xcode

1. **Open the project** in Xcode
2. **Select the test target**: Choose `TeslaCareUITests` scheme
3. **Run all tests**: Press `⌘U` or Product → Test
4. **Run specific test**: Click the diamond next to the test name

### Using Command Line

```bash
# Run all UI tests
xcodebuild test -scheme TeslaCare -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

# Run specific test class
xcodebuild test -scheme TeslaCare -destination 'platform=iOS Simulator,name=iPhone 15 Pro' -only-testing:TeslaCareUITests/TeslaCareUITests

# Run Swift Testing tests
xcodebuild test -scheme TeslaCare -destination 'platform=iOS Simulator,name=iPhone 15 Pro' -only-testing:TeslaCareUITests/CarDetailViewComponentTests
```

## Viewing Screenshots

### In Xcode

1. **Run the tests** (⌘U)
2. **Open the Test Navigator** (⌘6)
3. **Click on a test** to see its results
4. **Expand the test** to see activities and attachments
5. **Click on screenshot attachments** to view them

Screenshots are saved with `lifetime = .keepAlways` so they persist between test runs.

### Screenshot Location

Screenshots are stored in:
```
~/Library/Developer/Xcode/DerivedData/TeslaCare-*/Logs/Test/Attachments/
```

### Export Screenshots

1. **Right-click** on a screenshot attachment in Xcode
2. Select **"Show in Finder"**
3. **Copy** screenshots to your desired location

## Test Coverage

### Components Tested

✅ **Car Info Header**
- Display name
- Year/make/model
- Tire health percentage
- Average tread depth
- Progress indicator

✅ **Tire Grid**
- Visual display of all 4 tires
- Position indicators
- Selection interaction

✅ **Health Indicators**
- Green (healthy): 50-100%
- Orange (warning): 25-50%
- Red (danger): <25%

✅ **Action Buttons**
- Rotate button
- Replace button
- Add Measurement button
- Log Air Filter button

✅ **Measurement Rows**
- Position icon and label
- Tread depth value
- Date
- Mileage
- Notes
- Warning/danger icons

✅ **Event Rows**
- Rotation events with pattern
- Replacement events with tire count
- Air filter changes with filter type
- Cost and mileage display

✅ **Empty States**
- No measurements message
- ContentUnavailableView

## Integration with App

### Adding Test Data Setup

In your app's initialization (e.g., `TeslaCareApp.swift` or main view), add:

```swift
import SwiftUI
import SwiftData

@main
struct TeslaCareApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(sharedModelContainer)
                .onAppear {
                    setupUITestData()
                }
        }
    }
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Car.self,
            TireMeasurement.self,
            TireRotationEvent.self,
            TireReplacementEvent.self,
            AirFilterChangeEvent.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    @MainActor
    private func setupUITestData() {
        let launchArgs = ProcessInfo.processInfo.arguments
        if launchArgs.contains("UI-Testing") {
            UITestDataHelper.setupTestData(
                modelContext: sharedModelContainer.mainContext,
                launchArguments: launchArgs
            )
        }
    }
}
```

## Best Practices

### When Writing New Tests

1. **Use descriptive names**: Test names should clearly indicate what they test
2. **Take screenshots at key moments**: After view appears, after interactions, before assertions
3. **Use launch arguments**: Set up test data without hardcoding
4. **Wait for elements**: Use `waitForExistence(timeout:)` for async UI
5. **Test both success and failure cases**

### Screenshot Guidelines

1. **Name clearly**: Use format `ComponentName_State`
2. **Keep consistent**: Same device, orientation, text size
3. **Set lifetime**: Use `.keepAlways` for important screenshots
4. **Document purpose**: Add comments explaining what the screenshot shows

### Performance Testing

The `testLaunchPerformance()` test measures app launch time. Run it regularly to catch performance regressions.

## Troubleshooting

### Tests Timing Out
- Increase timeout values if running on slow simulators
- Ensure the app is properly launching
- Check that UI elements are actually visible

### Screenshots Not Appearing
- Verify `attachment.lifetime = .keepAlways`
- Check that tests are actually running
- Look in Test Navigator (⌘6) → expand test → view attachments

### Launch Arguments Not Working
- Ensure `UITestDataHelper.setupTestData()` is called on app launch
- Verify launch argument names match exactly
- Check that test data is being inserted into the model context

### Elements Not Found
- Use Xcode's Accessibility Inspector to verify element identifiers
- Check that elements are visible and not obscured
- Wait for animations to complete before searching

## Maintenance

### Adding New Test Scenarios

1. **Add launch argument** to test setup
2. **Create data setup method** in `UITestDataHelper`
3. **Write test method** with appropriate assertions
4. **Capture screenshot** at key view states
5. **Update this README** with new scenario details

### Updating for UI Changes

When the UI changes:
1. Update element queries in tests
2. Re-capture screenshots
3. Update assertions to match new behavior
4. Document breaking changes

## CI/CD Integration

### GitHub Actions Example

```yaml
name: UI Tests

on: [push, pull_request]

jobs:
  ui-tests:
    runs-on: macos-latest
    
    steps:
    - uses: actions/checkout@v2
    
    - name: Run UI Tests
      run: |
        xcodebuild test \
          -scheme TeslaCare \
          -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
          -resultBundlePath TestResults.xcresult
    
    - name: Upload Screenshots
      uses: actions/upload-artifact@v2
      with:
        name: ui-test-screenshots
        path: ~/Library/Developer/Xcode/DerivedData/**/Attachments/
```

## Resources

- [XCTest Framework Documentation](https://developer.apple.com/documentation/xctest)
- [Swift Testing Documentation](https://developer.apple.com/documentation/testing)
- [UI Testing in Xcode](https://developer.apple.com/library/archive/documentation/DeveloperTools/Conceptual/testing_with_xcode/chapters/09-ui_testing.html)

## Summary

This comprehensive test suite provides:
- ✅ **20+ UI tests** covering all major view states
- ✅ **Screenshot capture** for visual regression testing
- ✅ **Component-level testing** with Swift Testing
- ✅ **Flexible test data** using launch arguments
- ✅ **Complete documentation** for maintenance and extension

Run the tests regularly to ensure UI consistency and catch regressions early!
