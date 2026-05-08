//
//  AppDelegate+UITesting.swift
//  TeslaCare
//
//  Created by Jin on 5/7/26.
//
//  Extension to support UI testing setup
//

import SwiftUI
import SwiftData

// MARK: - App Integration for UI Testing

/*
 INTEGRATION INSTRUCTIONS
 ========================
 
 To enable UI testing with automatic test data setup, add this code to your main app file.
 
 OPTION 1: SwiftUI App with WindowGroup
 ----------------------------------------
 
 @main
 struct TeslaCareApp: App {
     var sharedModelContainer: ModelContainer = {
         let schema = Schema([
             Car.self,
             TireMeasurement.self,
             TireRotationEvent.self,
             TireReplacementEvent.self,
             AirFilterChangeEvent.self
         ])
         
         let modelConfiguration = ModelConfiguration(
             schema: schema,
             isStoredInMemoryOnly: false
         )
         
         do {
             return try ModelContainer(
                 for: schema,
                 configurations: [modelConfiguration]
             )
         } catch {
             fatalError("Could not create ModelContainer: \(error)")
         }
     }()
     
     var body: some Scene {
         WindowGroup {
             ContentView()
                 .modelContainer(sharedModelContainer)
                 .onAppear {
                     setupUITestDataIfNeeded()
                 }
         }
     }
     
     @MainActor
     private func setupUITestDataIfNeeded() {
         let launchArgs = ProcessInfo.processInfo.arguments
         
         if launchArgs.contains("UI-Testing") {
             UITestDataHelper.setupTestData(
                 modelContext: sharedModelContainer.mainContext,
                 launchArguments: launchArgs
             )
         }
     }
 }
 
 
 OPTION 2: Using Environment Setup
 -----------------------------------
 
 If you prefer a more modular approach, create a view modifier:
 
 struct UITestingModifier: ViewModifier {
     @Environment(\.modelContext) private var modelContext
     
     func body(content: Content) -> some View {
         content.onAppear {
             setupTestDataIfNeeded()
         }
     }
     
     @MainActor
     private func setupTestDataIfNeeded() {
         let launchArgs = ProcessInfo.processInfo.arguments
         
         if launchArgs.contains("UI-Testing") {
             UITestDataHelper.setupTestData(
                 modelContext: modelContext,
                 launchArguments: launchArgs
             )
         }
     }
 }
 
 extension View {
     func setupUITestingIfNeeded() -> some View {
         modifier(UITestingModifier())
     }
 }
 
 // Then in your ContentView or root view:
 struct ContentView: View {
     var body: some View {
         NavigationStack {
             // Your content
         }
         .setupUITestingIfNeeded()
     }
 }
 
 
 OPTION 3: Conditional Compilation
 -----------------------------------
 
 For production builds, you can exclude test setup code:
 
 #if DEBUG
 @MainActor
 private func setupUITestDataIfNeeded(modelContext: ModelContext) {
     let launchArgs = ProcessInfo.processInfo.arguments
     
     if launchArgs.contains("UI-Testing") {
         UITestDataHelper.setupTestData(
             modelContext: modelContext,
             launchArguments: launchArgs
         )
     }
 }
 #endif
 
 
 LAUNCH ARGUMENTS REFERENCE
 ==========================
 
 The following launch arguments are supported:
 
 UI-Testing              - Required base argument to enable test mode
 EmptyCarState          - Car with no measurements
 CarWithMeasurements    - Car with 4 tire measurements
 HealthyTires           - All tires 8-9/32" (green)
 WarningTires           - Some tires 2-4/32" (orange)
 DangerousTires         - Some tires ≤2/32" (red)
 WithRotationHistory    - Car + measurements + rotation events
 WithReplacementHistory - Car + measurements + replacement events
 WithAirFilterHistory   - Car + measurements + air filter events
 CompleteHistory        - Car with all types of events
 Car2020                - Different year for format testing
 
 
 DEBUGGING UI TESTS
 ==================
 
 To debug test data setup:
 
 1. Add breakpoints in UITestDataHelper methods
 2. Run UI test in debug mode
 3. Check that launch arguments are being passed
 4. Verify data is being inserted into model context
 5. Ensure context.save() is being called
 
 Print statements:
 
 @MainActor
 func setupTestData(modelContext: ModelContext, launchArguments: [String]) {
     print("🧪 UI Testing: Launch arguments = \(launchArguments)")
     
     guard launchArguments.contains("UI-Testing") else {
         print("🧪 UI Testing: Not in test mode")
         return
     }
     
     print("🧪 UI Testing: Setting up test data...")
     // ... setup code
     
     print("🧪 UI Testing: Test data setup complete")
 }
 
 
 VERIFYING SETUP
 ===============
 
 1. Set a launch argument in your test scheme
 2. Run the app (not the test)
 3. Check console for setup messages
 4. Verify data appears in the UI
 
 If data doesn't appear:
 - Check that onAppear is being called
 - Verify model container is shared
 - Ensure view is observing data changes
 - Try adding .task instead of .onAppear
 
 
 CUSTOM TEST SCENARIOS
 =====================
 
 To add a new test scenario:
 
 1. Add a new launch argument name
 2. Create a setup function in UITestDataHelper
 3. Add condition in setupTestData()
 4. Create corresponding test in test file
 
 Example:
 
 // In UITestDataHelper:
 private static func setupCustomScenario(modelContext: ModelContext) {
     let car = Car(name: "Test Car", make: "Tesla", model: "Model S", year: 2024)
     modelContext.insert(car)
     
     // Add custom test data
 }
 
 // In setupTestData():
 else if launchArguments.contains("CustomScenario") {
     setupCustomScenario(modelContext: modelContext)
 }
 
 // In test file:
 @MainActor
 func testCustomScenario() throws {
     app.launchArguments.append("CustomScenario")
     app.launch()
     // Test assertions
 }
 
 
 PERFORMANCE CONSIDERATIONS
 ==========================
 
 - Test data setup should be fast (< 1 second)
 - Clear old data before creating new data
 - Use in-memory storage for faster tests (optional)
 - Batch insert operations when possible
 
 For in-memory testing:
 
 let modelConfiguration = ModelConfiguration(
     schema: schema,
     isStoredInMemoryOnly: true  // Fast, but data not persisted
 )
 
 
 PRODUCTION SAFETY
 =================
 
 Test setup only runs when:
 1. "UI-Testing" launch argument is present
 2. App is launched by test runner
 
 Never runs in:
 - Normal app launches
 - Production builds (if using #if DEBUG)
 - TestFlight or App Store builds
 
 
 TROUBLESHOOTING
 ===============
 
 Issue: Test data not appearing
 Solution: Verify .modelContainer() is applied before .onAppear()
 
 Issue: Data from previous test still visible
 Solution: clearAllData() is called before each scenario
 
 Issue: Crashes on launch with test arguments
 Solution: Check model relationships and required fields
 
 Issue: Screenshots show wrong data
 Solution: Verify launch argument matches test scenario
 
 Issue: Animations interfere with screenshots
 Solution: Add sleep delays or disable animations:
          app.launchEnvironment["DISABLE_ANIMATIONS"] = "1"
 
 */

// MARK: - Example Implementation

/// Example of how to integrate this into your TeslaCareApp
///
/// ```swift
/// @main
/// struct TeslaCareApp: App {
///     var sharedModelContainer: ModelContainer = {
///         let schema = Schema([
///             Car.self,
///             TireMeasurement.self,
///             TireRotationEvent.self,
///             TireReplacementEvent.self,
///             AirFilterChangeEvent.self
///         ])
///         
///         let modelConfiguration = ModelConfiguration(schema: schema)
///         
///         do {
///             return try ModelContainer(for: schema, configurations: [modelConfiguration])
///         } catch {
///             fatalError("Could not create ModelContainer: \(error)")
///         }
///     }()
///     
///     var body: some Scene {
///         WindowGroup {
///             ContentView()
///                 .modelContainer(sharedModelContainer)
///                 .onAppear {
///                     Task { @MainActor in
///                         let launchArgs = ProcessInfo.processInfo.arguments
///                         if launchArgs.contains("UI-Testing") {
///                             UITestDataHelper.setupTestData(
///                                 modelContext: sharedModelContainer.mainContext,
///                                 launchArguments: launchArgs
///                             )
///                         }
///                     }
///                 }
///         }
///     }
/// }
/// ```
